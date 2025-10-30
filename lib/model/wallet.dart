import 'package:meta/meta.dart';
import '../util/model.dart';

@immutable
class Wallet {
  final String walletId;
  final int coin;
  final double balance;
  final String userId;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final IsActived isActived;

  const Wallet({
    required this.walletId,
    required this.coin,
    required this.balance,
    required this.userId,
    this.updatedAt,
    this.createdAt,
    this.isActived = IsActived.ACTIVE,
  });

  factory Wallet.fromJson(Map<String, dynamic> j) {
    int _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
    double _double(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;

    return Wallet(
      walletId : (j['walletId'] ?? '').toString(),
      coin     : _int(j['coin']),
      balance  : _double(j['balance']),
      userId   : (j['userId'] ?? '').toString(),
      updatedAt: parseInstant(j['updatedAt']),
      createdAt: parseInstant(j['createdAt']),
      isActived: parseIsActived(j['isActived']),
    );
  }

  Map<String, dynamic> toJson() => {
    'walletId' : walletId,
    'coin'     : coin,
    'balance'  : balance,
    'userId'   : userId,
    'updatedAt': updatedAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'isActived': isActivedToJson(isActived),
  };
}
