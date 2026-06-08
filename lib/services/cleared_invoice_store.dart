import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ClearedInvoiceStore {
  static final ClearedInvoiceStore _instance = ClearedInvoiceStore._();
  static ClearedInvoiceStore get instance => _instance;
  ClearedInvoiceStore._();

  static const String _storageKey = 'cleared_invoice_hashes';
  Set<String> _hashes = {};

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      if (stored != null && stored.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(stored);
        _hashes = decoded.cast<String>().toSet();
      }
    } catch (_) {
      _hashes = {};
    }
  }

  Future<void> add(String hash) async {
    _hashes.add(hash);
    await _persist();
  }

  bool contains(String? hash) => hash != null && _hashes.contains(hash);

  Set<String> get all => Set.unmodifiable(_hashes);

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_hashes.toList()));
    } catch (_) {}
  }
}
