import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

enum ServerHealth { checking, healthy, unhealthy }

class ServerProvider with ChangeNotifier {
  String _selectedServer = 'https://lachispa.me';
  String _customServerUrl = '';
  bool _isLoading = false;
  String? _errorMessage;
  ServerHealth _serverHealth = ServerHealth.checking;

  static const Map<String, String> _defaultServers = {
    'LaChispa': 'https://lachispa.me',
  };

  String get selectedServer => _selectedServer;
  String get customServerUrl => _customServerUrl;
  String get currentServerUrl => _selectedServer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, String> get defaultServers => _defaultServers;
  ServerHealth get serverHealth => _serverHealth;

  Future<void> checkHealth() async {
    _serverHealth = ServerHealth.checking;
    notifyListeners();
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
        validateStatus: (_) => true,
      ));
      final resp = await dio.get('$_selectedServer/api/v1/health');
      _serverHealth = (resp.statusCode == 200)
          ? ServerHealth.healthy
          : ServerHealth.unhealthy;
    } catch (_) {
      _serverHealth = ServerHealth.unhealthy;
    }
    notifyListeners();
  }

  String get serverDisplayName {
    return _getServerDisplayName(_selectedServer);
  }
  
  String getServerDisplayName(String serverUrl) {
    return _getServerDisplayName(serverUrl);
  }
  
  String _getServerDisplayName(String serverUrl) {
    for (String name in _defaultServers.keys) {
      if (_defaultServers[name] == serverUrl) {
        return name;
      }
    }
    return serverUrl;
  }

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedServer = prefs.getString('selected_server') ?? 'https://lachispa.me';
      _customServerUrl = prefs.getString('custom_server_url') ?? '';
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading server configuration';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectServer(String serverUrl) async {
    if (serverUrl == _selectedServer) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String normalizedUrl = serverUrl.trim();
      
      if (!normalizedUrl.startsWith('http://') && !normalizedUrl.startsWith('https://')) {
        normalizedUrl = 'https://$normalizedUrl';
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_server', normalizedUrl);
      
      if (!_defaultServers.containsValue(normalizedUrl)) {
        await prefs.setString('custom_server_url', normalizedUrl);
      }
      
      _selectedServer = normalizedUrl;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error saving selected server';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void setCustomServerUrl(String url) {
    _customServerUrl = url;
    notifyListeners();
  }

  Future<void> applyCustomServer() async {
    if (_customServerUrl.isEmpty) {
      _errorMessage = 'Server URL cannot be empty';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_customServerUrl.startsWith('http://') && !_customServerUrl.startsWith('https://')) {
        _customServerUrl = 'https://$_customServerUrl';
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_server', _customServerUrl);
      await prefs.setString('custom_server_url', _customServerUrl);
      
      _selectedServer = _customServerUrl;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error configuring custom server';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> resetToDefault() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_server');
      await prefs.remove('custom_server_url');
      
      _selectedServer = 'https://lachispa.me';
      _customServerUrl = '';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error resetting configuration';
      _isLoading = false;
      notifyListeners();
    }
  }
}