import 'package:dio/dio.dart';

enum PaymentErrorKind {
  insufficientBalance,
  feeReserveRequired,
  alreadyPaid,
  stillPending,
  routeNotFound,
  paymentNotFound,
  authenticationError,
  amountlessInvoice,
  lnurlOrDecodeError,
  serverError,
  unknown,
}

class PaymentError implements Exception {
  final PaymentErrorKind kind;
  final String? rawDetail;
  final int? statusCode;

  const PaymentError(this.kind, {this.rawDetail, this.statusCode});

  static PaymentError fromDio(DioException e) {
    final status = e.response?.statusCode;
    final detail = _extractDetail(e.response?.data);

    // 1) Classify by body text first — LNbits errors carry the same strings
    //    regardless of whether the status is wrapped by a proxy (e.g. 520).
    if (detail != null) {
      final lower = detail.toLowerCase();
      if (lower.contains('insufficient balance') ||
          lower.contains('not enough funds')) {
        return PaymentError(PaymentErrorKind.insufficientBalance,
            rawDetail: detail, statusCode: status);
      }
      if (lower.contains('must reserve at least')) {
        return PaymentError(PaymentErrorKind.feeReserveRequired,
            rawDetail: detail, statusCode: status);
      }
      if (lower.contains('already paid')) {
        return PaymentError(PaymentErrorKind.alreadyPaid,
            rawDetail: detail, statusCode: status);
      }
      if (lower.contains('still pending')) {
        return PaymentError(PaymentErrorKind.stillPending,
            rawDetail: detail, statusCode: status);
      }
      if (lower.contains('failed node') ||
          lower.contains('retrying is not possible') ||
          lower.contains('no_route') ||
          lower.contains('no route')) {
        return PaymentError(PaymentErrorKind.routeNotFound,
            rawDetail: detail, statusCode: status);
      }
      if (lower.contains('amountless')) {
        return PaymentError(PaymentErrorKind.amountlessInvoice,
            rawDetail: detail, statusCode: status);
      }
    }

    // 2) Fall back to status-code classification.
    if (status == 401) {
      return PaymentError(PaymentErrorKind.authenticationError,
          rawDetail: detail, statusCode: status);
    }
    if (status == 404) {
      return PaymentError(PaymentErrorKind.paymentNotFound,
          rawDetail: detail, statusCode: status);
    }
    if (status == 520 || status == 500 || status == 502 || status == 503) {
      return PaymentError(PaymentErrorKind.serverError,
          rawDetail: detail, statusCode: status);
    }
    if (status == 400) {
      return PaymentError(PaymentErrorKind.lnurlOrDecodeError,
          rawDetail: detail, statusCode: status);
    }
    return PaymentError(PaymentErrorKind.unknown,
        rawDetail: detail, statusCode: status);
  }

  static String? _extractDetail(dynamic body) {
    if (body == null) return null;
    if (body is String) return body;
    if (body is Map) {
      final d = body['detail'] ?? body['message'] ?? body['error'];
      if (d is String) return d;
      // FastAPI-style: detail may be a list of {loc, msg, type}. Join msgs
      // so substring matching still works and users don't see raw maps.
      if (d is List) {
        final msgs = d
            .whereType<Map>()
            .map((m) => m['msg'])
            .whereType<String>()
            .toList();
        if (msgs.isNotEmpty) return msgs.join('; ');
      }
      return null;
    }
    return null;
  }

  @override
  String toString() =>
      'PaymentError(${kind.name}, status=$statusCode, detail=$rawDetail)';
}
