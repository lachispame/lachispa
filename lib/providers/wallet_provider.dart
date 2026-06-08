import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/wallet_service.dart';
import '../models/wallet_info.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService;

  List<WalletInfo> _wallets = [];
  WalletInfo? _primaryWallet;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  /// Callback to notify wallet changes to other providers
  Function(String walletId)? _onWalletChanged;

  WalletProvider(this._walletService);

  void setOnWalletChangedCallback(Function(String walletId) callback) {
    _onWalletChanged = callback;
  }

  /// Generate unique preference key for user+server combination
  String _getPreferredWalletKey(String serverUrl, String username) {
    return 'preferred_wallet_${serverUrl}_$username';
  }

  /// Save preferred wallet for user+server combination
  Future<void> _savePreferredWallet(
      String serverUrl, String username, String walletId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getPreferredWalletKey(serverUrl, username);
      await prefs.setString(key, walletId);
      print(
          '[WALLET_PROVIDER] Preferred wallet saved: $walletId for $username@$serverUrl');
    } catch (e) {
      print('[WALLET_PROVIDER] Error saving preferred wallet: $e');
    }
  }

  /// Get preferred wallet for user+server combination
  Future<String?> _getPreferredWallet(String serverUrl, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getPreferredWalletKey(serverUrl, username);
      final walletId = prefs.getString(key);
      print(
          '[WALLET_PROVIDER] Preferred wallet retrieved: $walletId for $username@$serverUrl');
      return walletId;
    } catch (e) {
      print('[WALLET_PROVIDER] Error getting preferred wallet: $e');
      return null;
    }
  }

  List<WalletInfo> get wallets => _wallets;
  WalletInfo? get primaryWallet => _primaryWallet;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get hasWallets => _wallets.isNotEmpty;

  int get primaryBalance => _primaryWallet?.balanceSats ?? 0;
  String get primaryBalanceFormatted =>
      _primaryWallet?.balanceFormatted ?? '0 sats';
  String? get primaryWalletId => _primaryWallet?.id;

  /// Initialize user wallets with saved preference restoration
  Future<void> initializeWallets({
    required String serverUrl,
    required String authToken,
    String? username,
  }) async {
    if (_isInitialized) return;

    _setLoading(true);
    _error = null;

    try {
      print('[WALLET_PROVIDER] Initializing wallets...');

      final wallets = await _walletService
          .getUserWallets(
        serverUrl: serverUrl,
        authToken: authToken,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw WalletException(
              'Timeout getting wallets - check your connection');
        },
      );

      _wallets = wallets;

      if (wallets.isNotEmpty) {
        await _establishPrimaryWallet(serverUrl, username, wallets);
      } else {
        print('[WALLET_PROVIDER] ⚠️ User has no wallets');
      }

      _isInitialized = true;
      print('[WALLET_PROVIDER] ${wallets.length} wallets initialized');
    } catch (e) {
      _error = e.toString().replaceFirst('WalletException: ', '');
      print('[WALLET_PROVIDER] Error initializing wallets: $_error');
      _isInitialized = true;
    } finally {
      _setLoading(false);
    }
  }

  /// Establish primary wallet based on saved preferences or fallback to first
  Future<void> _establishPrimaryWallet(
      String serverUrl, String? username, List<WalletInfo> wallets) async {
    WalletInfo? selectedWallet;

    if (username != null) {
      final preferredWalletId = await _getPreferredWallet(serverUrl, username);
      if (preferredWalletId != null) {
        selectedWallet =
            wallets.where((w) => w.id == preferredWalletId).firstOrNull;
        if (selectedWallet != null) {
          print(
              '[WALLET_PROVIDER] Using preferred wallet: ${selectedWallet.name}');
        } else {
          print('[WALLET_PROVIDER] Preferred wallet not found, using first');
        }
      }
    }

    selectedWallet ??= wallets.first;

    _primaryWallet = selectedWallet;
    print(
        '[WALLET_PROVIDER] Primary wallet established: ${_primaryWallet!.name}');
    print('[WALLET_PROVIDER] Balance: ${_primaryWallet!.balanceFormatted}');
  }

  /// Refresh primary wallet balance and update state
  Future<void> refreshPrimaryBalance({
    required String serverUrl,
  }) async {
    if (_primaryWallet == null) {
      print('[WALLET_PROVIDER] No primary wallet to update');
      return;
    }

    try {
      print('[WALLET_PROVIDER] Refreshing balance...');

      final balance = await _walletService.getWalletBalance(
        serverUrl: serverUrl,
        walletId: _primaryWallet!.id,
        adminKey: _primaryWallet!.adminKey,
      );

      final updatedWallet = WalletInfo(
        id: _primaryWallet!.id,
        name: _primaryWallet!.name,
        adminKey: _primaryWallet!.adminKey,
        inKey: _primaryWallet!.inKey,
        readKey: _primaryWallet!.readKey,
        balanceMsat: balance.balanceMsat,
      );

      _primaryWallet = updatedWallet;

      final index = _wallets.indexWhere((w) => w.id == _primaryWallet!.id);
      if (index != -1) {
        _wallets[index] = updatedWallet;
      }

      notifyListeners();
      print('[WALLET_PROVIDER] Balance updated: ${balance.balanceFormatted}');
    } catch (e) {
      _error =
          'Error refreshing balance: ${e.toString().replaceFirst('WalletException: ', '')}';
      print('[WALLET_PROVIDER] Error refreshing balance: $_error');
      notifyListeners();
    }
  }

  /// Change primary wallet and notify LNAddressProvider of wallet change
  Future<void> setPrimaryWallet(WalletInfo wallet,
      {String? serverUrl, String? username}) async {
    if (_wallets.contains(wallet)) {
      final previousWalletId = _primaryWallet?.id;
      _primaryWallet = wallet;
      print('[WALLET_PROVIDER] Primary wallet changed to: ${wallet.name}');

      if (serverUrl != null && username != null) {
        await _savePreferredWallet(serverUrl, username, wallet.id);
      }

      if (previousWalletId != wallet.id) {
        _onWalletChanged?.call(wallet.id);
      }

      notifyListeners();
    }
  }

  /// Create new wallet and add to list
  Future<bool> createWallet({
    required String serverUrl,
    required String authToken,
    required String walletName,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      print('[WALLET_PROVIDER] Creating new wallet: $walletName');

      final newWallet = await _walletService.createWallet(
        serverUrl: serverUrl,
        authToken: authToken,
        walletName: walletName,
      );

      _wallets.add(newWallet);

      if (_wallets.length == 1) {
        _primaryWallet = newWallet;
      }

      notifyListeners();
      print('[WALLET_PROVIDER] Wallet created successfully: ${newWallet.name}');
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('WalletException: ', '');
      print('[WALLET_PROVIDER] Error creating wallet: $_error');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete wallet with primary wallet reassignment if needed
  Future<bool> deleteWallet({
    required String serverUrl,
    required WalletInfo wallet,
  }) async {
    if (_wallets.length <= 1) {
      _error = 'Cannot delete the only wallet';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      print('[WALLET_PROVIDER] Deleting wallet: ${wallet.name}');

      await _walletService.deleteWallet(
        serverUrl: serverUrl,
        walletId: wallet.id,
        adminKey: wallet.adminKey,
      );

      _wallets.removeWhere((w) => w.id == wallet.id);

      if (_primaryWallet?.id == wallet.id && _wallets.isNotEmpty) {
        _primaryWallet = _wallets.first;
        print('[WALLET_PROVIDER] New primary wallet: ${_primaryWallet!.name}');
      }

      notifyListeners();
      print('[WALLET_PROVIDER] Wallet deleted successfully');
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('WalletException: ', '');
      print('[WALLET_PROVIDER] Error deleting wallet: $_error');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clear current error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset provider state on logout
  void reset() {
    _wallets.clear();
    _primaryWallet = null;
    _isLoading = false;
    _isInitialized = false;
    _error = null;
    notifyListeners();
    print('[WALLET_PROVIDER] Provider reset');
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Debug information
  @override
  String toString() {
    return 'WalletProvider('
        'wallets: ${_wallets.length}, '
        'primary: ${_primaryWallet?.name}, '
        'isLoading: $_isLoading, '
        'isInitialized: $_isInitialized'
        ')';
  }
}
