/// Lightning transaction information
class TransactionInfo {
  final String id;
  final String walletId;
  final int amount; // In millisats
  final String memo;
  final DateTime timestamp;
  final TransactionType type;
  final TransactionStatus status;
  final String? paymentHash;
  final String? invoice;
  final int? fee;
  final String? description;
  
  // Fiat currency information from LNBits extra field
  final String? fiatCurrency;     // Wallet default currency (USD)
  final double? fiatAmount;       // Amount in wallet currency
  final double? fiatRate;         // sats per wallet currency unit
  final double? btcRate;          // wallet currency per BTC
  
  // Original request fiat information
  final String? originalFiatCurrency;  // Original request currency (ZAR, AUD, etc.)
  final double? originalFiatAmount;    // Original requested amount
  final double? originalFiatRate;      // sats per original currency unit
  final double? originalBtcRate;       // original currency per BTC

  TransactionInfo({
    required this.id,
    required this.walletId,
    required this.amount,
    required this.memo,
    required this.timestamp,
    required this.type,
    required this.status,
    this.paymentHash,
    this.invoice,
    this.fee,
    this.description,
    this.fiatCurrency,
    this.fiatAmount,
    this.fiatRate,
    this.btcRate,
    this.originalFiatCurrency,
    this.originalFiatAmount,
    this.originalFiatRate,
    this.originalBtcRate,
  });

  int get amountSats => amount ~/ 1000;
  String get amountFormatted => '${amountSats.abs()} sats';
  
  String get displayAmount {
    final satsAmount = type == TransactionType.incoming ? '+$amountFormatted' : '-$amountFormatted';
    
    if (originalFiatAmount != null && originalFiatCurrency != null) {
      final fiatSign = type == TransactionType.incoming ? '+' : '-';
      return '$satsAmount\n$fiatSign${originalFiatAmount!.toStringAsFixed(2)} $originalFiatCurrency';
    }
    
    if (fiatAmount != null && fiatCurrency != null) {
      final fiatSign = type == TransactionType.incoming ? '+' : '-';
      return '$satsAmount\n$fiatSign${fiatAmount!.toStringAsFixed(2)} $fiatCurrency';
    }
    
    return satsAmount;
  }
  bool get isPending => status == TransactionStatus.pending;
  bool get isCompleted => status == TransactionStatus.completed;
  bool get isFailed => status == TransactionStatus.failed;
  bool get isIncoming => type == TransactionType.incoming;
  bool get isOutgoing => type == TransactionType.outgoing;

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      return 'Today ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Create from LNBits JSON
  factory TransactionInfo.fromJson(Map<String, dynamic> json) {
    try {
      final amount = json['amount'] as int;
      final type = amount > 0 ? TransactionType.incoming : TransactionType.outgoing;
      
      DateTime timestamp;
      if (json['time'] is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(json['time'] * 1000);
      } else if (json['time'] is double) {
        timestamp = DateTime.fromMillisecondsSinceEpoch((json['time'] as double).round() * 1000);
      } else if (json['time'] is String) {
        timestamp = DateTime.tryParse(json['time']) ?? DateTime.now();
      } else {
        timestamp = DateTime.now();
      }
      
      // Determinar status
      TransactionStatus status = TransactionStatus.completed;
      
      // Check both 'pending' boolean field and 'status' string field
      if (json['pending'] == true || json['status'] == 'pending') {
        status = TransactionStatus.pending;
      } else if (json['failed'] == true || json['status'] == 'failed') {
        status = TransactionStatus.failed;
      }

      // Extract fiat information from extra field
      String? fiatCurrency;
      double? fiatAmount;
      double? fiatRate;
      double? btcRate;
      String? originalFiatCurrency;
      double? originalFiatAmount;
      double? originalFiatRate;
      double? originalBtcRate;
      
      if (json['extra'] is Map<String, dynamic>) {
        final extra = json['extra'] as Map<String, dynamic>;
        
        // Wallet default currency information
        fiatCurrency = extra['wallet_fiat_currency']?.toString();
        fiatAmount = extra['wallet_fiat_amount']?.toDouble();
        fiatRate = extra['wallet_fiat_rate']?.toDouble();
        btcRate = extra['wallet_btc_rate']?.toDouble();
        
        // Original request currency information (if available from LNBits)
        originalFiatCurrency = extra['fiat_currency']?.toString();
        originalFiatAmount = extra['fiat_amount']?.toDouble();
        originalFiatRate = extra['fiat_rate']?.toDouble();
        originalBtcRate = extra['btc_rate']?.toDouble();
      }
      
      // FALLBACK: Parse original fiat info from memo if LNBits doesn't provide it
      // Handles "25 CUP", "25 CUP - description", "100.50 ZAR", etc.
      if (originalFiatCurrency == null && originalFiatAmount == null) {
        final memo = json['memo']?.toString() ?? '';
        final memoMatch = RegExp(r'(\d+(?:\.\d+)?)\s*([A-Z]{3})').firstMatch(memo.trim());
        if (memoMatch != null) {
          final fiatAmount = double.tryParse(memoMatch.group(1) ?? '');
          final currency = memoMatch.group(2);
          if (fiatAmount != null && currency != null) {
            originalFiatAmount = fiatAmount;
            originalFiatCurrency = currency;
            // Calculate rate based on sats amount (amount is in msat)
            final satsAmount = amount ~/ 1000;
            if (satsAmount > 0 && fiatAmount > 0) {
              originalFiatRate = satsAmount / fiatAmount;
            }
          }
        }
      }

      return TransactionInfo(
        id: json['payment_hash']?.toString() ?? json['id']?.toString() ?? '',
        walletId: json['wallet_id']?.toString() ?? '',
        amount: amount,
        memo: json['memo']?.toString() ?? json['description']?.toString() ?? 'No description',
        timestamp: timestamp,
        type: type,
        status: status,
        paymentHash: json['payment_hash']?.toString(),
        invoice: json['bolt11']?.toString(),
        fee: json['fee']?.toInt(),
        description: json['description']?.toString(),
        fiatCurrency: fiatCurrency,
        fiatAmount: fiatAmount,
        fiatRate: fiatRate,
        btcRate: btcRate,
        originalFiatCurrency: originalFiatCurrency,
        originalFiatAmount: originalFiatAmount,
        originalFiatRate: originalFiatRate,
        originalBtcRate: originalBtcRate,
      );
    } catch (e) {
      print('[TRANSACTION_INFO] Error parsing JSON: $e');
      throw Exception('Error parsing transaction: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'amount': amount,
      'memo': memo,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'status': status.name,
      'payment_hash': paymentHash,
      'bolt11': invoice,
      'fee': fee,
      'description': description,
      'fiat_currency': fiatCurrency,
      'fiat_amount': fiatAmount,
      'fiat_rate': fiatRate,
      'btc_rate': btcRate,
      'original_fiat_currency': originalFiatCurrency,
      'original_fiat_amount': originalFiatAmount,
      'original_fiat_rate': originalFiatRate,
      'original_btc_rate': originalBtcRate,
    };
  }

  @override
  String toString() {
    final fiatInfo = fiatAmount != null && fiatCurrency != null 
        ? ', fiat: ${fiatAmount!.toStringAsFixed(2)} $fiatCurrency' 
        : '';
    final originalInfo = originalFiatAmount != null && originalFiatCurrency != null 
        ? ', original: ${originalFiatAmount!.toStringAsFixed(2)} $originalFiatCurrency'
        : '';
    return 'TransactionInfo(id: $id, amount: $amountFormatted$fiatInfo$originalInfo, type: $type, status: $status, memo: $memo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum TransactionType {
  incoming,
  outgoing,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
}
class TransactionException implements Exception {
  final String message;
  
  TransactionException(this.message);
  
  @override
  String toString() => 'TransactionException: $message';
}

/// Transaction operation result
class TransactionResult {
  final bool success;
  final String? error;
  final List<TransactionInfo>? transactions;
  
  TransactionResult.success(this.transactions) : success = true, error = null;
  TransactionResult.error(this.error) : success = false, transactions = null;
}