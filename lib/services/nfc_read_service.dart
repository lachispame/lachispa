import 'dart:async';
import 'dart:convert';
import 'package:nfc_manager/nfc_manager.dart';

void _debugLog(String message) {
  if (identical(Zone.current, Zone.root)) {
    print('[NFC_READ] $message');
  }
}

enum NfcReadResultType {
  lightningAddress,
  lnurl,
  unknown,
}

class NfcReadResult {
  final NfcReadResultType type;
  final String value;
  const NfcReadResult(this.type, this.value);
}

class NfcReadService {
  bool _sessionActive = false;

  static Future<bool> isAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      _debugLog('isAvailable error: $e');
      return false;
    }
  }

  Future<void> startReadSession({
    required void Function(NfcReadResult) onResult,
    required void Function(String) onError,
  }) async {
    if (_sessionActive) return;
    _sessionActive = true;

    try {
      await NfcManager.instance.startSession(
        pollingOptions: NfcPollingOption.values.toSet(),
        invalidateAfterFirstRead: true,
        alertMessage: 'Acerca la tarjeta',
        onDiscovered: (NfcTag tag) async {
          try {
            final result = _extractDataFromTag(tag);
            if (result != null) {
              onResult(result);
            } else {
              onError('Tag no contiene una dirección válida');
            }
          } catch (e) {
            _debugLog('Read error: $e');
            onError(e.toString());
          } finally {
            _sessionActive = false;
          }
        },
      );
    } catch (e) {
      _debugLog('startSession error: $e');
      _sessionActive = false;
      onError(e.toString());
    }
  }

  Future<void> stopSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {
      // ignore
    }
    _sessionActive = false;
  }

  NfcReadResult? _extractDataFromTag(NfcTag tag) {
    final ndef = Ndef.from(tag);
    if (ndef == null) {
      _debugLog('Ndef es null');
      return null;
    }
    final message = ndef.cachedMessage;
    if (message == null || message.records.isEmpty) {
      _debugLog('No hay registros NDEF');
      return null;
    }

    for (final record in message.records) {
      String? raw;

      if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
          record.type.length == 1 &&
          record.type[0] == 0x55 &&
          record.payload.isNotEmpty) {
        final prefixIndex = record.payload[0];
        final prefix = (prefixIndex < NdefRecord.URI_PREFIX_LIST.length)
            ? NdefRecord.URI_PREFIX_LIST[prefixIndex]
            : '';
        final urlBytes = record.payload.sublist(1);
        raw = prefix + utf8.decode(urlBytes, allowMalformed: true);
      } else {
        if (record.payload.isNotEmpty) {
          raw = utf8.decode(record.payload, allowMalformed: true).trim();
        }
      }

      if (raw != null) {
        _debugLog('Dato leído: $raw');
        final result = _classifyData(raw);
        if (result != null) return result;
      }
    }
    return null;
  }

  NfcReadResult? _classifyData(String raw) {
    final lower = raw.toLowerCase().trim();

    if (lower.startsWith('lnurl1')) {
      return NfcReadResult(NfcReadResultType.lnurl, raw);
    }

    if (lower.startsWith('lnurlp://') || lower.startsWith('lnurlp:')) {
      return NfcReadResult(NfcReadResultType.lnurl, raw);
    }

    if (raw.contains('@') && raw.split('@').length == 2) {
      String clean = raw;
      // Remove 'lightning:' prefix if present (10 chars: 'lightning:')
      if (clean.toLowerCase().startsWith('lightning:')) {
        clean = clean.substring(10);
      }
      final parts = clean.split('@');
      if (parts[0].isNotEmpty && parts[1].contains('.')) {
        return NfcReadResult(NfcReadResultType.lightningAddress, clean);
      }
    }

    if (lower.startsWith('https://') || lower.startsWith('http://')) {
      return NfcReadResult(NfcReadResultType.lnurl, raw);
    }

    return null;
  }

  void dispose() {
    stopSession();
  }
}
