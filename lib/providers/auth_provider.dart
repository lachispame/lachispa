import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/server_provider.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  
  AuthProvider(this._authService);

  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;
  SessionData? _sessionData;
  
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  SessionData? get sessionData => _sessionData;
  String? get currentUser => _sessionData?.username;
  String? get currentServer => _sessionData?.serverUrl;
  
  /// Initialize provider and restore existing session from secure storage
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final session = await _authService.getSession();
      if (session != null) {
        print('[AUTH_PROVIDER] Session found, validating with server...');
        
        // Validate session with server
        // Returns: true = valid, false = rejected (401/422), null = unreachable
        final validationResult = await _authService.validateSession(
          session.token,
          session.serverUrl
        );

        if (validationResult == false) {
          // Server explicitly rejected the token — clear session
          print('[AUTH_PROVIDER] Session rejected by server, clearing local session ❌');
          await _authService.logout();
          _sessionData = null;
          _isLoggedIn = false;
        } else {
          // true = validated, null = network unreachable — keep session
          _sessionData = session;
          _isLoggedIn = true;
          if (validationResult == null) {
            print('[AUTH_PROVIDER] Server unreachable, keeping local session for ${session.username} ⚠️');
          } else {
            print('[AUTH_PROVIDER] Session restored and validated for ${session.username} ✅');
          }
        }
      } else {
        print('[AUTH_PROVIDER] No session found in storage');
      }
    } catch (e) {
      print('[AUTH_PROVIDER] Error initializing: $e');
      _errorMessage = 'Error initializing session';
      // Clear potentially corrupted session
      await _authService.logout();
      _sessionData = null;
      _isLoggedIn = false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Authenticate user and establish session with server fallback support
  Future<bool> login({
    required String username,
    required String password,
    required String serverUrl,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      print('[AUTH_PROVIDER] Starting login for $username');
      
      final result = await _authService.login(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      
      if (result.isSuccess) {
        await _authService.saveSession(
          token: result.token!,
          userId: result.userId!,
          serverUrl: result.serverUrl!,
          username: result.username!,
        );
        
        _sessionData = SessionData(
          token: result.token!,
          userId: result.userId!,
          serverUrl: result.serverUrl!,
          username: result.username!,
          loginTime: DateTime.now(),
        );
        
        _isLoggedIn = true;
        print('[AUTH_PROVIDER] Successful login for $username');
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.error ?? 'Unknown error';
        print('[AUTH_PROVIDER] Login failed: ${_errorMessage}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Unexpected error: ${e.toString()}';
      print('[AUTH_PROVIDER] Login error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Logout and clear all session data
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _authService.logout();
      _sessionData = null;
      _isLoggedIn = false;
      _clearError();
      print('[AUTH_PROVIDER] Successful logout');
    } catch (e) {
      print('[AUTH_PROVIDER] Logout error: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Check if session is still valid and handle expiration
  Future<bool> checkSession() async {
    try {
      final isActive = await _authService.isLoggedIn();
      if (!isActive && _isLoggedIn) {
        _sessionData = null;
        _isLoggedIn = false;
        notifyListeners();
      }
      return isActive;
    } catch (e) {
      print('[AUTH_PROVIDER] Error checking session: $e');
      return false;
    }
  }
  
  /// Create new user account with automatic session establishment
  Future<bool> signup({
    required String username,
    required String password,
    required String serverUrl,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      print('[AUTH_PROVIDER] Starting signup for $username');
      
      final result = await _authService.signup(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      
      if (result.isSuccess) {
        await _authService.saveSession(
          token: result.token!,
          userId: result.userId!,
          serverUrl: result.serverUrl!,
          username: result.username!,
        );
        
        _sessionData = SessionData(
          token: result.token!,
          userId: result.userId!,
          serverUrl: result.serverUrl!,
          username: result.username!,
          loginTime: DateTime.now(),
        );
        
        _isLoggedIn = true;
        print('[AUTH_PROVIDER] Successful signup for $username');
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.error ?? 'Unknown error';
        print('[AUTH_PROVIDER] Signup failed: ${_errorMessage}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Unexpected error: ${e.toString()}';
      print('[AUTH_PROVIDER] Signup error: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get friendly display name for current server using ServerProvider
  String getServerDisplayName(BuildContext context) {
    if (_sessionData?.serverUrl == null) return 'Not connected';
    
    try {
      final serverProvider = Provider.of<ServerProvider>(context, listen: false);
      return serverProvider.getServerDisplayName(_sessionData!.serverUrl);
    } catch (e) {
      return _sessionData!.serverUrl;
    }
  }
  
  /// Clear current error state
  void clearError() {
    _clearError();
    notifyListeners();
  }
  
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  void _clearError() {
    _errorMessage = null;
  }
}

/// Factory for creating AuthProvider with proper dependency injection
class AuthProviderFactory {
  static AuthProvider create() {
    return AuthProvider(AuthService());
  }
}