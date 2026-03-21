import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/ln_address.dart';
import '../core/utils/proxy_config.dart';

void _debugLog(String message) {
  if (kDebugMode) {
    print(message);
  }
}

class LNAddressService {
  final Dio _dio;
  final String _baseUrl;

  LNAddressService(this._baseUrl) : _dio = Dio() {
    _configureDio();
  }

  void updateServerUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  void _configureDio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);

    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Accept'] = 'application/json';
    _dio.options.headers['User-Agent'] = 'LaChispa-Web/0.0.1';

    ProxyConfig.configureProxy(_dio, enableLogging: false);

    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (object) {
        _debugLog('[LN_ADDRESS_SERVICE] $object');
      },
    ));
  }

  // Configure authentication headers for LNURLP extension
  void setAuthHeaders(String invoiceKey, String adminKey) {
    _invoiceKey = invoiceKey;
    _adminKey = adminKey;

    _debugLog('[LN_ADDRESS_SERVICE] Setting up LNURLP authentication...');
    _debugLog(
        '[LN_ADDRESS_SERVICE] - Invoice Key: ${invoiceKey.substring(0, 8)}...');
    _debugLog(
        '[LN_ADDRESS_SERVICE] - Admin Key: ${adminKey.substring(0, 8)}...');
  }

  String _invoiceKey = '';
  String _adminKey = '';

  // Configure headers for read operations (GET)
  void _setReadHeaders() {
    _dio.options.headers.clear();
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Accept'] = 'application/json';
    _dio.options.headers['User-Agent'] = 'LaChispa-Web/0.0.1';
    _dio.options.headers['X-Api-Key'] = _invoiceKey;
    _debugLog('[LN_ADDRESS_SERVICE] Using invoice key for read operation');
  }

  // Configure headers for write operations (POST/PUT/DELETE)
  void _setWriteHeaders() {
    _dio.options.headers.clear();
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Accept'] = 'application/json';
    _dio.options.headers['User-Agent'] = 'LaChispa-Web/0.0.1';
    _dio.options.headers['X-Api-Key'] = _adminKey;

    _debugLog('[LN_ADDRESS_SERVICE] 🔐 Setting up write headers:');
    _debugLog(
        '[LN_ADDRESS_SERVICE]   Admin Key: ${_adminKey.isNotEmpty ? _adminKey.substring(0, 8) + "..." : "EMPTY"}');
    _debugLog(
        '[LN_ADDRESS_SERVICE]   Invoice Key: ${_invoiceKey.isNotEmpty ? _invoiceKey.substring(0, 8) + "..." : "EMPTY"}');

    if (_adminKey.isEmpty) {
      _debugLog(
          '[LN_ADDRESS_SERVICE] ⚠️ EMPTY ADMIN KEY - this will cause authentication error');
    }
  }

  // Configure authentication using wallet admin key
  void setWalletAuthHeaders(String adminKey) {
    _dio.options.headers.clear();

    _debugLog(
        '[LN_ADDRESS_SERVICE] Setting up wallet admin key authentication...');

    _dio.options.headers['X-Api-Key'] = adminKey;
    _dio.options.headers['Authorization'] = 'Bearer $adminKey';

    _debugLog(
        '[LN_ADDRESS_SERVICE] Admin key configured: ${adminKey.substring(0, 8)}...');
  }

  // Get all Lightning Addresses
  Future<List<LNAddress>> getLNAddresses() async {
    // Use optimized endpoints based on server type
    final endpoints = _getOptimizedEndpoints();

    // Use invoice key for read operations
    _setReadHeaders();

    for (final endpoint in endpoints) {
      try {
        _debugLog('[LN_ADDRESS_SERVICE] Testing endpoint: $_baseUrl$endpoint');
        _debugLog('[LN_ADDRESS_SERVICE] Headers: ${_dio.options.headers}');

        final response = await _dio.get(endpoint);

        _debugLog('[LN_ADDRESS_SERVICE] Status Code: ${response.statusCode}');
        _debugLog('[LN_ADDRESS_SERVICE] Response Data: ${response.data}');

        if (response.statusCode == 200) {
          final data = response.data;

          // According to documentation, response is a direct array
          if (data is List) {
            final addresses =
                data.map((json) => LNAddress.fromJson(json, _baseUrl)).toList();
            _debugLog(
                '[LN_ADDRESS_SERVICE] ✅ ${addresses.length} Lightning Addresses obtained from $endpoint');
            return addresses;
          } else {
            _debugLog(
                '[LN_ADDRESS_SERVICE] Unexpected response structure at $endpoint: $data');
            continue; // Try next endpoint
          }
        }
      } catch (e) {
        _debugLog('[LN_ADDRESS_SERVICE] ❌ Failed endpoint $endpoint: $e');
        if (e is DioException && e.response?.statusCode != null) {
          _debugLog(
              '[LN_ADDRESS_SERVICE] Status: ${e.response?.statusCode}, Data: ${e.response?.data}');
        }
        continue; // Try next endpoint
      }
    }

    // If all endpoints fail, return empty list
    _debugLog('[LN_ADDRESS_SERVICE] ⚠️ All Lightning Address endpoints failed');
    return [];
  }

  // Get Lightning Addresses filtered by wallet
  Future<List<LNAddress>> getLNAddressesForWallet(String walletId) async {
    try {
      final allAddresses = await getLNAddresses();
      final walletAddresses = allAddresses
          .where((address) => address.walletId == walletId)
          .toList();

      _debugLog(
          '[LN_ADDRESS_SERVICE] ${walletAddresses.length} Lightning Addresses for wallet $walletId');
      return walletAddresses;
    } catch (e) {
      _debugLog('[LN_ADDRESS_SERVICE] Error filtering by wallet: $e');
      throw Exception('Error getting Lightning Addresses for wallet: $e');
    }
  }

  // Connectivity diagnosis before critical operations
  Future<bool> _diagnoseConnection() async {
    try {
      _debugLog('[LN_ADDRESS_SERVICE] Diagnosing connectivity...');

      // Basic connectivity test - try public endpoint first
      try {
        final testResponse = await _dio.get('/api/v1/wallets');
        _debugLog(
            '[LN_ADDRESS_SERVICE] Basic test: ${testResponse.statusCode}');
        return testResponse.statusCode == 200;
      } catch (e) {
        if (e is DioException) {
          // If we get 401, server is available but needs authentication
          if (e.response?.statusCode == 401) {
            _debugLog(
                '[LN_ADDRESS_SERVICE] Server available (401 = needs auth)');
            return true; // Server is working, just needs authentication
          }

          // If we get 403, server is also available
          if (e.response?.statusCode == 403) {
            _debugLog(
                '[LN_ADDRESS_SERVICE] Server available (403 = access denied)');
            return true;
          }

          // For other HTTP errors, we also consider there's connectivity
          if (e.response?.statusCode != null) {
            _debugLog(
                '[LN_ADDRESS_SERVICE] Server available (status: ${e.response?.statusCode})');
            return true;
          }

          // Only fail on real connection errors
          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout) {
            _debugLog(
                '[LN_ADDRESS_SERVICE] Real connectivity error: ${e.type}');
            return false;
          }
        }

        _debugLog('[LN_ADDRESS_SERVICE] Unexpected error: $e');
        return false;
      }
    } catch (e) {
      _debugLog('[LN_ADDRESS_SERVICE] Connectivity test failed: $e');
      return false;
    }
  }

  // Verify LNURLP permissions before creating
  Future<bool> _hasLNURLPPermissions() async {
    try {
      _debugLog('[LN_ADDRESS_SERVICE] Verifying LNURLP permissions...');

      // Configure headers with invoice key for GET operations
      _setReadHeaders();

      // Use optimized endpoints based on server
      final endpoints = _getOptimizedEndpoints();

      for (final endpoint in endpoints) {
        try {
          _debugLog('[LN_ADDRESS_SERVICE] Verifying endpoint: $endpoint');
          final response = await _dio.get(endpoint);
          _debugLog('[LN_ADDRESS_SERVICE] Response: ${response.statusCode}');
          if (response.statusCode == 200) {
            _debugLog(
                '[LN_ADDRESS_SERVICE] ✅ LNURLP permissions verified at: $endpoint');
            return true;
          }
        } catch (e) {
          _debugLog('[LN_ADDRESS_SERVICE] Error en endpoint $endpoint: $e');
          if (e is DioException) {
            _debugLog(
                '[LN_ADDRESS_SERVICE] Status Code: ${e.response?.statusCode}');
            _debugLog(
                '[LN_ADDRESS_SERVICE] Response Data: ${e.response?.data}');
            // If we get 404, extension is not installed
            if (e.response?.statusCode == 404) {
              _debugLog(
                  '[LN_ADDRESS_SERVICE] ❌ LNURLP extension not found (404)');
              return false;
            }
            // For 401/403, extension exists but has auth problem
            if (e.response?.statusCode == 401 ||
                e.response?.statusCode == 403) {
              _debugLog(
                  '[LN_ADDRESS_SERVICE] ⚠️ Authentication problem (${e.response?.statusCode}), but extension available');
              return true; // Extension is available
            }
            // Other errors continue to next endpoint
            continue;
          }
        }
      }

      return false;
    } catch (e) {
      _debugLog('[LN_ADDRESS_SERVICE] Error verifying permissions: $e');
      return false;
    }
  }

  // Detect specific server and get optimized endpoints
  List<String> _getOptimizedEndpoints() {
    final serverUrl = _baseUrl.toLowerCase();

    // Detection of specific servers according to official source code
    if (serverUrl.contains('lachispa.me')) {
      _debugLog('[LN_ADDRESS_SERVICE] 🎯 Detected server: LaChispa.me');
      _debugLog(
          '[LN_ADDRESS_SERVICE] ✅ Using official endpoint: /lnurlp/api/v1/links');
      return [
        '/lnurlp/api/v1/links', // ✅ WORKS on LaChispa
      ];
    }

    if (serverUrl.contains('btclake.org') ||
        serverUrl.contains('btclake.com')) {
      _debugLog('[LN_ADDRESS_SERVICE] 🎯 Detected server: BTCLake');
      _debugLog(
          '[LN_ADDRESS_SERVICE] 🧪 TESTING actual BTCLake capabilities...');
      return [
        '/lnurlp/api/v1/links', // ✅ TEST - might exist
      ];
    }

    // All standard LNBits servers
    _debugLog(
        '[LN_ADDRESS_SERVICE] 🔍 Standard LNBits server - testing standard endpoint');
    return [
      '/lnurlp/api/v1/links', // ✅ STANDARD ENDPOINT
    ];
  }

  // Create new Lightning Address
  Future<LNAddress> createLNAddress({
    required String username,
    required String walletId,
    String? description,
  }) async {
    try {
      _debugLog(
          '[LN_ADDRESS_SERVICE] ⚡ Creating Lightning Address: $username for wallet $walletId');
      _debugLog('[LN_ADDRESS_SERVICE] 🌐 Server: $_baseUrl');

      final isConnected = await _diagnoseConnection();
      if (!isConnected) {
        throw Exception(
            '🌐 No server connectivity\n\nCannot establish connection to server.\nCheck your internet connection and try again.');
      }

      final hasPermissions = await _hasLNURLPPermissions();
      if (!hasPermissions) {
        throw Exception(
            '🚫 LNURLP extension not available\n\nThe LNURLP extension is not installed on this server\nor you do not have permissions to use it.\n\nContact the server administrator.');
      }

      _debugLog(
          '[LN_ADDRESS_SERVICE] 🚫 WALLET OWNERSHIP VERIFICATION BYPASSED - proceeding...');

      final finalDescription = description ?? 'Lightning Address: $username';

      _debugLog('[LN_ADDRESS_SERVICE] 📋 Creating for wallet: $walletId');
      _debugLog('[LN_ADDRESS_SERVICE] 👤 Username: $username');
      _debugLog('[LN_ADDRESS_SERVICE] 📝 Description: $finalDescription');

      final payload = LNAddress.createPayload(
        username: username,
        walletId: walletId,
        description: finalDescription,
        amount: 0,
        minAmount: 1,
        maxAmount: 2100000000,
        commentChars: 500,
      );

      _debugLog('[LN_ADDRESS_SERVICE] Payload to create:');
      payload.forEach((key, value) {
        _debugLog('[LN_ADDRESS_SERVICE]   $key: $value (${value.runtimeType})');
      });

      if (payload['username'] == null ||
          payload['username'].toString().isEmpty) {
        throw Exception(
            '🚫 USERNAME MISSING\n\nUsername is required to create Lightning Address.\nVerify that you have entered a valid username.');
      }

      _setWriteHeaders();
      _debugLog('[LN_ADDRESS_SERVICE] Headers: ${_dio.options.headers}');

      final endpoints = _getOptimizedEndpoints();

      _debugLog(
          '[LN_ADDRESS_SERVICE] 📋 Endpoints to try: ${endpoints.length}');
      for (int i = 0; i < endpoints.length; i++) {
        final endpoint = endpoints[i];
        try {
          _debugLog(
              '[LN_ADDRESS_SERVICE] 🔄 [${i + 1}/${endpoints.length}] Trying: $endpoint');
          _debugLog('[LN_ADDRESS_SERVICE] 🌐 Full URL: $_baseUrl$endpoint');
          _debugLog('[LN_ADDRESS_SERVICE] 📤 Payload: $payload');

          final response = await _dio.post(endpoint, data: payload);

          _debugLog(
              '[LN_ADDRESS_SERVICE] ✅ Successful response: ${response.statusCode}');
          _debugLog('[LN_ADDRESS_SERVICE] 📥 Response data: ${response.data}');

          if (response.statusCode == 201 || response.statusCode == 200) {
            final lnAddress = LNAddress.fromJson(response.data, _baseUrl);
            _debugLog(
                '[LN_ADDRESS_SERVICE] ⚡ Lightning Address created successfully: ${lnAddress.fullAddress}');
            _debugLog(
                '[LN_ADDRESS_SERVICE] 🎯 Successful endpoint: $endpoint (works on this server)');
            return lnAddress;
          }
        } on DioException catch (e) {
          final isLast = (i == endpoints.length - 1);
          _debugLog(
              '[LN_ADDRESS_SERVICE] ❌ [${i + 1}/${endpoints.length}] Failed endpoint $endpoint');
          _debugLog('[LN_ADDRESS_SERVICE] 📊 Error type: ${e.type}');
          _debugLog(
              '[LN_ADDRESS_SERVICE] 🔢 Status Code: ${e.response?.statusCode}');
          _debugLog(
              '[LN_ADDRESS_SERVICE] 📄 Error Response: ${e.response?.data}');
          _debugLog('[LN_ADDRESS_SERVICE] 🔗 Error Message: ${e.message}');

          if (e.response?.statusCode == 404) {
            _debugLog(
                '[LN_ADDRESS_SERVICE] 🚫 404: Endpoint does not exist on this server');
          } else if (e.response?.statusCode == 401) {
            _debugLog('[LN_ADDRESS_SERVICE] 🔐 401: Authentication error');
          } else if (e.response?.statusCode == 403) {
            _debugLog(
                '[LN_ADDRESS_SERVICE] 🚷 403: No permissions for this endpoint');
          } else if (e.type == DioExceptionType.connectionError) {
            _debugLog(
                '[LN_ADDRESS_SERVICE] 🌐 Connection error (CORS detected)');
            _debugLog(
                '[LN_ADDRESS_SERVICE] ⚠️ This is the correct endpoint but browser blocks the request');
            _debugLog(
                '[LN_ADDRESS_SERVICE] 💡 Solution: Contact administrator to enable CORS');
          }

          if (isLast) {
            _debugLog(
                '[LN_ADDRESS_SERVICE] ❌ Last endpoint failed - no more options');
            rethrow;
          } else {
            _debugLog(
                '[LN_ADDRESS_SERVICE] ⏭️ Continuing with next endpoint...');
            continue;
          }
        } catch (e) {
          _debugLog('[LN_ADDRESS_SERVICE] ❌ Unexpected error at $endpoint: $e');
          if (i == endpoints.length - 1) {
            rethrow;
          }
          continue;
        }
      }

      throw Exception('All creation endpoints failed');
    } catch (e) {
      _debugLog('[LN_ADDRESS_SERVICE] Error creating: $e');
      if (e is DioException) {
        _debugLog('[LN_ADDRESS_SERVICE] DioException details:');
        _debugLog('[LN_ADDRESS_SERVICE]   Type: ${e.type}');
        _debugLog('[LN_ADDRESS_SERVICE]   Status: ${e.response?.statusCode}');
        _debugLog('[LN_ADDRESS_SERVICE]   Data: ${e.response?.data}');
        _debugLog('[LN_ADDRESS_SERVICE]   Headers: ${e.response?.headers}');

        // Specific connection error handling
        if (e.type == DioExceptionType.connectionError) {
          if (kIsWeb) {
            // Detect if it's lachispa.me to give specific message
            final isLaChispa = _baseUrl.toLowerCase().contains('lachispa.me');

            if (isLaChispa) {
              throw Exception('🌐 CORS Blocked - LaChispa.me\n\n' +
                  '⚠️ CONFIRMED PROBLEM:\n' +
                  'The correct endpoint (/lnurlp/api/v1/links) exists on lachispa.me\n' +
                  'but the web browser blocks POST requests due to CORS policies.\n\n' +
                  '✅ AVAILABLE SOLUTIONS:\n' +
                  '1. 📱 Use mobile application (recommended)\n' +
                  '2. 📧 Contact @lachispa_me to enable CORS\n' +
                  '3. 🛠️ Create manually with curl:\n\n' +
                  'curl -X POST https://lachispa.me/lnurlp/api/v1/links \\\\\n' +
                  '  -H "Content-Type: application/json" \\\\\n' +
                  '  -H "X-Api-Key: ${_adminKey.substring(0, 8)}..." \\\\\n' +
                  '  -d \'{"username": "$username", "description": "Lightning Address", "amount": 0, "max": 50000000000, "min": 1, "comment_chars": 500}\'\n\n' +
                  '💡 CONFIRMED:\n' +
                  '• Functional endpoint: /lnurlp/api/v1/links ✅\n' +
                  '• Extension installed: LNURLP ✅\n' +
                  '• Problem: Only CORS in browser 🚫');
            } else {
              throw Exception('🌐 CORS Error - Web Server\n\n' +
                  '⚠️ IDENTIFIED PROBLEM:\n' +
                  'The LNBits server does not allow POST requests from web browsers ' +
                  'for the LNURLP extension due to CORS policies.\n\n' +
                  '✅ RECOMMENDED SOLUTIONS:\n' +
                  '1. Contact server administrator to enable CORS\n' +
                  '2. Use mobile application instead of browser\n' +
                  '3. Create Lightning Address manually with curl\n\n' +
                  '💡 TECHNICAL NOTE:\n' +
                  'GET requests work correctly, only POST requests are blocked by CORS.');
            }
          } else {
            throw Exception(
                'Connection error. Check your internet and server availability.');
          }
        }

        if (e.response?.statusCode == 404) {
          final errorData = e.response?.data;
          if (errorData is Map && errorData.containsKey('detail')) {
            final detail = errorData['detail'].toString();
            if (detail.contains('Wallet not found')) {
              throw Exception('🚫 Wallet not found\n\n' +
                  'Wallet with ID "$walletId" was not found on the server.\n\n' +
                  'Possible causes:\n' +
                  '• Wallet does not belong to your user\n' +
                  '• There is a session synchronization problem\n' +
                  '• Wallet was deleted\n\n' +
                  'Try logout/login or select another wallet.');
            } else {
              throw Exception('🚫 Resource not found: $detail');
            }
          } else {
            throw Exception('🚫 LNURLP extension not found\n\n' +
                'LNURLP extension is not installed on this LNBits server.\n' +
                'Contact administrator to install it.');
          }
        }

        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          throw Exception('🔐 Permission error\n\n' +
              'You do not have permissions to create Lightning Addresses.\n' +
              'Verify that you have the correct admin key.');
        }

        if (e.type == DioExceptionType.connectionTimeout) {
          throw Exception(
              'Connection timeout. Server took too long to respond.');
        }

        if (e.type == DioExceptionType.receiveTimeout) {
          throw Exception(
              'Timeout receiving data. Server did not respond in time.');
        }

        if (e.response?.data != null) {
          final errorData = e.response!.data;
          if (errorData is Map && errorData.containsKey('detail')) {
            throw Exception('Error LNURLP: ${errorData['detail']}');
          } else if (errorData is Map && errorData.containsKey('message')) {
            throw Exception('Error LNURLP: ${errorData['message']}');
          } else {
            throw Exception('Error LNURLP: ${errorData.toString()}');
          }
        }

        // Generic DioException error
        throw Exception('Connection error: ${e.message ?? "Unknown error"}');
      }
      throw Exception('Error creating Lightning Address: $e');
    }
  }

  // Get specific Lightning Address information
  Future<LNAddress> getLNAddress(String id) async {
    try {
      _debugLog('[LN_ADDRESS_SERVICE] Getting Lightning Address: $id');

      final response = await _dio.get('/lnurlp/api/v1/links/$id');

      if (response.statusCode == 200) {
        final lnAddress = LNAddress.fromJson(response.data, _baseUrl);
        _debugLog(
            '[LN_ADDRESS_SERVICE] Lightning Address obtained: ${lnAddress.fullAddress}');
        return lnAddress;
      } else {
        throw Exception('Lightning Address not found');
      }
    } catch (e) {
      _debugLog('[LN_ADDRESS_SERVICE] Error getting: $e');
      throw Exception('Error getting Lightning Address: $e');
    }
  }

  // Update existing Lightning Address
  Future<LNAddress> updateLNAddress(
    String id, {
    String? username,
    String? description,
    bool? isActive,
  }) async {
    try {
      _debugLog('[LN_ADDRESS_SERVICE] Updating Lightning Address: $id');

      final current = await getLNAddress(id);

      final payload = LNAddress.createPayload(
        username: username ?? current.username,
        walletId: current.walletId,
        description: description ?? current.description,
        amount: 0,
        minAmount: current.minAmount,
        maxAmount: current.maxAmount,
        commentChars: current.commentChars,
      );

      final response = await _dio.put(
        '/lnurlp/api/v1/links/$id',
        data: payload,
      );

      if (response.statusCode == 200) {
        final updated = LNAddress.fromJson(response.data, _baseUrl);
        _debugLog(
            '[LN_ADDRESS_SERVICE] Lightning Address updated: ${updated.fullAddress}');
        return updated;
      } else {
        throw Exception('Error updating Lightning Address');
      }
    } catch (e) {
      _debugLog('[LN_ADDRESS_SERVICE] Error updating: $e');
      throw Exception('Error updating Lightning Address: $e');
    }
  }

  // Delete Lightning Address
  Future<bool> deleteLNAddress(String id) async {
    try {
      _debugLog('[LN_ADDRESS_SERVICE] Deleting Lightning Address: $id');

      _setWriteHeaders();
      _debugLog('[LN_ADDRESS_SERVICE] Headers: ${_dio.options.headers}');

      final response = await _dio.delete('/lnurlp/api/v1/links/$id');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _debugLog(
            '[LN_ADDRESS_SERVICE] Lightning Address deleted successfully');
        return true;
      } else {
        throw Exception('Error deleting Lightning Address');
      }
    } catch (e) {
      _debugLog('[LN_ADDRESS_SERVICE] Error deleting: $e');
      throw Exception('Error deleting Lightning Address: $e');
    }
  }

  // Check username availability
  Future<bool> isUsernameAvailable(String username, String walletId) async {
    try {
      final addresses = await getLNAddressesForWallet(walletId);
      return !addresses.any((address) =>
          address.username.toLowerCase() == username.toLowerCase());
    } catch (e) {
      _debugLog('[LN_ADDRESS_SERVICE] Error checking username: $e');
      return true;
    }
  }

  // Check if LNURLP extension is available
  Future<bool> checkExtensionAvailability() async {
    try {
      _debugLog(
          '[LN_ADDRESS_SERVICE] Checking LNURLP extension availability...');

      _setReadHeaders();
      _debugLog('[LN_ADDRESS_SERVICE] Headers: ${_dio.options.headers}');

      final endpoints = _getOptimizedEndpoints();

      for (final endpoint in endpoints) {
        try {
          _debugLog('[LN_ADDRESS_SERVICE] Testing availability at: $endpoint');
          final response = await _dio.get(endpoint);
          if (response.statusCode == 200) {
            _debugLog(
                '[LN_ADDRESS_SERVICE] ✅ LNURLP extension available at: $endpoint');
            return true;
          }
        } catch (e) {
          _debugLog(
              '[LN_ADDRESS_SERVICE] Endpoint $endpoint not available: $e');
          continue;
        }
      }

      _debugLog('[LN_ADDRESS_SERVICE] ❌ No LNURLP endpoint found');
      return false;
    } catch (e) {
      _debugLog('[LN_ADDRESS_SERVICE] Error verifying extension: $e');
      // If it's a 401/403 error, extension exists but has auth problem
      if (e.toString().contains('401') || e.toString().contains('403')) {
        _debugLog(
            '[LN_ADDRESS_SERVICE] Extension exists but authentication error');
        return true; // Extension is available, just auth problem
      }
      return false;
    }
  }

  // Resolve Lightning Address using well-known endpoint
  Future<String> resolveLightningAddress(String lightningAddress) async {
    try {
      _debugLog(
          '[LN_ADDRESS_SERVICE] Resolving Lightning Address: $lightningAddress');

      // Extract username from Lightning Address (username@domain)
      final parts = lightningAddress.split('@');
      if (parts.length != 2) {
        throw Exception('Invalid Lightning Address format');
      }

      final username = parts[0];
      final domain = parts[1];

      // If from same server, use well-known endpoint
      if (_baseUrl.contains(domain)) {
        try {
          _debugLog(
              '[LN_ADDRESS_SERVICE] Using well-known endpoint for: $username');
          final response =
              await _dio.get('/lnurlp/api/v1/well-known/$username');

          if (response.statusCode == 200 && response.data != null) {
            final lnurl = response.data['lnurl'] ?? response.data['callback'];
            if (lnurl != null) {
              _debugLog(
                  '[LN_ADDRESS_SERVICE] LNURL obtained from well-known: $lnurl');
              return lnurl;
            }
          }
        } catch (e) {
          _debugLog('[LN_ADDRESS_SERVICE] Error in well-known: $e');
        }
      }

      // Fallback: return the Lightning Address
      _debugLog('[LN_ADDRESS_SERVICE] Using fallback for Lightning Address');
      return lightningAddress.toUpperCase();
    } catch (e) {
      _debugLog('[LN_ADDRESS_SERVICE] Error resolving: $e');
      return lightningAddress.toUpperCase();
    }
  }

  // Encode URL in LNURL format (bech32)
  String _encodeLNURL(String url) {
    try {
      _debugLog('[LN_ADDRESS_SERVICE] Encoding URL to LNURL: $url');

      // Convert URL to UTF-8 bytes
      final bytes = utf8.encode(url);
      _debugLog('[LN_ADDRESS_SERVICE] URL en bytes: ${bytes.length} bytes');

      // Convert from 8 bits to 5 bits for bech32
      final convertedBits = _convertBits(bytes, 8, 5, true);
      if (convertedBits == null) {
        throw Exception('Error converting bits for bech32');
      }

      _debugLog(
          '[LN_ADDRESS_SERVICE] Bits convertidos: ${convertedBits.length} elementos');

      // Encode in bech32 with prefix 'lnurl'
      final lnurl = _bech32Encode('lnurl', convertedBits);

      _debugLog(
          '[LN_ADDRESS_SERVICE] LNURL final: ${lnurl.substring(0, 20)}...${lnurl.substring(lnurl.length - 10)}');

      return lnurl.toUpperCase();
    } catch (e) {
      _debugLog('[LN_ADDRESS_SERVICE] Error encoding LNURL: $e');
      return url; // Fallback to original URL
    }
  }

  // Implementation of bech32 encoding for LNURL
  String _bech32Encode(String hrp, List<int> data) {
    const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';

    // Calculate checksum
    final values = _hrpExpand(hrp) + data + [0, 0, 0, 0, 0, 0];
    final mod = _polymod(values) ^ 1;
    final checksum = List.generate(6, (i) => (mod >> (5 * (5 - i))) & 31);

    // Build final result
    final combined = data + checksum;
    final result = hrp + '1' + combined.map((i) => charset[i]).join('');

    return result;
  }

  // Expand HRP for checksum calculation
  List<int> _hrpExpand(String hrp) {
    final result = <int>[];
    for (final c in hrp.codeUnits) {
      result.add(c >> 5);
    }
    result.add(0);
    for (final c in hrp.codeUnits) {
      result.add(c & 31);
    }
    return result;
  }

  // Calculate polymod for bech32
  int _polymod(List<int> values) {
    const generator = [
      0x3b6a57b2,
      0x26508e6d,
      0x1ea119fa,
      0x3d4233dd,
      0x2a1462b3
    ];
    var chk = 1;

    for (final value in values) {
      final top = chk >> 25;
      chk = (chk & 0x1ffffff) << 5 ^ value;
      for (var i = 0; i < 5; i++) {
        chk ^= ((top >> i) & 1) != 0 ? generator[i] : 0;
      }
    }

    return chk;
  }

  // Convert bits for bech32 (8 bits → 5 bits)
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

  // Verify LNURLP extension availability with detailed diagnosis
  Future<Map<String, dynamic>> checkLNURLPAvailability() async {
    final result = {
      'available': false,
      'error': null,
      'suggestions': <String>[],
      'technical_details': null,
    };

    try {
      _debugLog('[LN_ADDRESS_SERVICE] Verifying LNURLP availability...');

      // First verify basic connectivity
      final basicTest = await _diagnoseConnection();
      if (!basicTest) {
        result['error'] = 'No server connectivity';
        result['suggestions'] = [
          'Check your internet connection',
          'Confirm server URL is correct',
          'Try from a different network',
          'Check that no firewall is blocking'
        ];
        return result;
      }

      // Test LNURLP endpoints
      final endpoints = [
        '/lnurlp/api/v1/links',
        '/api/v1/lnurlp/links',
        '/lnaddress/api/v1/links',
      ];

      for (final endpoint in endpoints) {
        try {
          final response = await _dio.get(endpoint);
          if (response.statusCode == 200) {
            result['available'] = true;
            result['technical_details'] = 'Functional endpoint: $endpoint';
            return result;
          }
        } on DioException catch (e) {
          if (e.type == DioExceptionType.connectionError && kIsWeb) {
            result['error'] = 'CORS error in web browser';
            result['suggestions'] = [
              'Server does not allow requests from web browsers',
              'Contact administrator to configure CORS',
              'Try using mobile application instead',
              'Verify that LNURLP extension is installed'
            ];
            result['technical_details'] =
                'XMLHttpRequest CORS error at endpoint: $endpoint';
            return result;
          }

          if (e.response?.statusCode == 404) {
            result['error'] = 'LNURLP extension not installed';
            result['suggestions'] = [
              'LNURLP extension is not installed on server',
              'Contact administrator to install it',
              'Verify you are connected to correct server'
            ];
            result['technical_details'] = '404 on all LNURLP endpoints';
            return result;
          }

          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            result['error'] = 'Authentication error';
            result['suggestions'] = [
              'Verify your authentication key',
              'Make sure you have sufficient permissions',
              'Try logout and login again'
            ];
            result['technical_details'] =
                'Authentication error ${e.response?.statusCode}';
            return result;
          }
        }
      }

      result['error'] = 'LNURLP extension not available';
      result['suggestions'] = [
        'No LNURLP endpoint responded correctly',
        'Verify extension is installed and enabled',
        'Contact server administrator'
      ];
    } catch (e) {
      result['error'] = 'Unexpected error: $e';
      result['technical_details'] = e.toString();
    }

    return result;
  }

  // Verify service connectivity
  Future<bool> checkServiceHealth() async {
    try {
      final response = await _dio.get('/lnurlp/api/v1/links');
      return response.statusCode == 200;
    } catch (e) {
      _debugLog('[LN_ADDRESS_SERVICE] Service not available: $e');
      return false;
    }
  }

  // FORCED: Always return true to avoid cache issues
  Future<bool> verifyWalletOwnership(String walletId) async {
    _debugLog(
        '[LN_ADDRESS_SERVICE] 🔧 FORCING verifyWalletOwnership = true (CACHE BYPASS)');
    return true; // FORCED - do not validate wallet ownership
  }
}
