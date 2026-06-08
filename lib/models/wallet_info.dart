/// Lightning Network wallet information
class WalletInfo {
  final String id;
  final String name;
  final String adminKey;
  final String inKey;
  final String readKey;
  final int balanceMsat;

  WalletInfo({
    required this.id,
    required this.name,
    required this.adminKey,
    required this.inKey,
    required this.readKey,
    required this.balanceMsat,
  });

  int get balanceSats => balanceMsat ~/ 1000;
  String get balanceFormatted => '$balanceSats sats';

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      adminKey: json['adminkey'] ?? json['admin_key'] ?? json['adminKey'] ?? '',
      inKey: json['inkey'] ?? json['in_key'] ?? json['inKey'] ?? '',
      readKey: json['readkey'] ?? json['read_key'] ?? json['readKey'] ?? '',
      balanceMsat: json['balance_msat'] ?? json['balance'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'adminkey': adminKey,
      'inkey': inKey,
      'readkey': readKey,
      'balance_msat': balanceMsat,
    };
  }

  @override
  String toString() {
    return 'WalletInfo(id: $id, name: $name, balance: $balanceSats sats)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WalletInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Detailed wallet balance
class WalletBalance {
  final String id;
  final String name;
  final int balanceMsat;

  WalletBalance({
    required this.id,
    required this.name,
    required this.balanceMsat,
  });

  int get balanceSats => balanceMsat ~/ 1000;
  String get balanceFormatted => '$balanceSats sats';

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      id: json['id'] as String,
      name: json['name'] as String,
      balanceMsat: json['balance'] as int,
    );
  }

  @override
  String toString() {
    return 'WalletBalance(id: $id, name: $name, balance: $balanceSats sats)';
  }
}

class WalletException implements Exception {
  final String message;

  WalletException(this.message);

  @override
  String toString() => 'WalletException: $message';
}
