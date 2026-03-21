class LightningInvoice {
  final String paymentHash;
  final String paymentRequest;
  final int amount; // amount is in millisatoshis (msat), not satoshis
  final String memo;
  final DateTime createdAt;
  final bool isPaid;

  LightningInvoice({
    required this.paymentHash,
    required this.paymentRequest,
    required this.amount,
    required this.memo,
    required this.createdAt,
    required this.isPaid,
  });

  factory LightningInvoice.fromJson(Map<String, dynamic> json) {
    final paymentRequest = json['payment_request'] ?? json['bolt11'] ?? '';

    return LightningInvoice(
      paymentHash: json['payment_hash'] ?? json['checking_id'] ?? '',
      paymentRequest: paymentRequest,
      amount: json['amount'] ?? 0,
      memo: json['memo'] ?? '',
      createdAt:
          DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now(),
      isPaid: json['paid'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_hash': paymentHash,
      'payment_request': paymentRequest,
      'amount': amount,
      'memo': memo,
      'time': createdAt.toIso8601String(),
      'paid': isPaid,
    };
  }

  @override
  String toString() {
    final amountInSats = amount ~/ 1000;
    return 'LightningInvoice(hash: ${paymentHash.substring(0, 8)}..., amount: $amountInSats sats ($amount msat), memo: "$memo", paid: $isPaid)';
  }

  int get amountSats => amount ~/ 1000;

  String get formattedAmount => '$amountSats sats';
  LightningInvoice copyWith({
    String? paymentHash,
    String? paymentRequest,
    int? amount,
    String? memo,
    DateTime? createdAt,
    bool? isPaid,
  }) {
    return LightningInvoice(
      paymentHash: paymentHash ?? this.paymentHash,
      paymentRequest: paymentRequest ?? this.paymentRequest,
      amount: amount ?? this.amount,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LightningInvoice &&
        other.paymentHash == paymentHash &&
        other.paymentRequest == paymentRequest &&
        other.amount == amount;
  }

  @override
  int get hashCode =>
      paymentHash.hashCode ^ paymentRequest.hashCode ^ amount.hashCode;
}
