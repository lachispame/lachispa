import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter_nfc_hce/flutter_nfc_hce.dart';
import '../core/utils/proxy_config.dart';
import 'app_info_service.dart';
import '../l10n/generated/app_localizations.dart';

void _debugLog(String message) {
  if (kDebugMode) {
    print('[HCE_WALLET] $message');
  }
}

enum NfcChargeStatus {
  scanning,
  reading,
  charging,
  success,
  invalidTag,
  networkError,
  callbackError,
}

enum ModoNfcRecibir {
  hceWallet,    // Emitir HCE → pagador usa Phoenix u otra wallet
  lectorBoltcard, // Lector NFC   → pagador usa BoltCard física
}

class NfcChargeResult {
  final NfcChargeStatus status;
  final String? message;
  const NfcChargeResult(this.status, {this.message});
}

class NfcChargeService {
  final Dio _dio = Dio();
  final FlutterNfcHce _hce = FlutterNfcHce();
  bool _sessionActive = false;
  bool _processingTag = false;
  final AppLocalizations _l10n;

  NfcChargeService(this._l10n) {
    _configureDio();
  }

  void _configureDio() {
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    _dio.options.headers['User-Agent'] = isAndroid
        ? AppInfoService.getUserAgent('Android')
        : AppInfoService.getUserAgent();
    _dio.options.headers['Accept'] = 'application/json';
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.sendTimeout = const Duration(seconds: 15);
    _dio.options.followRedirects = true;
    _dio.options.maxRedirects = 5;
    _dio.options.validateStatus =
        (status) => status != null && status >= 200 && status < 400;
    ProxyConfig.configureProxy(_dio);
  }

  static Future<bool> isAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      _debugLog('isAvailable threw: $e');
      return false;
    }
  }

  bool get isSessionActive => _sessionActive;

  Future<void> startChargeSession({
    required String lnurlOrInvoice,
    required ModoNfcRecibir modo,
    required void Function(NfcChargeResult) onStatus,
  }) async {
    if (_sessionActive) return;
    _sessionActive = true;

    // CRÍTICO: asegurarse que HCE está detenido antes de activar lector
    if (modo == ModoNfcRecibir.lectorBoltcard) {
      try { await _hce.stopNfcHce(); } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 300));
    }

    onStatus(const NfcChargeResult(NfcChargeStatus.scanning));

    try {
      switch (modo) {
        case ModoNfcRecibir.hceWallet:
          // HCE Mode: Emitir para wallet (Phoenix)
          _debugLog('Emitiendo para wallet: $lnurlOrInvoice');
          final isInvoice = lnurlOrInvoice.startsWith('lightning:lnbc') || lnurlOrInvoice.startsWith('lnbc');
          _debugLog('Tipo de contenido: ${isInvoice ? 'INVOICE' : 'LNURL'}');
          _debugLog('Longitud del contenido: ${lnurlOrInvoice.length}');
          if (isInvoice) {
            _debugLog('INVOICE detectada - primeros 30 chars: ${lnurlOrInvoice.substring(0, lnurlOrInvoice.length > 30 ? 30 : lnurlOrInvoice.length)}');
          }

          // CRÍTICO: Detener NfcManager y HCE previo antes de iniciar HCE
          try {
            await NfcManager.instance.stopSession();
            _debugLog('NfcManager detenido correctamente');
          } catch (_) {}
          try {
            await _hce.stopNfcHce();
            _debugLog('HCE previo detenido');
          } catch (_) {}
          await Future.delayed(const Duration(milliseconds: 500));

          // Verificar contenido no vacío
          if (lnurlOrInvoice.isEmpty) {
            _debugLog('ERROR: Contenido vacío');
            onStatus(const NfcChargeResult(NfcChargeStatus.invalidTag));
            break;
          }

          final result = await _hce.startNfcHce(
            lnurlOrInvoice,
            mimeType: 'text/plain',
            persistMessage: true, // true para persistir el mensaje NDEF
          );
          _debugLog('Resultado startNfcHce: $result');
          _debugLog('Emulación NFC iniciada correctamente');
          onStatus(const NfcChargeResult(NfcChargeStatus.reading));
          // HCE queda activo esperando que un lector se conecte
          // El usuario debe detener la sesión manualmente
          break;

        case ModoNfcRecibir.lectorBoltcard:
          // BoltCard Mode: Lector NFC
          _debugLog('NFC: Iniciando lectura de tarjeta');
          await NfcManager.instance.startSession(
            pollingOptions: {NfcPollingOption.iso14443},
            invalidateAfterFirstRead: false,
            alertMessage: 'Acerca la tarjeta',
            onDiscovered: (NfcTag tag) async {
              if (_processingTag) return;
              _processingTag = true;
              try {
                onStatus(const NfcChargeResult(NfcChargeStatus.reading));

                final url = _extractUriFromTag(tag);
                if (url == null) {
                  onStatus(const NfcChargeResult(NfcChargeStatus.invalidTag));
                  await _safeStop(errorMessage: _l10n.nfc_tag_not_compatible);
                  return;
                }
                _debugLog('Tag URL: $url');

                final metaResponse = await _dio.get(url);
                final meta = metaResponse.data;
                if (meta is! Map) {
                  onStatus(const NfcChargeResult(NfcChargeStatus.invalidTag));
                  await _safeStop(errorMessage: _l10n.nfc_invalid_response);
                  return;
                }
                if (meta['tag'] != 'withdrawRequest') {
                  onStatus(const NfcChargeResult(NfcChargeStatus.invalidTag));
                  await _safeStop(errorMessage: _l10n.nfc_not_boltcard);
                  return;
                }
                final callbackValue = meta['callback'];
                final k1Value = meta['k1'];
                if (callbackValue is! String ||
                    callbackValue.isEmpty ||
                    k1Value is! String ||
                    k1Value.isEmpty) {
                  onStatus(const NfcChargeResult(NfcChargeStatus.invalidTag));
                  await _safeStop(errorMessage: _l10n.nfc_incomplete_data);
                  return;
                }
                final callback = callbackValue;
                final k1 = k1Value;

                onStatus(const NfcChargeResult(NfcChargeStatus.charging));

                final claim = await _dio.get(callback, queryParameters: {
                  'k1': k1,
                  'pr': lnurlOrInvoice,
                });

                final claimData = claim.data;
                if (claimData is Map && claimData['status'] == 'OK') {
                  onStatus(const NfcChargeResult(NfcChargeStatus.success));
                  await _safeStop(alertMessage: 'OK');
                } else {
                  final reason = claimData is Map
                      ? claimData['reason']?.toString()
                      : null;
                  onStatus(NfcChargeResult(
                    NfcChargeStatus.callbackError,
                    message: reason,
                  ));
                  await _safeStop(errorMessage: reason);
                }
                } catch (e) {
                _debugLog('Discovery handler error: $e');
                onStatus(NfcChargeResult(
                  NfcChargeStatus.networkError,
                  message: e.toString(),
                ));
                await _safeStop(errorMessage: _l10n.nfc_network_error);
              } finally {
                _processingTag = false;
                _sessionActive = false;
              }
            },
          );
          break;
      }
    } catch (e) {
      _debugLog('startSession error: $e');
      _sessionActive = false;
      onStatus(NfcChargeResult(
        NfcChargeStatus.networkError,
        message: e.toString(),
      ));
    }
  }

  Future<void> stopSession() async {
    await _safeStop();
    try { await _hce.stopNfcHce(); } catch (_) {}
    _sessionActive = false;
    _processingTag = false;
  }

  Future<void> _safeStop({String? alertMessage, String? errorMessage}) async {
    try {
      await NfcManager.instance.stopSession(
        alertMessage: alertMessage,
        errorMessage: errorMessage,
      );
    } catch (_) {
      // ignore
    }
  }

  String? _extractUriFromTag(NfcTag tag) {
    final ndef = Ndef.from(tag);
    if (ndef == null) {
      _debugLog('Ndef es null - la tarjeta no soporta NDEF');
      return null;
    }
    final message = ndef.cachedMessage;
    if (message == null || message.records.isEmpty) {
      _debugLog('No hay registros NDEF en la tarjeta');
      return null;
    }

    _debugLog('Registros encontrados: ${message.records.length}');

    for (final record in message.records) {
      _debugLog('Record typeNameFormat: ${record.typeNameFormat}');
      _debugLog('Record type: ${record.type}');
      _debugLog('Record payload length: ${record.payload.length}');

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
        _debugLog('URI estándar leído: $raw');
      } else {
        final payload = record.payload;
        if (payload.isNotEmpty) {
          // Handle RTD_TEXT properly
          if (payload.length > 1) {
            final statusByte = payload[0];
            final encoding = ((statusByte & 0x80) == 0 ? utf8 : Encoding.getByName('utf-16')) ?? utf8;
            final langLength = statusByte & 0x3F;
            if (payload.length > 1 + langLength) {
              final contentBytes = payload.sublist(1 + langLength);
              raw = encoding.decode(contentBytes);
              _debugLog('Payload decodificado (RTD_TEXT): $raw');
            }
          } else {
            raw = utf8.decode(payload, allowMalformed: true).trim();
            _debugLog('Payload crudo leído: $raw');
          }
        }
      }

      if (raw != null) {
        _debugLog('Intentando normalizar: $raw');
        final normalized = _normalizeLnurlw(raw);
        if (normalized != null) {
          _debugLog('URL normalizada: $normalized');
          return normalized;
        }
      }
    }
    _debugLog('No se encontró una URL LNURLW válida');
    return null;
  }

  String? _normalizeLnurlw(String raw) {
    if (raw.isEmpty) return null;
    final lower = raw.toLowerCase();
    if (lower.startsWith('lnurlw://')) {
      return 'https://${raw.substring(9)}';
    }
    if (lower.startsWith('lnurlw:') && !lower.startsWith('lnurlw://')) {
      return 'https://${raw.substring(7)}';
    }
    if (lower.startsWith('https://') || lower.startsWith('http://')) {
      return raw;
    }
    return null;
  }

  void dispose() {
    try { _hce.stopNfcHce(); } catch (_) {}
    _dio.close(force: true);
  }
}
