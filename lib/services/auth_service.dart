import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/utils/proxy_config.dart';
import 'app_info_service.dart';

void _debugLog(String message) {
  if (kDebugMode) {
    print(message);
  }
}

class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  
  AuthService() 
    : _dio = Dio(),
      _storage = const FlutterSecureStorage() {
    _configureDio();
  }

  void _configureDio() {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['User-Agent'] = AppInfoService.getUserAgent();
    _dio.options.followRedirects = false;
    _dio.options.validateStatus = (status) {
      return status != null && status >= 200 && status < 400;
    };
    
    ProxyConfig.configureProxy(_dio, enableLogging: true);
    
    if (ProxyConfig.hasSystemProxy()) {
      _debugLog('[AUTH_SERVICE] System proxy detected - using automatic configuration');
    }
  }

  /// Login with traditional LNBits username and password
  Future<LoginResult> login({
    required String serverUrl,
    required String username, 
    required String password,
  }) async {
    try {
      String baseUrl = serverUrl;
      if (!baseUrl.startsWith('http')) {
        baseUrl = 'https://$baseUrl';
      }
      
      _debugLog('[AUTH_SERVICE] Starting login - Server: $baseUrl');
      _debugLog('[AUTH_SERVICE] User: $username');

      // Check server connectivity before attempting auth
      try {
        await _dio.get('$baseUrl/api/v1/wallets');
        _debugLog('[AUTH_SERVICE] LNBits server reachable');
      } on DioException catch (e) {
        _debugLog('[AUTH_SERVICE] Connectivity error: ${e.message}');
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          return LoginResult.error('Server unavailable. Check URL');
        }
      }

      // OAuth2 Password Bearer authentication endpoints
      final loginEndpoints = [
        '/api/v1/auth/login',           // Main OAuth2 endpoint
        '/api/v1/auth/usr',             // Alternative user endpoint
        '/api/v1/auth',                 // Base auth endpoint
        '/usermanager/api/v1/auth',     // User management endpoint
        '/auth/login',                  // Direct login endpoint
        '/login',                       // Web login endpoint
      ];

      for (String endpoint in loginEndpoints) {
        try {
          _debugLog('[AUTH_SERVICE] Trying endpoint: $baseUrl$endpoint');
          
          // Prepare auth data based on endpoint requirements
          Map<String, dynamic> authData;
          String contentType = 'application/json';
          
          if (endpoint.contains('/auth/usr')) {
            // /api/v1/auth/usr uses 'usr' instead of 'username'
            authData = {
              'usr': username,
              'password': password,
            };
          } else if (endpoint.contains('/auth/login')) {
            authData = {
              'username': username,
              'password': password,
              'grant_type': 'password',
            };
            contentType = 'application/x-www-form-urlencoded';
          } else if (endpoint.contains('/usermanager')) {
            authData = {
              'username': username,
              'password': password,
            };
          } else {
            authData = {
              'username': username,
              'password': password,
            };
          }
          
          dynamic requestData;
          if (contentType == 'application/x-www-form-urlencoded') {
            requestData = authData.entries
                .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
                .join('&');
          } else {
            requestData = authData;
          }
          
          final response = await _dio.post(
            '$baseUrl$endpoint',
            data: requestData,
            options: Options(
              headers: {
                'Content-Type': contentType,
              },
            ),
          );

          if (response.statusCode == 200 && response.data != null) {
            _debugLog('[AUTH_SERVICE] Login successful at $endpoint');
            return _processLoginResponse(response.data, baseUrl, username);
          }
        } on DioException catch (e) {
          _debugLog('[AUTH_SERVICE] Error at $endpoint: ${e.response?.statusCode}');
          
          if (e.response?.statusCode == 401) {
            _debugLog('[AUTH_SERVICE] Invalid credentials');
          } else if (e.response?.statusCode == 403) {
            _debugLog('[AUTH_SERVICE] Access denied');
          } else if (e.response?.statusCode == 404) {
            _debugLog('[AUTH_SERVICE] Endpoint not found');
          }
          
          continue;
        }
      }

      return LoginResult.error('Invalid username or password');

    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return LoginResult.error('Unexpected error: ${e.toString()}');
    }
  }

  LoginResult _processLoginResponse(dynamic data, String serverUrl, String username) {
    try {
      _debugLog('[AUTH_SERVICE] Processing login response');
      
      String? accessToken;
      String? userId;
      
      if (data is Map<String, dynamic>) {
        // Search for token in possible fields (priority order for LNBits)
        accessToken = data['admin_key'] ??
                     data['adminkey'] ??
                     data['access_token'] ?? 
                     data['token'] ?? 
                     data['api_key'] ??
                     data['key'] ??
                     data['invoice_key'];
        
        userId = data['user_id'] ?? 
                data['id'] ?? 
                data['usr'] ??
                data['wallet_id'];
      }

      if (accessToken != null && accessToken.isNotEmpty) {
        return LoginResult.success(
          token: accessToken,
          userId: userId ?? username,
          serverUrl: serverUrl,
          username: username,
        );
      }

      // Fallback: create basic session if server responds but no token
      if (data != null) {
        return LoginResult.success(
          token: 'session_${DateTime.now().millisecondsSinceEpoch}',
          userId: username,
          serverUrl: serverUrl,
          username: username,
        );
      }

      return LoginResult.error('Invalid server response');

    } catch (e) {
      return LoginResult.error('Error processing server response');
    }
  }

  LoginResult _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return LoginResult.error('Connection timeout');
      
      case DioExceptionType.connectionError:
        return LoginResult.error('Connection error. Check server');
      
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return LoginResult.error('Invalid username or password');
        } else if (statusCode == 404) {
          return LoginResult.error('Server not found');
        } else {
          return LoginResult.error('Server error ($statusCode)');
        }
      
      case DioExceptionType.cancel:
        return LoginResult.error('Operation cancelled');
      
      default:
        return LoginResult.error('Connection error: ${e.message}');
    }
  }

  Future<void> saveSession({
    required String token,
    required String userId,
    required String serverUrl,
    required String username,
  }) async {
    final now = DateTime.now();
    final expiryTime = now.add(const Duration(days: 5));
    
    await Future.wait([
      _storage.write(key: 'auth_token', value: token),
      _storage.write(key: 'user_id', value: userId),
      _storage.write(key: 'server_url', value: serverUrl),
      _storage.write(key: 'username', value: username),
      _storage.write(key: 'login_time', value: now.toIso8601String()),
      _storage.write(key: 'session_expires', value: expiryTime.toIso8601String()),
    ]);
    
    _debugLog('[AUTH_SERVICE] Session saved with 5-day expiry: ${expiryTime.toIso8601String()}');
  }

  /// Get session data with optimized parallel reads and expiry check
  Future<SessionData?> getSession() async {
    try {
      // Check token first for early return
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return null;

      // Read all remaining values in parallel
      final results = await Future.wait([
        _storage.read(key: 'user_id'),
        _storage.read(key: 'server_url'),
        _storage.read(key: 'username'),
        _storage.read(key: 'login_time'),
        _storage.read(key: 'session_expires'),
      ]);

      // Check if session has expired locally
      if (results[4] != null) {
        final expiryTime = DateTime.parse(results[4]!);
        if (DateTime.now().isAfter(expiryTime)) {
          _debugLog('[AUTH_SERVICE] Session expired locally, clearing storage');
          await logout();
          return null;
        }
      }

      return SessionData(
        token: token,
        userId: results[0] ?? '',
        serverUrl: results[1] ?? '',
        username: results[2] ?? '',
        loginTime: results[3] != null ? DateTime.parse(results[3]!) : DateTime.now(),
      );
    } catch (e) {
      _debugLog('[AUTH_SERVICE] Error getting session: $e');
      return null;
    }
  }

  /// Create new user account in LNBits
  Future<LoginResult> signup({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    try {
      String baseUrl = serverUrl;
      if (!baseUrl.startsWith('http')) {
        baseUrl = 'https://$baseUrl';
      }
      
      _debugLog('[AUTH_SERVICE] Starting signup - Server: $baseUrl');
      _debugLog('[AUTH_SERVICE] User: $username');

      try {
        await _dio.get('$baseUrl/api/v1/wallets');
        _debugLog('[AUTH_SERVICE] LNBits server reachable');
      } on DioException catch (e) {
        _debugLog('[AUTH_SERVICE] Connectivity error: ${e.message}');
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          return LoginResult.error('Server unavailable. Check URL');
        }
      }

      // Try multiple signup methods
      return await _trySignupMethods(baseUrl, username, password, serverUrl);

    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return LoginResult.error('Unexpected error: ${e.toString()}');
    }
  }

  /// Try user creation with multiple endpoint fallbacks
  Future<LoginResult> _trySignupMethods(
    String baseUrl, 
    String username, 
    String password,
    String serverUrl,
  ) async {
    _debugLog('[AUTH_SERVICE] Creating user with username and password...');
    
    // Possible endpoints for user creation
    final endpoints = [
      {
        'url': '$baseUrl/api/v1/auth/register',
        'data': {'username': username, 'password': password, 'password_repeat': password},
        'name': 'Auth Register'
      },
      {
        'url': '$baseUrl/api/v1/auth/signup',
        'data': {'username': username, 'password': password},
        'name': 'Auth Signup'
      },
      {
        'url': '$baseUrl/usermanager/api/v1/users',
        'data': {'username': username, 'password': password},
        'name': 'User Manager'
      },
      {
        'url': '$baseUrl/api/v1/auth/usr',
        'data': {'usr': username, 'password': password, 'wallet_name': username},
        'name': 'Auth USR'
      },
      {
        'url': '$baseUrl/api/v1/users',
        'data': {'username': username, 'password': password},
        'name': 'Users API'
      },
    ];
    
    String? lastError;
    
    for (int i = 0; i < endpoints.length; i++) {
      final endpoint = endpoints[i];
      
      try {
        _debugLog('[AUTH_SERVICE] Trying method ${i + 1}: ${endpoint['name']}');
        _debugLog('[AUTH_SERVICE] URL: ${endpoint['url']}');
        
        final response = await _dio.post(
          endpoint['url'] as String,
          data: endpoint['data'],
          options: Options(
            contentType: 'application/json',
          ),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          _debugLog('[AUTH_SERVICE] User created successfully with ${endpoint['name']}: ${response.statusCode}');
          _debugLog('[AUTH_SERVICE] Response: ${response.data}');
          return _processSignupResponse(response.data, serverUrl, username);
        } else {
          _debugLog('[AUTH_SERVICE] ${endpoint['name']} - Unexpected status: ${response.statusCode}');
          lastError = 'Error creating user: status ${response.statusCode}';
        }
        
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        _debugLog('[AUTH_SERVICE] ${endpoint['name']} failed: $statusCode');
        _debugLog('[AUTH_SERVICE] Response: $responseData');
        
        if (statusCode == 400) {
          lastError = 'User already exists or invalid data';
        } else if (statusCode == 403) {
          lastError = 'Account creation disabled on server';
        } else if (statusCode == 401) {
          lastError = 'Not authorized to create user';
        } else if (statusCode == 404) {
          lastError = 'Endpoint not found';
        } else if (statusCode == 405) {
          lastError = 'Method not allowed';
        } else if (statusCode == 422) {
          lastError = 'Invalid user data';
        } else {
          lastError = 'Server error ($statusCode)';
        }
        
        continue;
        
      } catch (e) {
        _debugLog('[AUTH_SERVICE] ${endpoint['name']} unexpected error: $e');
        lastError = 'Unexpected error: ${e.toString()}';
        continue;
      }
    }
    
    _debugLog('[AUTH_SERVICE] All signup endpoints failed');
    return LoginResult.error(lastError ?? 'Could not create account. Server does not allow public registration.');
  }

  LoginResult _processSignupResponse(dynamic data, String serverUrl, String username) {
    try {
      _debugLog('[AUTH_SERVICE] Processing signup response');
      
      String? accessToken;
      String? userId;
      
      if (data is Map<String, dynamic>) {
        // Search for token in possible fields (priority order for LNBits)
        accessToken = data['admin_key'] ??
                     data['adminkey'] ??
                     data['access_token'] ?? 
                     data['token'] ?? 
                     data['api_key'] ??
                     data['key'] ??
                     data['invoice_key'];
        
        userId = data['id'] ?? 
                data['user_id'] ?? 
                data['usr'] ??
                data['wallet_id'];
      }

      if (accessToken != null && accessToken.isNotEmpty) {
        return LoginResult.success(
          token: accessToken,
          userId: userId ?? username,
          serverUrl: serverUrl,
          username: username,
        );
      }

      // Fallback: create basic session for new user
      if (data != null) {
        return LoginResult.success(
          token: 'new_user_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId ?? username,
          serverUrl: serverUrl,
          username: username,
        );
      }

      return LoginResult.error('Invalid server response');

    } catch (e) {
      return LoginResult.error('Error processing server response');
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    try {
      final session = await getSession();
      return session != null;
    } catch (e) {
      return false;
    }
  }

  /// Validate session token with server
  /// Returns true if valid, false if explicitly rejected (401/422), null if unreachable
  Future<bool?> validateSession(String token, String serverUrl) async {
    try {
      String baseUrl = serverUrl;
      if (!baseUrl.startsWith('http')) {
        baseUrl = 'https://$baseUrl';
      }

      _debugLog('[AUTH_SERVICE] Validating session with server: $baseUrl');

      final response = await _dio.get(
        '$baseUrl/api/v1/auth',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-API-KEY': token,
          },
        ),
      );

      final isValid = response.statusCode == 200;
      _debugLog('[AUTH_SERVICE] Session validation result: $isValid');
      return isValid;

    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 422) {
          _debugLog('[AUTH_SERVICE] Session rejected by server: $statusCode');
          return false;
        }
      }
      _debugLog('[AUTH_SERVICE] Session validation unreachable: ${e.type} - ${e.message}');
      return null;
    } catch (e) {
      _debugLog('[AUTH_SERVICE] Session validation unknown error: $e');
      return null;
    }
  }
}

class LoginResult {
  final bool isSuccess;
  final String? token;
  final String? userId;
  final String? serverUrl;
  final String? username;
  final String? error;

  LoginResult._({
    required this.isSuccess,
    this.token,
    this.userId,
    this.serverUrl,
    this.username,
    this.error,
  });

  factory LoginResult.success({
    required String token,
    required String userId,
    required String serverUrl,
    required String username,
  }) {
    return LoginResult._(
      isSuccess: true,
      token: token,
      userId: userId,
      serverUrl: serverUrl,
      username: username,
    );
  }

  factory LoginResult.error(String error) {
    return LoginResult._(
      isSuccess: false,
      error: error,
    );
  }
}

class SessionData {
  final String token;
  final String userId;
  final String serverUrl;
  final String username;
  final DateTime loginTime;

  SessionData({
    required this.token,
    required this.userId,
    required this.serverUrl,
    required this.username,
    required this.loginTime,
  });
}