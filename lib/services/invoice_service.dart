import 'package:dio/dio.dart';
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import '../models/lightning_invoice.dart';
import '../models/decoded_invoice.dart';
import '../core/utils/proxy_config.dart';
import 'app_info_service.dart';

void _debugLog(String message) {
  if (kDebugMode) {
    print(message);
  }
}

class InvoiceService {
  final Dio _dio = Dio();

  InvoiceService() {
    _configureDio();
  }

  void _configureDio() {
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final isWeb = kIsWeb;
    
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['User-Agent'] = isAndroid 
        ? AppInfoService.getUserAgent('Android') 
        : isWeb 
          ? AppInfoService.getUserAgent('Web')
          : AppInfoService.getUserAgent();
    
    // Longer timeouts for proxy and Android devices
    _dio.options.connectTimeout = isAndroid 
        ? const Duration(seconds: 30) 
        : const Duration(seconds: 20);
    _dio.options.receiveTimeout = isAndroid 
        ? const Duration(seconds: 30) 
        : const Duration(seconds: 20);
    _dio.options.sendTimeout = isAndroid 
        ? const Duration(seconds: 30) 
        : const Duration(seconds: 20);
    
    ProxyConfig.configureProxy(_dio, enableLogging: false);
    
    if (ProxyConfig.hasSystemProxy()) {
      _debugLog('[INVOICE_SERVICE] Using system proxy configuration');
    }
    
    // Android WebView requires specific headers to avoid request blocking
    if (isAndroid) {
      _dio.options.headers['Accept'] = 'application/json';
      _dio.options.headers['Cache-Control'] = 'no-cache';
      _dio.options.headers.remove('Accept-Encoding');
      _dio.options.headers.remove('Connection');
      _dio.options.headers.remove('DNT');
      _dio.options.headers.remove('Upgrade-Insecure-Requests');
    }
    
    _dio.options.followRedirects = true;
    _dio.options.maxRedirects = isAndroid ? 3 : 5;
    _dio.options.validateStatus = (status) {
      return status != null && status >= 200 && status < 400;
    };
    
    _dio.interceptors.add(LogInterceptor(
      requestBody: isAndroid,
      responseBody: true,
      requestHeader: isAndroid,
      responseHeader: isAndroid,
      error: true,
      logPrint: (obj) => _debugLog('[INVOICE_SERVICE] $obj'),
    ));
    
    _debugLog('[INVOICE_SERVICE] Configured for ${isAndroid ? "Android" : isWeb ? "Web" : "Desktop"}');
  }

  void _configureProxyForDio(Dio dio, {bool enableLogging = false}) {
    ProxyConfig.configureProxy(dio, enableLogging: enableLogging);
  }

  /// Creates a new Lightning invoice
  /// 
  /// [serverUrl] - LNBits server URL
  /// [adminKey] - Wallet admin key
  /// [amount] - Amount in satoshis
  /// [memo] - Optional invoice description
  /// [originalFiatCurrency] - Original fiat currency (ZAR, USD, etc.)
  /// [originalFiatAmount] - Original fiat amount
  /// [originalFiatRate] - Original fiat rate (sats per unit)
  /// 
  /// Returns a [LightningInvoice] with the created invoice data
  Future<LightningInvoice> createInvoice({
    required String serverUrl,
    required String adminKey,
    required int amount,
    String? memo,
    String? comment,
    String? originalFiatCurrency,
    double? originalFiatAmount,
    double? originalFiatRate,
  }) async {
    try {
      String baseUrl = serverUrl;
      if (!baseUrl.startsWith('http')) {
        baseUrl = 'https://$baseUrl';
      }

      _debugLog('[INVOICE_SERVICE] Creating invoice: $amount sats, memo: "$memo"');
      if (originalFiatCurrency != null && originalFiatAmount != null) {
        _debugLog('[INVOICE_SERVICE] Original fiat: $originalFiatAmount $originalFiatCurrency (rate: $originalFiatRate)');
      }

      final headers = {
        'X-API-KEY': adminKey,
        'Content-Type': 'application/json',
      };

      final isAndroid = !kIsWeb && Platform.isAndroid;
      
      // Build extras with fiat information if provided
      // Try multiple approaches to ensure LNBits accepts the fiat data
      Map<String, dynamic>? extras;
      if (originalFiatCurrency != null && originalFiatAmount != null && originalFiatRate != null) {
        extras = {
          // Original approach - put fiat info in extras
          'fiat_currency': originalFiatCurrency,
          'fiat_amount': originalFiatAmount,
          'fiat_rate': originalFiatRate,
          'btc_rate': (originalFiatAmount / amount) * 100000000,
        };
        if (comment != null && comment.isNotEmpty) {
          extras['comment'] = comment;
        }
        _debugLog('[INVOICE_SERVICE] Extras object: $extras');
      } else if (comment != null && comment.isNotEmpty) {
        extras = {'comment': comment};
      }
      
      // Platform-optimized endpoint ordering for different LNBits API variants
      List<Map<String, dynamic>> endpoints;
      
      if (isAndroid) {
        // Android-optimized endpoints tested manually
        endpoints = [
          // Try LNBits LNURLP endpoint with fiat info (common pattern)
          if (originalFiatCurrency != null && originalFiatAmount != null) {
            'url': '$baseUrl/lnurlp/api/v1/invoice',
            'data': {
              'amount': (amount * 1000).toString(), // LNURLP expects msat as string
              'description': memo ?? '',
              'currency': originalFiatCurrency.toUpperCase(),
              'fiat_amount': originalFiatAmount.toString(),
              'comment': comment ?? '',
            }
          },
          // Try direct fiat fields in main payments endpoint
          if (originalFiatCurrency != null && originalFiatAmount != null) {
            'url': '$baseUrl/api/v1/payments',
            'data': {
              'out': false,
              'amount': amount,
              'memo': memo ?? '',
              'fiat_currency': originalFiatCurrency.toUpperCase(),
              'fiat_amount': originalFiatAmount,
              'extras': comment != null && comment.isNotEmpty ? {'comment': comment} : null,
            }
          },
          {
            'url': '$baseUrl/api/v1/payments',
            'data': {
              'out': false,
              'amount': amount,
              'memo': memo ?? '',
              'extras': extras,
            }
          },
          // Try approach 2: fiat fields at root level
          if (originalFiatCurrency != null && originalFiatAmount != null) {
            'url': '$baseUrl/api/v1/payments',
            'data': {
              'out': false,
              'amount': amount,
              'memo': memo ?? '',
              'fiat_currency': originalFiatCurrency,
              'fiat_amount': originalFiatAmount,
              'fiat_rate': originalFiatRate,
              'extras': comment != null && comment.isNotEmpty ? {'comment': comment} : null,
            }
          },
          // Try approach 3: using 'currency' parameter (common in some LNBits extensions)
          if (originalFiatCurrency != null && originalFiatAmount != null) {
            'url': '$baseUrl/api/v1/payments',
            'data': {
              'out': false,
              'amount': amount,
              'memo': memo ?? '',
              'currency': originalFiatCurrency,
              'currency_amount': originalFiatAmount,
              'extras': extras,
            }
          },
          {
            'url': '$baseUrl/api/v1/payments',
            'data': {
              'amount': amount,
              'memo': memo ?? '',
              'extras': extras,
            }
          },
          {
            'url': '$baseUrl/api/v1/payments',
            'data': {
              'out': false,
              'amount': amount,
              'description': memo ?? '',
              'extras': extras,
            }
          },
          {
            'url': '$baseUrl/payments',
            'data': {
              'out': false,
              'amount': amount,
              'memo': memo ?? '',
              'extras': extras,
            }
          },
          {
            'url': '$baseUrl/api/v1/payments',
            'data': {
              'amount': amount,
              'description': memo ?? '',
              'unit': 'sat',
              'extras': extras,
            }
          },
          {
            'url': '$baseUrl/api/v1/wallet/payments',
            'data': {
              'out': false,
              'amount': amount,
              'memo': memo ?? '',
              'extras': extras,
            }
          },
          {
            'url': '$baseUrl/api/v1/invoices',
            'data': {
              'amount': amount,
              'memo': memo ?? '',
              'extras': extras,
            }
          },
          {
            'url': '$baseUrl/invoice',
            'data': {
              'amount': amount,
              'memo': memo ?? '',
              'extras': extras,
            }
          },
        ];
      } else {
        // Web/Desktop-optimized endpoints
        endpoints = [
          // Try LNURLP endpoint for web with fiat info
          if (originalFiatCurrency != null && originalFiatAmount != null) {
            'url': '$baseUrl/lnurlp/api/v1/invoice',
            'data': {
              'amount': (amount * 1000).toString(), // LNURLP expects msat as string
              'description': memo ?? '',
              'currency': originalFiatCurrency.toUpperCase(),
              'fiat_amount': originalFiatAmount.toString(),
              'comment': comment ?? '',
            }
          },
          // Try direct fiat fields for web
          if (originalFiatCurrency != null && originalFiatAmount != null) {
            'url': '$baseUrl/api/v1/payments',
            'data': {
              'out': false,
              'amount': amount,
              'memo': memo ?? '',
              'unit': 'sat',
              'fiat_currency': originalFiatCurrency.toUpperCase(),
              'fiat_amount': originalFiatAmount,
              'extras': comment != null && comment.isNotEmpty ? {'comment': comment} : null,
            }
          },
          {
            'url': '$baseUrl/api/v1/payments',
            'data': {
              'out': false,
              'amount': amount,
              'memo': memo ?? '',
              'unit': 'sat',
              'extras': extras,
            }
          },
          {
            'url': '$baseUrl/node/api/v1/payments',
            'data': {
              'out': false,
              'amount': amount,
              'memo': memo ?? '',
              'unit': 'sat',
              'extras': extras,
            }
          },
          {
            'url': '$baseUrl/api/v1/invoice',
            'data': {
              'amount': amount,
              'memo': memo ?? '',
              'unit': 'sat',
              'extras': extras,
            }
          },
          {
            'url': '$baseUrl/api/v1/payments',
            'data': {
              'amount': amount,
              'memo': memo ?? '',
              'description': memo ?? '',
              'extras': extras,
            }
          },
        ];
      }

      Exception? lastException;

      // Try each endpoint until one works
      for (int i = 0; i < endpoints.length; i++) {
        final endpoint = endpoints[i];
        final url = endpoint['url'] as String;
        final data = endpoint['data'] as Map<String, dynamic>;
        
        try {
          _debugLog('[INVOICE_SERVICE] Trying endpoint: $url (${i + 1}/${endpoints.length})');
          _debugLog('[INVOICE_SERVICE] Data: $data');
          _debugLog('[INVOICE_SERVICE] Platform: ${isAndroid ? "Android" : "Web/Desktop"}');
          _debugLog('[INVOICE_SERVICE] Headers: $headers');
          
          // Special logging for fiat endpoints
          if (data.containsKey('fiat_currency') || data.containsKey('currency') || (data.containsKey('extras') && data['extras'] != null)) {
            _debugLog('[INVOICE_SERVICE] 💰 FIAT ENDPOINT ATTEMPT: Contains fiat data');
            _debugLog('[INVOICE_SERVICE] 💰 Fiat currency: ${data['fiat_currency'] ?? data['currency']}');
            _debugLog('[INVOICE_SERVICE] 💰 Fiat amount: ${data['fiat_amount'] ?? data['currency_amount']}');
            _debugLog('[INVOICE_SERVICE] 💰 Extras: ${data['extras']}');
          }

          final response = await _dio.post(
            url,
            data: data,
            options: Options(
              headers: headers,
              method: 'POST',
              responseType: ResponseType.json,
              contentType: 'application/json',
            ),
          );

          if (response.statusCode == 201 || response.statusCode == 200) {
            _debugLog('[INVOICE_SERVICE] ✅ Invoice created successfully with: $url');
            _debugLog('[INVOICE_SERVICE] Response: ${response.data}');
            
            // Check if the created invoice contains our fiat information
            if (response.data is Map && response.data.containsKey('extra')) {
              _debugLog('[INVOICE_SERVICE] 💰 CREATED INVOICE EXTRA FIELD: ${response.data['extra']}');
            } else if (response.data is Map) {
              _debugLog('[INVOICE_SERVICE] ⚠️ No extra field found in created invoice response');
              _debugLog('[INVOICE_SERVICE] Available fields: ${(response.data as Map).keys.toList()}');
            }
            
            return LightningInvoice.fromJson(response.data);
          }
        } catch (e) {
          _debugLog('[INVOICE_SERVICE] ❌ Failed $url: $e');
          lastException = e is Exception ? e : Exception(e.toString());
          
          if (e.toString().contains('405')) {
            _debugLog('[INVOICE_SERVICE] 405 - Method not allowed: $url');
            continue;
          }
          
          if (e.toString().contains('401')) {
            _debugLog('[INVOICE_SERVICE] 401 - Authentication error');
            throw Exception('Authentication error. Verify credentials.');
          }
          
          continue;
        }
      }
      
      // All endpoints failed
      _debugLog('[INVOICE_SERVICE] ❌ All creation endpoints failed');
      if (lastException != null) {
        throw lastException;
      } else {
        throw Exception('Could not create invoice. Server does not support invoice creation.');
      }
    } on DioException catch (e) {
      _debugLog('[INVOICE_SERVICE] DioException: ${e.type}');
      _debugLog('[INVOICE_SERVICE] Error: ${e.message}');
      _debugLog('[INVOICE_SERVICE] Response: ${e.response?.data}');
      
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication error. Verify credentials.');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid invoice data: ${e.response?.data}');
      } else if (e.response?.statusCode == 405) {
        throw Exception('Method not allowed. Server does not support invoice creation on this endpoint.');
      } else if (e.response?.statusCode == 520) {
        throw Exception('Server error (520). Amount may be too large or server is overloaded.');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Invalid amount. May exceed server limits.');
      } else {
        throw Exception('Server error (${e.response?.statusCode ?? 'unknown'}): ${e.message}');
      }
    } catch (e) {
      _debugLog('[INVOICE_SERVICE] General error: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Checks invoice status
  /// 
  /// [serverUrl] - LNBits server URL
  /// [adminKey] - Wallet admin key
  /// [paymentHash] - Invoice payment hash
  /// 
  /// Returns true if invoice has been paid
  Future<bool> checkInvoiceStatus({
    required String serverUrl,
    required String adminKey,
    required String paymentHash,
  }) async {
    try {
      String baseUrl = serverUrl;
      if (!baseUrl.startsWith('http')) {
        baseUrl = 'https://$baseUrl';
      }

      final headers = {
        'X-API-KEY': adminKey,
      };

      // Try multiple endpoints to check status
      final endpoints = [
        '$baseUrl/api/v1/payments/$paymentHash',
        '$baseUrl/api/v1/wallet/payment/$paymentHash',
        '$baseUrl/node/api/v1/payments/$paymentHash',
      ];
      
      Response? response;
      for (final endpoint in endpoints) {
        try {
          _debugLog('[INVOICE_SERVICE] Trying endpoint: $endpoint');
          response = await _dio.get(endpoint, options: Options(headers: headers));
          _debugLog('[INVOICE_SERVICE] ✅ Endpoint successful: $endpoint');
          break;
        } catch (e) {
          _debugLog('[INVOICE_SERVICE] ❌ Endpoint failed: $endpoint - $e');
          continue;
        }
      }
      
      if (response == null) {
        throw Exception('Could not verify invoice status on any endpoint');
      }

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Check different response formats from various LNBits implementations
        bool isPaid = false;
        
        if (data is Map && data.containsKey('paid')) {
          isPaid = data['paid'] == true;
        }
        else if (data is Map && data.containsKey('status')) {
          final status = data['status']?.toString().toLowerCase();
          isPaid = status == 'paid' || status == 'complete' || status == 'settled';
        }
        else if (data is List) {
          for (final payment in data) {
            if (payment is Map && payment['payment_hash'] == paymentHash) {
              final status = payment['status']?.toString().toLowerCase();
              isPaid = status == 'paid' || status == 'complete' || status == 'settled';
              break;
            }
          }
        }
        
        _debugLog('[INVOICE_SERVICE] Invoice status $paymentHash: ${isPaid ? "PAID" : "PENDING"}');
        _debugLog('[INVOICE_SERVICE] Datos de respuesta: $data');
        
        return isPaid;
      } else {
        throw Exception('Error checking status: ${response.statusCode}');
      }
    } catch (e) {
      _debugLog('[INVOICE_SERVICE] Error checking status: $e');
      return false;
    }
  }

  /// Decodes a BOLT11 invoice using LNBits
  /// Automatically tries multiple endpoints
  /// 
  /// [serverUrl] - LNBits server URL
  /// [invoiceKey] - Invoice/Admin key of the wallet
  /// [bolt11] - Lightning invoice to decode
  /// 
  /// Returns a [DecodedInvoice] with decoded data
  Future<DecodedInvoice> decodeBolt11({
    required String serverUrl,
    required String invoiceKey,
    required String bolt11,
  }) async {
    try {
      // Asegurar que la URL tenga HTTPS
      String baseUrl = serverUrl;
      if (!baseUrl.startsWith('http')) {
        baseUrl = 'https://$baseUrl';
      }

      // Clean invoice by removing prefixes if they exist
      String cleanBolt11 = bolt11.trim();
      if (cleanBolt11.toLowerCase().startsWith('lightning:')) {
        cleanBolt11 = cleanBolt11.substring(10);
        _debugLog('[INVOICE_SERVICE] Removed "lightning:" prefix from invoice');
      }

      _debugLog('[INVOICE_SERVICE] Decoding BOLT11 invoice');
      _debugLog('[INVOICE_SERVICE] Invoice: ${cleanBolt11.substring(0, math.min(20, cleanBolt11.length))}...');

      final headers = {
        'X-API-KEY': invoiceKey,
        'Content-Type': 'application/json',
      };

      // Multiple endpoints for different LNBits implementations
      final endpoints = [
        {
          'url': '$baseUrl/api/v1/payments/decode',
          'data': {'data': cleanBolt11}
        },
        {
          'url': '$baseUrl/node/api/v1/payments/decode', 
          'data': {'data': cleanBolt11}
        },
        {
          'url': '$baseUrl/api/v1/payments/decode',
          'data': {'bolt11': cleanBolt11}
        },
        {
          'url': '$baseUrl/lnurlp/api/v1/decode',
          'data': {'payment_request': cleanBolt11}
        },
        {
          'url': '$baseUrl/decode',
          'data': {'bolt11': cleanBolt11}
        },
      ];

      Exception? lastException;

      // Try each endpoint until one works
      for (int i = 0; i < endpoints.length; i++) {
        final endpoint = endpoints[i];
        final url = endpoint['url'] as String;
        final data = endpoint['data'] as Map<String, dynamic>;
        
        try {
          _debugLog('[INVOICE_SERVICE] Trying decode: $url (${i + 1}/${endpoints.length})');
          _debugLog('[INVOICE_SERVICE] Data: $data');

          final response = await _dio.post(
            url,
            data: data,
            options: Options(headers: headers),
          );

          if (response.statusCode == 200) {
            _debugLog('[INVOICE_SERVICE] ✅ Invoice decoded successfully with: $url');
            _debugLog('[INVOICE_SERVICE] Response: ${response.data}');
            return DecodedInvoice.fromJson(response.data, cleanBolt11);
          }
        } catch (e) {
          _debugLog('[INVOICE_SERVICE] ❌ Failed $url: $e');
          lastException = e is Exception ? e : Exception(e.toString());
          
          if (e.toString().contains('404')) {
            _debugLog('[INVOICE_SERVICE] 404 - Endpoint not available: $url');
            continue;
          }
          
          if (e.toString().contains('401')) {
            _debugLog('[INVOICE_SERVICE] 401 - Authentication error');
            throw Exception('Authentication error. Verify credentials.');
          }
          
          continue;
        }
      }
      
      // All endpoints failed
      _debugLog('[INVOICE_SERVICE] ❌ All decode endpoints failed');
      if (lastException != null) {
        throw lastException;
      } else {
        throw Exception('Could not decode invoice. Server does not support decoding.');
      }
    } on DioException catch (e) {
      _debugLog('[INVOICE_SERVICE] DioException decodificando: ${e.type}');
      _debugLog('[INVOICE_SERVICE] Error: ${e.message}');
      _debugLog('[INVOICE_SERVICE] Response: ${e.response?.data}');
      
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication error. Verify credentials.');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid BOLT11 invoice: ${e.response?.data}');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Incorrect invoice format.');
      } else {
        throw Exception('Error decoding invoice (${e.response?.statusCode ?? 'unknown'}): ${e.message}');
      }
    } catch (e) {
      _debugLog('[INVOICE_SERVICE] General decode error: $e');
      throw Exception('Unexpected error decoding invoice: $e');
    }
  }

  /// Sends a Lightning payment using a BOLT11 invoice
  /// Automatically detects if it's a hold invoice and uses appropriate endpoint
  /// 
  /// [serverUrl] - LNBits server URL
  /// [adminKey] - Wallet admin key
  /// [bolt11] - Lightning invoice to pay
  /// 
  /// Returns payment data
  Future<Map<String, dynamic>> sendPayment({
    required String serverUrl,
    required String adminKey,
    required String bolt11,
    int? amount,
  }) async {
    try {
      // Asegurar que la URL tenga HTTPS
      String baseUrl = serverUrl;
      if (!baseUrl.startsWith('http')) {
        baseUrl = 'https://$baseUrl';
      }

      _debugLog('[INVOICE_SERVICE] Sending Lightning payment');
      _debugLog('[INVOICE_SERVICE] Invoice: ${bolt11.substring(0, 20)}...');

      final headers = {
        'X-API-KEY': adminKey,
        'Content-Type': 'application/json',
      };

      final isAndroid = !kIsWeb && Platform.isAndroid;

      // For amountless invoices, convert sats to millisatoshis for LNBits API
      final int? amountMsat = amount != null ? amount * 1000 : null;

      _debugLog('[INVOICE_SERVICE] Payment amount: ${amount != null ? "$amount sats ($amountMsat msat)" : "from invoice"}');

      // Platform-optimized endpoints for payment processing
      List<Map<String, dynamic>> endpoints;

      if (isAndroid) {
        // Android-optimized payment endpoints tested
        endpoints = [
          {
            'url': '$baseUrl/api/v1/payments',
            'data': {
              'out': true,
              'bolt11': bolt11,
              if (amountMsat != null) 'amount': amountMsat,
            }
          },
          {
            'url': '$baseUrl/api/v1/payments',
            'data': {
              'out': true,
              'bolt11': bolt11,
              if (amount != null) 'amount': amount,
            }
          },
          {
            'url': '$baseUrl/api/v1/payments',
            'data': {
              'bolt11': bolt11,
              if (amountMsat != null) 'amount': amountMsat,
            }
          },
          {
            'url': '$baseUrl/api/v1/pay',
            'data': {
              'bolt11': bolt11,
              if (amountMsat != null) 'amount': amountMsat,
            }
          },
          {
            'url': '$baseUrl/payments',
            'data': {
              'out': true,
              'bolt11': bolt11,
              if (amountMsat != null) 'amount': amountMsat,
            }
          },
          {
            'url': '$baseUrl/pay',
            'data': {
              'bolt11': bolt11,
              if (amountMsat != null) 'amount': amountMsat,
            }
          },
          {
            'url': '$baseUrl/api/v1/wallet/payments',
            'data': {
              'out': true,
              'bolt11': bolt11,
              if (amountMsat != null) 'amount': amountMsat,
            }
          },
          // Hold invoice endpoints for special invoices (RoboSats, P2P bots, etc.)
          {
            'url': '$baseUrl/hodlvoice/api/v1/pay',
            'data': {
              'bolt11': bolt11,
              if (amountMsat != null) 'amount': amountMsat,
            }
          },
          {
            'url': '$baseUrl/api/v1/payments/hodl',
            'data': {
              'out': true,
              'bolt11': bolt11,
              if (amountMsat != null) 'amount': amountMsat,
            }
          },
        ];
      } else {
        // Web/Desktop-optimized payment endpoints
        endpoints = [
          // Try with millisatoshis first (LNBits standard)
          {
            'url': '$baseUrl/api/v1/payments',
            'data': {
              'out': true,
              'bolt11': bolt11,
              if (amountMsat != null) 'amount': amountMsat,
            }
          },
          // Fallback: try with satoshis
          {
            'url': '$baseUrl/api/v1/payments',
            'data': {
              'out': true,
              'bolt11': bolt11,
              if (amount != null) 'amount': amount,
            }
          },
          {
            'url': '$baseUrl/node/api/v1/payments',
            'data': {
              'out': true,
              'bolt11': bolt11,
              if (amountMsat != null) 'amount': amountMsat,
            }
          },
          // Hold invoice endpoints
          {
            'url': '$baseUrl/hodlvoice/api/v1/pay',
            'data': {
              'bolt11': bolt11,
              if (amountMsat != null) 'amount': amountMsat,
            }
          },
          {
            'url': '$baseUrl/api/v1/payments/hodl',
            'data': {
              'out': true,
              'bolt11': bolt11,
              if (amountMsat != null) 'amount': amountMsat,
            }
          },
          {
            'url': '$baseUrl/api/v1/hodl',
            'data': {
              'bolt11': bolt11,
              'action': 'pay',
              if (amountMsat != null) 'amount': amountMsat,
            }
          },
        ];
      }

      Exception? lastException;
      
      // Try each endpoint until one works
      for (int i = 0; i < endpoints.length; i++) {
        final endpoint = endpoints[i];
        final url = endpoint['url'] as String;
        final data = endpoint['data'] as Map<String, dynamic>;
        
        try {
          _debugLog('[INVOICE_SERVICE] Trying endpoint $url (${i + 1}/${endpoints.length})');
          _debugLog('[INVOICE_SERVICE] Data: $data');
          _debugLog('[INVOICE_SERVICE] Platform: ${isAndroid ? "Android" : "Web/Desktop"}');
          _debugLog('[INVOICE_SERVICE] Headers: $headers');

          final response = await _dio.post(
            url,
            data: data,
            options: Options(
              headers: headers,
              method: 'POST',
              responseType: ResponseType.json,
              contentType: 'application/json',
            ),
          );

          if (response.statusCode == 201 || response.statusCode == 200) {
            _debugLog('[INVOICE_SERVICE] ✅ Payment sent successfully with: $url');
            _debugLog('[INVOICE_SERVICE] Response: ${response.data}');
            return response.data;
          }
        } catch (e) {
          _debugLog('[INVOICE_SERVICE] ❌ Failed $url: $e');
          lastException = e is Exception ? e : Exception(e.toString());

          // Check response body for definitive errors (stop trying other endpoints)
          String responseBody = '';
          if (e is DioException && e.response?.data != null) {
            responseBody = e.response!.data.toString().toLowerCase();
          }

          if (responseBody.contains('amountless invoices not supported')) {
            _debugLog('[INVOICE_SERVICE] 520 - Server does not support amountless invoices');
            throw Exception('AMOUNTLESS_INVOICE_NOT_SUPPORTED');
          }

          if (e.toString().contains('404')) {
            _debugLog('[INVOICE_SERVICE] 404 - Endpoint not available: $url');
            continue;
          }

          if (e.toString().contains('402')) {
            _debugLog('[INVOICE_SERVICE] 402 - Insufficient funds');
            throw Exception('Insufficient funds to make payment.');
          }

          if (e.toString().contains('401')) {
            _debugLog('[INVOICE_SERVICE] 401 - Authentication error');
            throw Exception('Authentication error. Verify credentials.');
          }

          continue;
        }
      }
      
      // All endpoints failed
      _debugLog('[INVOICE_SERVICE] ❌ All endpoints failed');
      if (lastException != null) {
        throw lastException;
      } else {
        throw Exception('Server error: Could not process payment');
      }
    } on DioException catch (e) {
      _debugLog('[INVOICE_SERVICE] DioException enviando pago: ${e.type}');
      _debugLog('[INVOICE_SERVICE] Error: ${e.message}');
      _debugLog('[INVOICE_SERVICE] Response: ${e.response?.data}');
      
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication error. Verify credentials.');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid or already paid invoice: ${e.response?.data}');
      } else if (e.response?.statusCode == 402) {
        throw Exception('Insufficient funds to make payment.');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Payment error: ${e.response?.data}');
      } else if (e.response?.statusCode == 520) {
        final detail = e.response?.data?.toString() ?? '';
        if (detail.toLowerCase().contains('amountless')) {
          throw Exception('AMOUNTLESS_INVOICE_NOT_SUPPORTED');
        }
        throw Exception('Lightning server error. Try again in a few moments.');
      } else {
        throw Exception('Error sending payment (${e.response?.statusCode ?? 'unknown'}): ${e.message}');
      }
    } catch (e) {
      _debugLog('[INVOICE_SERVICE] General payment error: $e');
      throw Exception('Unexpected error sending payment: $e');
    }
  }

  /// Sends payment to a Lightning Address using LNBits native endpoint
  /// 
  /// [serverUrl] - LNBits server URL
  /// [adminKey] - Wallet admin key
  /// [lightningAddress] - Target Lightning Address (user@domain.com)
  /// [amountSats] - Amount in satoshis
  /// [comment] - Optional comment
  /// 
  /// Returns payment data
  Future<Map<String, dynamic>> sendPaymentToLightningAddress({
    required String serverUrl,
    required String adminKey,
    required String lightningAddress,
    required int amountSats,
    String? comment,
  }) async {
    try {
      _debugLog('[INVOICE_SERVICE] 🚀 Sending payment to Lightning Address using native LNBits API');
      _debugLog('[INVOICE_SERVICE] Address: $lightningAddress');
      _debugLog('[INVOICE_SERVICE] Amount: $amountSats sats');

      String baseUrl = serverUrl;
      if (!baseUrl.startsWith('http')) {
        baseUrl = 'https://$baseUrl';
      }

      // Step 1: Resolve Lightning Address to get LNURL-pay metadata
      final addressParts = lightningAddress.split('@');
      if (addressParts.length != 2) {
        throw Exception('Invalid Lightning Address. Must have format: user@domain.com');
      }
      
      final username = addressParts[0];
      final domain = addressParts[1];
      
      _debugLog('[INVOICE_SERVICE] Resolving: $username@$domain');
      
      // Get LNURL-pay metadata from domain
      final metadataUrl = 'https://$domain/.well-known/lnurlp/$username';
      _debugLog('[INVOICE_SERVICE] Getting metadata from: $metadataUrl');
      
      final metadataResponse = await _dio.get(metadataUrl);
      
      if (metadataResponse.statusCode != 200) {
        throw Exception('Error getting Lightning Address metadata (${metadataResponse.statusCode})');
      }
      
      final metadata = metadataResponse.data as Map<String, dynamic>;
      
      // Validate it's a valid LNURL-pay endpoint
      if (metadata['tag'] != 'payRequest') {
        throw Exception('Lightning Address is not valid for payments');
      }
      
      // Validate amount limits
      final minSendable = metadata['minSendable'] as int;
      final maxSendable = metadata['maxSendable'] as int;
      final amountMsat = amountSats * 1000;
      
      if (amountMsat < minSendable) {
        throw Exception('Minimum amount: ${minSendable ~/ 1000} sats');
      }
      if (amountMsat > maxSendable) {
        throw Exception('Maximum amount: ${maxSendable ~/ 1000} sats');
      }
      
      // Calculate description_hash according to LNURL-pay protocol
      final metadataString = metadata['metadata'] as String;
      final bytes = utf8.encode(metadataString);
      final hash = sha256.convert(bytes);
      
      _debugLog('[INVOICE_SERVICE] Processed metadata:');
      _debugLog('[INVOICE_SERVICE] - Callback: ${metadata['callback']}');
      _debugLog('[INVOICE_SERVICE] - Min/Max: ${minSendable ~/ 1000}/${maxSendable ~/ 1000} sats');
      _debugLog('[INVOICE_SERVICE] - Description hash: ${hash.toString()}');
      
      // Step 2: Use native LNBits endpoint /api/v1/payments/lnurl
      final response = await _dio.post(
        '$baseUrl/api/v1/payments/lnurl',
        data: {
          'description_hash': hash.toString(),
          'callback': metadata['callback'],
          'amount': amountMsat,
          'comment': comment ?? '',
          'description': 'Payment to $lightningAddress',
        },
        options: Options(
          headers: {
            'X-API-KEY': adminKey,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _debugLog('[INVOICE_SERVICE] ✅ Payment sent successfully using native LNBits API');
        _debugLog('[INVOICE_SERVICE] Response: ${response.data}');
        return response.data;
      } else {
        throw Exception('Payment error: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      _debugLog('[INVOICE_SERVICE] ❌ Error sending payment to Lightning Address: $e');
      
      // Fallback: Try manual method if native endpoint fails
      if (e.toString().contains('404') || e.toString().contains('405')) {
        _debugLog('[INVOICE_SERVICE] 🔄 Native endpoint not available, using manual method...');
        return await _sendPaymentToLightningAddressManual(
          serverUrl: serverUrl,
          adminKey: adminKey,
          lightningAddress: lightningAddress,
          amountSats: amountSats,
          comment: comment,
        );
      }
      
      rethrow;
    }
  }

  /// Manual fallback method for Lightning Address
  /// Used when native endpoint /api/v1/payments/lnurl is not available
  Future<Map<String, dynamic>> _sendPaymentToLightningAddressManual({
    required String serverUrl,
    required String adminKey,
    required String lightningAddress,
    required int amountSats,
    String? comment,
  }) async {
    try {
      _debugLog('[INVOICE_SERVICE] 🔧 Using manual method for Lightning Address');
      
      // Resolve Lightning Address to BOLT11
      final bolt11 = await _resolveLightningAddressToBolt11(
        lightningAddress: lightningAddress,
        amountSats: amountSats,
        comment: comment,
        currentServerUrl: serverUrl,
      );

      _debugLog('[INVOICE_SERVICE] BOLT11 obtained, sending payment...');

      // Send payment using standard BOLT11 payment method
      return await sendPayment(
        serverUrl: serverUrl,
        adminKey: adminKey,
        bolt11: bolt11,
      );
    } catch (e) {
      if (e.toString().contains('CORS') || e.toString().contains('XMLHttpRequest')) {
        throw Exception('External Lightning Address not available from web browser due to CORS restrictions. Use mobile app for external payments.');
      } else {
        throw Exception('Error processing Lightning Address: $e');
      }
    }
  }

  /// Sends payment to an LNURL by first resolving to BOLT11
  /// 
  /// [serverUrl] - LNBits server URL
  /// [adminKey] - Wallet admin key
  /// [lnurl] - Target LNURL (lnurl1... format)
  /// [amountSats] - Amount in satoshis
  /// [comment] - Optional comment
  /// 
  /// Returns payment data
  Future<Map<String, dynamic>> sendPaymentToLNURL({
    required String serverUrl,
    required String adminKey,
    required String lnurl,
    required int amountSats,
    String? comment,
  }) async {
    try {
      _debugLog('[INVOICE_SERVICE] Resolving LNURL: ${lnurl.substring(0, 20)}...');
      _debugLog('[INVOICE_SERVICE] Amount: $amountSats sats');

      // Step 1: Resolve LNURL to BOLT11
      final bolt11 = await _resolveLNURLToBolt11(
        lnurl: lnurl,
        amountSats: amountSats,
        comment: comment,
      );

      _debugLog('[INVOICE_SERVICE] BOLT11 obtained, sending payment...');

      // Step 2: Pay the BOLT11 invoice
      return await sendPayment(
        serverUrl: serverUrl,
        adminKey: adminKey,
        bolt11: bolt11,
      );
    } catch (e) {
      _debugLog('[INVOICE_SERVICE] Error sending payment to LNURL: $e');
      rethrow;
    }
  }

  /// Resolves a Lightning Address to a BOLT11 invoice
  /// 
  /// [lightningAddress] - Lightning Address (user@domain.com)
  /// [amountSats] - Amount in satoshis
  /// [comment] - Optional comment
  /// [currentServerUrl] - Current server URL for comparison
  /// 
  /// Returns a BOLT11 invoice ready to pay
  Future<String> _resolveLightningAddressToBolt11({
    required String lightningAddress,
    required int amountSats,
    String? comment,
    String? currentServerUrl,
  }) async {
    try {
      _debugLog('[INVOICE_SERVICE] Resolving Lightning Address: $lightningAddress');
      
      final parts = lightningAddress.split('@');
      if (parts.length != 2) {
        throw Exception('Invalid Lightning Address');
      }
      
      final username = parts[0];
      final domain = parts[1];
      
      final isAndroid = !kIsWeb && Platform.isAndroid;
      final isWeb = kIsWeb;
      
      // Check if it's external domain on web - exit immediately to avoid CORS
      if (isWeb && currentServerUrl != null) {
        final serverUri = Uri.parse(currentServerUrl.startsWith('http') ? currentServerUrl : 'https://$currentServerUrl');
        final serverDomain = serverUri.host;
        
        if (!domain.contains(serverDomain) && !serverDomain.contains(domain)) {
          _debugLog('[INVOICE_SERVICE] 🙅 External domain detected on web: $domain != $serverDomain');
          throw Exception('External Lightning Address ($domain) not available from web browser due to CORS restrictions.\n\nOptions:\n1. Use mobile app\n2. Request BOLT11 invoice directly\n3. Use Lightning Address from same server ($serverDomain)');
        }
      }
      
      // Try multiple Lightning Address resolution endpoints
      final urls = [
        'https://$domain/.well-known/lnurlpay/$username',  // Standard LNURL-pay (LUD-16)
        'https://$domain/.well-known/lnaddress/$username', // Standard Lightning Address
        'https://$domain/lnurlp/api/v1/well-known/$username', // LNBits format
        'https://$domain/.well-known/lightning/$username',    // Legacy format
        'https://$domain/lnaddress/api/v1/$username',         // Direct API
        'https://$domain/api/v1/lnurlp/pay/$username',        // Alternative API
        // Specific endpoints for known servers
        if (domain.contains('cubabitcoin.org')) 'https://$domain/lnurlp/$username',
        if (domain.contains('btclake.com')) 'https://$domain/.well-known/lnurl/$username',
      ].where((url) => url != null).cast<String>().toList();
      
      _debugLog('[INVOICE_SERVICE] 🌍 Resolving ${isWeb ? "WEB" : "MOBILE"}: $lightningAddress ($domain)');
      
      Map<String, dynamic>? metadata;
      String? workingUrl;
      
      for (final url in urls) {
        try {
          _debugLog('[INVOICE_SERVICE] Trying resolution: $url');
          _debugLog('[INVOICE_SERVICE] Platform: ${isAndroid ? "Android" : "Web/Desktop"}');
          
          // Create specific client for external request
          final externalDio = Dio();
          externalDio.options.connectTimeout = isAndroid 
              ? const Duration(seconds: 20) 
              : const Duration(seconds: 15);
          externalDio.options.receiveTimeout = isAndroid 
              ? const Duration(seconds: 20) 
              : const Duration(seconds: 15);
          externalDio.options.headers['User-Agent'] = AppInfoService.getUserAgent();
          externalDio.options.headers['Accept'] = 'application/json';
          
          _configureProxyForDio(externalDio);
          
          if (isAndroid) {
            externalDio.options.headers['Cache-Control'] = 'no-cache';
            externalDio.options.followRedirects = true;
            externalDio.options.maxRedirects = 3;
          }
          
          final response = await externalDio.get(url);
          
          if (response.statusCode == 200 && response.data is Map) {
            final data = response.data as Map<String, dynamic>;
            if (data.containsKey('callback') && data['tag'] == 'payRequest') {
              metadata = data;
              workingUrl = url;
              _debugLog('[INVOICE_SERVICE] ✅ Resolution successful with: $url');
              externalDio.close();
              break;
            } else {
              _debugLog('[INVOICE_SERVICE] ❌ Response is not valid LNURL-pay: $data');
            }
          }
          externalDio.close();
        } catch (e) {
          _debugLog('[INVOICE_SERVICE] ❌ Error with $url: ${e.toString()}');
          if (e.toString().contains('CORS') || e.toString().contains('blocked')) {
            _debugLog('[INVOICE_SERVICE] 🚫 CORS error detected - external server blocks web requests');
          }
          continue;
        }
      }
      
      if (metadata == null) {
        throw Exception('Could not resolve Lightning Address: $lightningAddress.\n\nVerify that:\n1. The address is valid\n2. The server supports Lightning Address\n3. You have internet connection');
      }
      
      // Validate amount
      final minSendable = metadata['minSendable'] as int;
      final maxSendable = metadata['maxSendable'] as int;
      final amountMsat = amountSats * 1000;
      
      if (amountMsat < minSendable) {
        throw Exception('Minimum amount: ${minSendable ~/ 1000} sats');
      }
      if (amountMsat > maxSendable) {
        throw Exception('Maximum amount: ${maxSendable ~/ 1000} sats');
      }
      
      // Generate invoice using callback
      final callbackUrl = metadata['callback'] as String;
      final params = {'amount': amountMsat.toString()};
      if (comment != null && comment.isNotEmpty) {
        params['comment'] = comment;
      }
      
      _debugLog('[INVOICE_SERVICE] Generating invoice from callback: $callbackUrl');
      
      // Use external client for callback as well
      final callbackDio = Dio();
      callbackDio.options.connectTimeout = const Duration(seconds: 15);
      callbackDio.options.receiveTimeout = const Duration(seconds: 15);
      callbackDio.options.headers['User-Agent'] = AppInfoService.getUserAgent();
      callbackDio.options.headers['Accept'] = 'application/json';
      
      _configureProxyForDio(callbackDio);
      
      try {
        final callbackResponse = await callbackDio.get(callbackUrl, queryParameters: params);
        
        if (callbackResponse.statusCode == 200) {
          final callbackData = callbackResponse.data;
          if (callbackData['pr'] != null) {
            final bolt11 = callbackData['pr'] as String;
            _debugLog('[INVOICE_SERVICE] ✅ BOLT11 generated successfully');
            callbackDio.close();
            return bolt11;
          }
        }
        callbackDio.close();
      } catch (e) {
        callbackDio.close();
        _debugLog('[INVOICE_SERVICE] Callback error: $e');
        rethrow;
      }
      
      throw Exception('Error generating invoice from Lightning Address');
    } catch (e) {
      _debugLog('[INVOICE_SERVICE] Error resolving Lightning Address: $e');
      rethrow;
    }
  }

  /// Resolves an LNURL to a BOLT11 invoice
  /// 
  /// [lnurl] - LNURL (lnurl1... format)
  /// [amountSats] - Amount in satoshis
  /// [comment] - Optional comment
  /// 
  /// Returns a BOLT11 invoice ready to pay
  Future<String> _resolveLNURLToBolt11({
    required String lnurl,
    required int amountSats,
    String? comment,
  }) async {
    try {
      _debugLog('[INVOICE_SERVICE] Resolving LNURL: ${lnurl.substring(0, 20)}...');
      
      // Decode LNURL (bech32) to URL
      final url = _decodeLNURL(lnurl);
      _debugLog('[INVOICE_SERVICE] Decoded URL: $url');
      
      // Create specific client for LNURL as well
      final lnurlDio = Dio();
      lnurlDio.options.connectTimeout = const Duration(seconds: 15);
      lnurlDio.options.receiveTimeout = const Duration(seconds: 15);
      lnurlDio.options.headers['User-Agent'] = AppInfoService.getUserAgent();
      lnurlDio.options.headers['Accept'] = 'application/json';
      
      _configureProxyForDio(lnurlDio);
      
      _debugLog('[INVOICE_SERVICE] Making GET request to: $url');
      _debugLog('[INVOICE_SERVICE] Headers: ${lnurlDio.options.headers}');
      
      // Get LNURL-pay metadata
      final response = await lnurlDio.get(url);
      lnurlDio.close();
      if (response.statusCode != 200 || response.data is! Map) {
        throw Exception('Error getting LNURL metadata');
      }
      
      final metadata = response.data as Map<String, dynamic>;
      if (metadata['tag'] != 'payRequest') {
        throw Exception('LNURL is not for payments');
      }
      
      // Validate amount
      final minSendable = metadata['minSendable'] as int;
      final maxSendable = metadata['maxSendable'] as int;
      final amountMsat = amountSats * 1000;
      
      if (amountMsat < minSendable) {
        throw Exception('Minimum amount: ${minSendable ~/ 1000} sats');
      }
      if (amountMsat > maxSendable) {
        throw Exception('Maximum amount: ${maxSendable ~/ 1000} sats');
      }
      
      // Generate invoice using callback
      final callbackUrl = metadata['callback'] as String;
      final params = {'amount': amountMsat.toString()};
      if (comment != null && comment.isNotEmpty) {
        params['comment'] = comment;
      }
      
      _debugLog('[INVOICE_SERVICE] Generating invoice from callback: $callbackUrl');
      final callbackResponse = await _dio.get(callbackUrl, queryParameters: params);
      
      if (callbackResponse.statusCode == 200) {
        final callbackData = callbackResponse.data;
        if (callbackData['pr'] != null) {
          return callbackData['pr'] as String;
        }
      }
      
      throw Exception('Error generating invoice from LNURL');
    } catch (e) {
      _debugLog('[INVOICE_SERVICE] Error resolving LNURL: $e');
      rethrow;
    }
  }

  /// Decodes LNURL (bech32) to URL
  String _decodeLNURL(String lnurl) {
    try {
      _debugLog('[INVOICE_SERVICE] Decoding LNURL: ${lnurl.substring(0, 20)}...');
      
      String normalized = lnurl.toLowerCase().trim();
      
      if (!normalized.startsWith('lnurl1')) {
        throw Exception('LNURL must start with lnurl1');
      }
      
      String data = normalized.substring(6);
      
      // Basic bech32 decoding implementation
      final decoded = _bech32Decode(data);
      final url = String.fromCharCodes(decoded);
      
      _debugLog('[INVOICE_SERVICE] Decoded URL: $url');
      return url;
    } catch (e) {
      _debugLog('[INVOICE_SERVICE] Error decoding LNURL: $e');
      throw Exception('Error decoding LNURL: $e');
    }
  }

  /// Basic bech32 decoding for LNURL
  List<int> _bech32Decode(String data) {
    const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
    
    try {
      _debugLog('[INVOICE_SERVICE] Decoding data: $data');
      
      // Convert characters to 5-bit values
      final values = data.split('').map((char) {
        final index = charset.indexOf(char);
        if (index == -1) throw Exception('Invalid character in LNURL: $char');
        return index;
      }).toList();
      
      _debugLog('[INVOICE_SERVICE] 5-bit values: ${values.length} elements');
      
      // Last 6 characters are checksum in bech32
      if (values.length < 6) {
        throw Exception('LNURL too short to have valid checksum');
      }
      
      // Remove checksum (last 6 elements) to get only data
      final dataValues = values.sublist(0, values.length - 6);
      _debugLog('[INVOICE_SERVICE] Data without checksum: ${dataValues.length} elements');
      
      // Convert from 5-bit to 8-bit
      final decoded = _convertBits(dataValues, 5, 8, false);
      if (decoded == null || decoded.isEmpty) {
        throw Exception('Error converting bits from 5 to 8');
      }
      
      _debugLog('[INVOICE_SERVICE] Decoded data: ${decoded.length} bytes');
      return decoded;
    } catch (e) {
      _debugLog('[INVOICE_SERVICE] Detailed bech32 error: $e');
      throw Exception('Error in bech32 decoding: $e');
    }
  }

  /// Converts bits between different bases
  List<int>? _convertBits(List<int> data, int fromBits, int toBits, bool pad) {
    var acc = 0;
    var bits = 0;
    final result = <int>[];
    final maxv = (1 << toBits) - 1;
    final maxAcc = (1 << (fromBits + toBits - 1)) - 1;
    
    for (final value in data) {
      if (value < 0 || (value >> fromBits) != 0) {
        return null;
      }
      acc = ((acc << fromBits) | value) & maxAcc;
      bits += fromBits;
      
      while (bits >= toBits) {
        bits -= toBits;
        result.add((acc >> bits) & maxv);
      }
    }
    
    if (pad) {
      if (bits > 0) {
        result.add((acc << (toBits - bits)) & maxv);
      }
    } else if (bits >= fromBits || ((acc << (toBits - bits)) & maxv) != 0) {
      return null;
    }
    
    return result;
  }

  /// Detects if an invoice is a hold invoice based on known patterns
  /// 
  /// [bolt11] - Lightning invoice to analyze
  /// 
  /// Returns true if it's likely a hold invoice
  bool _isHoldInvoice(String bolt11) {
    try {
      // Hold invoices often have specific characteristics:
      // - May have specific descriptions
      // - Usually have different metadata
      // - For now, we use basic heuristics
      
      final lowerBolt11 = bolt11.toLowerCase();
      
      // Known patterns of hold invoices
      final holdPatterns = [
        'hodl',
        'hold',
        'escrow',
        'conditional',
        'pending',
        'order #',        // Order patterns (RoboSats, etc)
        'robosats',       // RoboSats specifically
        'lnp2p',          // LNP2P bot
        'lnp2pbot',       // LNP2P bot specifically
        'mostrop2p',      // Mostro P2P
        'mostro',         // Mostro
        'sell btc',       // Sell orders
        'buy btc',        // Buy orders
        'will freeze',    // Common text in hold invoices
        'locked',         // Locked bitcoin
        'reserved',       // Reserved bitcoin
      ];
      
      // Check if invoice contains hold invoice patterns
      for (final pattern in holdPatterns) {
        if (lowerBolt11.contains(pattern)) {
          _debugLog('[INVOICE_SERVICE] 🔒 Hold invoice detected by pattern: $pattern');
          return true;
        }
      }
      
      _debugLog('[INVOICE_SERVICE] 📄 Standard invoice detected');
      return false;
    } catch (e) {
      _debugLog('[INVOICE_SERVICE] Error detecting invoice type: $e');
      return false; // Assume standard invoice on error
    }
  }

  /// Analyzes a decoded invoice to determine if it's a hold invoice
  /// 
  /// [decodedData] - Decoded invoice data
  /// 
  /// Returns true if it's a hold invoice
  bool _isHoldInvoiceFromDecoded(Map<String, dynamic> decodedData) {
    try {
      // Check specific fields of hold invoices
      if (decodedData.containsKey('payment_hash')) {
        final description = decodedData['description']?.toString()?.toLowerCase() ?? '';
        final memo = decodedData['memo']?.toString()?.toLowerCase() ?? '';
        
        // Expanded patterns for hold invoice detection
        final holdPatterns = [
          'hodl', 'hold', 'escrow', 'conditional', 'pending',
          'order #', 'robosats', 'lnp2p', 'lnp2pbot', 'mostrop2p', 'mostro',
          'sell btc', 'buy btc', 'will freeze', 'locked', 'reserved'
        ];
        
        for (final pattern in holdPatterns) {
          if (description.contains(pattern) || memo.contains(pattern)) {
            _debugLog('[INVOICE_SERVICE] 🔒 Hold invoice detected in description/memo: $pattern');
            return true;
          }
        }
      }
      
      // Check if it has specific metadata of hold invoices
      if (decodedData.containsKey('route_hints') && 
          decodedData['route_hints'] is List &&
          (decodedData['route_hints'] as List).isEmpty) {
        // Hold invoices sometimes don't have route hints
        return true;
      }
      
      return false;
    } catch (e) {
      _debugLog('[INVOICE_SERVICE] Error analyzing decoded invoice: $e');
      return false;
    }
  }

  /// Public method to validate Lightning Address
  /// Verifies it has the correct format user@domain.com
  static bool isValidLightningAddress(String address) {
    final parts = address.split('@');
    if (parts.length != 2) return false;
    
    final username = parts[0];
    final domain = parts[1];
    
    if (username.isEmpty) return false;
    if (!domain.contains('.')) return false;
    if (domain.endsWith('.')) return false;
    
    return true;
  }
  
  bool _isValidLightningAddress(String address) {
    return InvoiceService.isValidLightningAddress(address);
  }

  /// Checks if Lightning Address is from the same domain as the server
  bool _isSameDomain(String lightningAddress, String serverUrl) {
    try {
      final addressDomain = lightningAddress.split('@')[1];
      final serverUri = Uri.parse(serverUrl.startsWith('http') ? serverUrl : 'https://$serverUrl');
      final serverDomain = serverUri.host;
      
      return addressDomain.toLowerCase() == serverDomain.toLowerCase();
    } catch (e) {
      return false;
    }
  }

  /// Gets information about an LNURL-withdraw voucher without claiming it
  /// 
  /// [lnurl] - LNURL-withdraw voucher code
  /// 
  /// Returns voucher information for user confirmation
  Future<Map<String, dynamic>> getVoucherInfo({
    required String lnurl,
  }) async {
    try {
      _debugLog('[INVOICE_SERVICE] Getting LNURL-withdraw voucher info');
      _debugLog('[INVOICE_SERVICE] LNURL: ${lnurl.substring(0, 20)}...');
      
      // Step 1: Decode LNURL to get the actual URL
      final url = _decodeLNURL(lnurl);
      _debugLog('[INVOICE_SERVICE] Decoded URL: $url');
      
      // Step 2: GET the voucher metadata
      final metadataResponse = await _dio.get(url);
      
      if (metadataResponse.statusCode != 200) {
        throw Exception('Error obteniendo metadata del voucher (${metadataResponse.statusCode})');
      }
      
      final metadata = metadataResponse.data as Map<String, dynamic>;
      _debugLog('[INVOICE_SERVICE] Voucher metadata: $metadata');
      
      // Step 3: Validate it's a withdraw request
      if (metadata['tag'] != 'withdrawRequest') {
        throw Exception('El código no es un voucher válido (tag: ${metadata['tag']})');
      }
      
      // Step 4: Extract voucher details
      final minWithdrawable = metadata['minWithdrawable'] as int;
      final maxWithdrawable = metadata['maxWithdrawable'] as int;
      final callback = metadata['callback'] as String;
      final k1 = metadata['k1'] as String;
      final defaultDescription = metadata['defaultDescription'] as String? ?? 'Voucher LNURL-withdraw';
      
      final minSats = minWithdrawable ~/ 1000;
      final maxSats = maxWithdrawable ~/ 1000;
      
      _debugLog('[INVOICE_SERVICE] Voucher info - Min: $minSats sats, Max: $maxSats sats');
      _debugLog('[INVOICE_SERVICE] Description: $defaultDescription');
      
      return {
        'valid': true,
        'minWithdrawable': minWithdrawable,
        'maxWithdrawable': maxWithdrawable,
        'minSats': minSats,
        'maxSats': maxSats,
        'callback': callback,
        'k1': k1,
        'description': defaultDescription,
        'lnurl': lnurl,
        // Check if it's a fixed amount or range
        'isFixedAmount': minWithdrawable == maxWithdrawable,
      };
      
    } catch (e) {
      _debugLog('[INVOICE_SERVICE] Error obteniendo info de voucher: $e');
      
      // Analyze the error and throw a specific exception type
      final errorAnalysis = _analyzeVoucherError(e);
      throw VoucherException(errorAnalysis['type']!, errorAnalysis['technical']!);
    }
  }

  /// Claims an LNURL-withdraw voucher after user confirmation
  /// 
  /// [voucherInfo] - Voucher information from getVoucherInfo
  /// [adminKey] - Wallet admin key
  /// [serverUrl] - LNBits server URL
  /// [amountSats] - Amount to claim (within min/max range)
  /// 
  /// Returns claim result data
  Future<Map<String, dynamic>> claimVoucher({
    required Map<String, dynamic> voucherInfo,
    required String adminKey,
    required String serverUrl,
    required int amountSats,
  }) async {
    try {
      _debugLog('[INVOICE_SERVICE] Claiming LNURL-withdraw voucher');
      _debugLog('[INVOICE_SERVICE] Amount to claim: $amountSats sats');
      
      // Validate amount is within voucher limits
      final minSats = voucherInfo['minSats'] as int;
      final maxSats = voucherInfo['maxSats'] as int;
      
      if (amountSats < minSats || amountSats > maxSats) {
        throw Exception('Cantidad inválida. Debe estar entre $minSats y $maxSats sats');
      }
      
      final callback = voucherInfo['callback'] as String;
      final k1 = voucherInfo['k1'] as String;
      final description = voucherInfo['description'] as String;
      
      // Step 1: Create an invoice for the requested amount
      final invoice = await createInvoice(
        serverUrl: serverUrl,
        adminKey: adminKey,
        amount: amountSats,
        memo: description,
      );
      
      _debugLog('[INVOICE_SERVICE] Created invoice for $amountSats sats');
      _debugLog('[INVOICE_SERVICE] Invoice: ${invoice.paymentRequest.substring(0, 20)}...');
      
      // Step 2: Send the invoice to the callback to claim the voucher
      final claimResponse = await _dio.get(
        callback,
        queryParameters: {
          'k1': k1,
          'pr': invoice.paymentRequest,
        },
      );
      
      if (claimResponse.statusCode != 200) {
        throw Exception('Error reclamando voucher (${claimResponse.statusCode})');
      }
      
      final claimResult = claimResponse.data as Map<String, dynamic>;
      _debugLog('[INVOICE_SERVICE] Claim result: $claimResult');
      
      // Step 3: Check if the claim was successful
      if (claimResult['status'] == 'OK') {
        _debugLog('[INVOICE_SERVICE] ✅ Voucher claimed successfully');
        
        return {
          'success': true,
          'amount': amountSats,
          'description': description,
          'invoice_hash': invoice.paymentHash,
          'invoice': invoice.paymentRequest,
        };
      } else {
        final reason = claimResult['reason'] ?? 'Error desconocido';
        throw Exception('Error del servidor: $reason');
      }
      
    } catch (e) {
      _debugLog('[INVOICE_SERVICE] Error reclamando voucher: $e');
      
      // Analyze the error and throw a specific exception type
      final errorAnalysis = _analyzeVoucherError(e);
      throw VoucherException(errorAnalysis['type']!, errorAnalysis['technical']!);
    }
  }

  /// Analyzes the error response and returns a specific error type and message
  /// This helps provide user-friendly error messages for different voucher errors
  Map<String, String> _analyzeVoucherError(dynamic error) {
    String errorType = 'generic';
    String technicalMessage = error.toString().toLowerCase();
    
    // Check for DioException with response data
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data?.toString()?.toLowerCase() ?? '';
      
      _debugLog('[INVOICE_SERVICE] Analyzing error - Status: $statusCode, Data: $responseData');
      
      // Analyze by status code first
      switch (statusCode) {
        case 400:
          if (responseData.contains('already') || responseData.contains('used') || responseData.contains('claimed')) {
            errorType = 'already_claimed';
          } else if (responseData.contains('invalid') || responseData.contains('malformed')) {
            errorType = 'invalid_code';
          } else if (responseData.contains('amount')) {
            errorType = 'invalid_amount';
          } else {
            errorType = 'invalid_code';
          }
          break;
          
        case 404:
          if (responseData.contains('expired') || responseData.contains('expire')) {
            errorType = 'expired';
          } else {
            errorType = 'not_found';
          }
          break;
          
        case 429:
          errorType = 'server_error'; // Rate limited
          break;
          
        case 500:
        case 502:
        case 503:
          errorType = 'server_error';
          break;
          
        default:
          if (error.type == DioExceptionType.connectionTimeout || 
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError) {
            errorType = 'connection_error';
          } else {
            errorType = 'generic';
          }
      }
      
      // Additional content-based analysis
      if (responseData.contains('insufficient') || responseData.contains('not enough')) {
        errorType = 'insufficient_funds';
      } else if (responseData.contains('expired') || responseData.contains('expire')) {
        errorType = 'expired';
      } else if (responseData.contains('already') || responseData.contains('used') || responseData.contains('claimed')) {
        errorType = 'already_claimed';
      } else if (responseData.contains('tag') && responseData.contains('null')) {
        errorType = 'invalid_code';
      }
    } else {
      // Analyze generic exceptions
      if (technicalMessage.contains('already') || technicalMessage.contains('used') || technicalMessage.contains('claimed')) {
        errorType = 'already_claimed';
      } else if (technicalMessage.contains('expired') || technicalMessage.contains('expire')) {
        errorType = 'expired';
      } else if (technicalMessage.contains('not found') || technicalMessage.contains('404')) {
        errorType = 'not_found';
      } else if (technicalMessage.contains('connection') || technicalMessage.contains('network')) {
        errorType = 'connection_error';
      } else if (technicalMessage.contains('server') || technicalMessage.contains('500')) {
        errorType = 'server_error';
      } else if (technicalMessage.contains('invalid') || technicalMessage.contains('tag') || technicalMessage.contains('null')) {
        errorType = 'invalid_code';
      }
    }
    
    return {
      'type': errorType,
      'technical': error.toString(),
    };
  }

  void dispose() {
    _dio.close();
  }
}

/// Custom exception for voucher-related errors with specific error types
class VoucherException implements Exception {
  final String type;
  final String technicalMessage;

  const VoucherException(this.type, this.technicalMessage);

  @override
  String toString() => 'VoucherException: $type - $technicalMessage';
}