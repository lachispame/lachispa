import 'package:dio/dio.dart';

class YadioService {
  final Dio _dio = Dio();
  static const String baseUrl = 'https://api.yadio.io';

  YadioService() {
    _configureDio();
  }

  void _configureDio() {
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    // Logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: true,
      requestHeader: false,
      responseHeader: false,
      error: true,
      logPrint: (obj) => print('[YADIO_SERVICE] $obj'),
    ));
  }

  /// Converts a fiat currency amount to satoshis
  /// 
  /// [amount] - Amount in fiat currency
  /// [currency] - Source currency ('CUP', 'USD')
  /// 
  /// Returns the equivalent amount in satoshis
  Future<int> convertToSats({
    required double amount,
    required String currency,
  }) async {
    print('[YADIO_SERVICE] Converting $amount $currency to sats');

    try {
      // Use only the convert endpoint
      final response = await _dio.get('$baseUrl/convert/$amount/${currency.toUpperCase()}/BTC');
      
      if (response.statusCode == 200) {
        final data = response.data;
        print('[YADIO_SERVICE] Yadio response: ${data.toString()}');
        
        // Check if there's an error
        if (data.containsKey('error')) {
          print('[YADIO_SERVICE] ERROR de Yadio: ${data['error']}');
          throw Exception('Yadio error: ${data['error']}');
        }
        
        // Get result as double and convert directly
        final btcAmount = data['result'] as double;
        final rate = data['rate'] as double;
        
        print('[YADIO_SERVICE] BTC amount: $btcAmount');
        
        // Convert directly from double to sats with maximum precision
        final satsAmount = (btcAmount * 100000000).round();
        
        print('[YADIO_SERVICE] $amount $currency = $satsAmount sats (API Yadio)');
        print('[YADIO_SERVICE] Conversion: $amount $currency -> $btcAmount BTC -> $satsAmount sats');
        print('[YADIO_SERVICE] Rate used: 1 $currency = $rate BTC');
        
        return satsAmount;
      } else {
        throw Exception('Yadio server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('[YADIO_SERVICE] Connection error with Yadio: ${e.message}');
      print('[YADIO_SERVICE] Using fallback conversion');
      return _getFallbackConversion(amount, currency);
    } catch (e) {
      print('[YADIO_SERVICE] Error processing Yadio response: $e');
      print('[YADIO_SERVICE] Using fallback conversion');
      return _getFallbackConversion(amount, currency);
    }
  }

  /// Fallback conversion with approximate rates
  /// Only for testing when Yadio is not available
  int _getFallbackConversion(double amount, String currency) {
    print('[YADIO_SERVICE] Using fallback conversion for $currency');
    
    switch (currency.toUpperCase()) {
      case 'CUP':
        // Based on: 87 CUP = 203 sats → 1 CUP ≈ 2.33 sats
        return (amount * 2.33).round();
      
      case 'USD':
        // Based on real Yadio: 500 USD = 450,148 sats → 1 USD ≈ 900.3 sats
        return (amount * 900.3).round();
      
      default:
        throw Exception('Unsupported currency: $currency');
    }
  }

  /// Gets current exchange rates using the convert endpoint (more reliable than /rates)
  /// [currencies] - set of currency codes to fetch (e.g. {'CUP', 'USD'})
  Future<Map<String, double>> getExchangeRates({Set<String>? currencies}) async {
    try {
      // Get BTC/USD rate first
      final btcUsdResponse = await _dio.get('$baseUrl/convert/1/BTC/USD');
      if (btcUsdResponse.statusCode != 200) throw Exception('BTC/USD failed');
      final btcUsd = btcUsdResponse.data['result'] as double;

      final rates = <String, double>{
        'BTC': btcUsd,
        'USD': 1.0,
      };

      // Fetch each needed currency via /convert/1/BTC/XXX
      if (currencies != null) {
        for (final currency in currencies) {
          if (currency == 'USD') continue;
          try {
            final response = await _dio.get('$baseUrl/convert/1/BTC/$currency');
            if (response.statusCode == 200) {
              final btcToCurrency = response.data['result'] as double;
              rates[currency] = btcToCurrency / btcUsd;
            }
          } catch (e) {
            print('[YADIO_SERVICE] Failed to get rate for $currency: $e');
          }
        }
      }

      print('[YADIO_SERVICE] Rates obtained: $rates');
      return rates;
    } catch (e) {
      print('[YADIO_SERVICE] Error getting rates via convert: $e');

      return {
        'CUP': 120.0,
        'USD': 1.0,
        'BTC': 45000.0,
      };
    }
  }

  /// Converts a BTC string to satoshis using integer arithmetic
  /// to avoid precision loss with doubles
  int _convertBtcStringToSats(String btcString) {
    try {
      // Handle scientific notation if present
      if (btcString.toLowerCase().contains('e')) {
        final double btcDouble = double.parse(btcString);
        final String normalString = btcDouble.toStringAsFixed(8);
        return _convertNormalBtcStringToSats(normalString);
      } else {
        return _convertNormalBtcStringToSats(btcString);
      }
    } catch (e) {
      print('[YADIO_SERVICE] Error converting BTC string: $e');
      // Fallback to conversion with double
      final double btcDouble = double.parse(btcString);
      return (btcDouble * 100000000).round();
    }
  }
  
  /// Converts BTC in normal format (e.g., "0.00188374") to satoshis
  int _convertNormalBtcStringToSats(String btcString) {
    // Remove spaces
    btcString = btcString.trim();
    
    // If it doesn't have decimal point, add .0
    if (!btcString.contains('.')) {
      btcString = '$btcString.0';
    }
    
    // Separate integer and decimal parts
    final parts = btcString.split('.');
    final integerPart = int.parse(parts[0]);
    final decimalPart = parts[1];
    
    // Ensure decimal part has exactly 8 digits (satoshi precision)
    String normalizedDecimal = decimalPart.padRight(8, '0');
    if (normalizedDecimal.length > 8) {
      normalizedDecimal = normalizedDecimal.substring(0, 8);
    }
    
    // Convert to satoshis using integer arithmetic
    final integerSats = integerPart * 100000000;
    final decimalSats = int.parse(normalizedDecimal);
    
    print('[YADIO_SERVICE] Precise conversion: $btcString BTC -> ${integerSats + decimalSats} sats');
    print('[YADIO_SERVICE] Integer part: $integerPart BTC = $integerSats sats');
    print('[YADIO_SERVICE] Decimal part: 0.$normalizedDecimal BTC = $decimalSats sats');
    
    return integerSats + decimalSats;
  }

  /// Converts satoshis to fiat currency using Yadio
  /// 
  /// [sats] - Amount in satoshis
  /// [currency] - Target currency ('CUP', 'USD')
  /// 
  /// Returns the equivalent amount in the requested currency as string to maintain precision
  Future<String> convertSatsToFiat({
    required int sats,
    required String currency,
  }) async {
    print('[YADIO_SERVICE] Converting $sats sats to $currency');

    try {
      // Convert sats to BTC maintaining precision
      final btcAmount = sats / 100000000.0;
      final btcString = btcAmount.toStringAsFixed(8);

      // Use convert endpoint from BTC to desired currency
      final response = await _dio.get('$baseUrl/convert/$btcString/BTC/${currency.toUpperCase()}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        print('[YADIO_SERVICE] Yadio response: ${data.toString()}');
        
        // Check if there's an error
        if (data.containsKey('error')) {
          print('[YADIO_SERVICE] ERROR de Yadio: ${data['error']}');
          throw Exception('Yadio error: ${data['error']}');
        }
        
        // Get result as string to maintain precision
        final fiatAmountStr = data['result'].toString();
        final rate = data['rate'] as double;
        
        print('[YADIO_SERVICE] $sats sats = $fiatAmountStr $currency (Yadio API)');
        print('[YADIO_SERVICE] Conversion: $sats sats -> $btcString BTC -> $fiatAmountStr $currency');
        print('[YADIO_SERVICE] Rate used: 1 BTC = $rate $currency');
        
        return fiatAmountStr;
      } else {
        throw Exception('Yadio server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('[YADIO_SERVICE] Connection error with Yadio: ${e.message}');
      print('[YADIO_SERVICE] Using fallback conversion');
      return _getFallbackSatsToFiatConversion(sats, currency);
    } catch (e) {
      print('[YADIO_SERVICE] Error processing Yadio response: $e');
      print('[YADIO_SERVICE] Using fallback conversion');
      return _getFallbackSatsToFiatConversion(sats, currency);
    }
  }

  /// Fallback conversion from sats to fiat
  String _getFallbackSatsToFiatConversion(int sats, String currency) {
    print('[YADIO_SERVICE] Using fallback conversion from sats to $currency');
    
    switch (currency.toUpperCase()) {
      case 'CUP':
        // Based on: 87 CUP = 203 sats → 1 sat ≈ 0.429 CUP
        final cupValue = sats * 0.429;
        return cupValue.toStringAsFixed(2);
      
      case 'USD':
        // Based on real Yadio: 500 USD = 450,148 sats → 1 sat ≈ 0.00111 USD
        final usdValue = sats * 0.00111;
        return usdValue.toStringAsFixed(2);
      
      default:
        throw Exception('Unsupported currency: $currency');
    }
  }

  void dispose() {
    _dio.close();
  }
}