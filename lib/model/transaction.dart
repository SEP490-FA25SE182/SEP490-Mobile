// lib/model/transaction.dart
import 'package:meta/meta.dart';
import '../util/model.dart';
import '../util/trans_type.dart';

@immutable
class Transaction {
  final String transactionId;
  final double totalPrice;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final int status;
  final String paymentMethodId;
  final String? orderId;
  final int? orderCode;
  final String? walletId;
  final IsActived isActived;
  final TransactionType transType;

  const Transaction({
    required this.transactionId,
    required this.totalPrice,
    this.updatedAt,
    this.createdAt,
    required this.status,
    required this.paymentMethodId,
    this.orderId,
    this.walletId,
    this.orderCode,
    this.isActived = IsActived.ACTIVE,
    this.transType = TransactionType.PAYMENT,
  });

  factory Transaction.fromJson(Map<String, dynamic> j) {
    double _double(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;
    int? _intN(dynamic v) =>
        v == null ? null : (v is int ? v : int.tryParse(v.toString()));

    return Transaction(
      transactionId  : (j['transactionId'] ?? '').toString(),
      totalPrice     : _double(j['totalPrice']),
      updatedAt      : parseInstant(j['updatedAt']),
      createdAt      : parseInstant(j['createdAt']),
      status         : _intN(j['status']) ?? 0,
      paymentMethodId: (j['paymentMethodId'] ?? '').toString(),
      orderId        : (j['orderId'] ?? '').toString(),
      walletId        : (j['walletId'] ?? '').toString(),
      orderCode      : _intN(j['orderCode']),
      isActived      : parseIsActived(j['isActived']),
      transType      : parseTransactionType(j['transType']),
    );
  }

  Map<String, dynamic> toJson() => {
    'transactionId'  : transactionId,
    'totalPrice'     : totalPrice,
    'updatedAt'      : updatedAt?.toIso8601String(),
    'createdAt'      : createdAt?.toIso8601String(),
    'status'         : status,
    'paymentMethodId': paymentMethodId,
    'orderId'        : orderId,
    'walletId'        : walletId,
    'orderCode'      : orderCode,
    'isActived'      : isActived.name,
    'transType'      : transType.name,
  };

  Transaction copyWith({
    String? transactionId,
    double? totalPrice,
    DateTime? updatedAt,
    DateTime? createdAt,
    int? status,
    String? paymentMethodId,
    String? orderId,
    String? walletId,
    int? orderCode,
    IsActived? isActived,
    TransactionType? transType,
  }) => Transaction(
    transactionId: transactionId ?? this.transactionId,
    totalPrice: totalPrice ?? this.totalPrice,
    updatedAt: updatedAt ?? this.updatedAt,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    paymentMethodId: paymentMethodId ?? this.paymentMethodId,
    orderId: orderId ?? this.orderId,
    walletId: walletId ?? this.walletId,
    orderCode: orderCode ?? this.orderCode,
    isActived: isActived ?? this.isActived,
    transType: transType ?? this.transType,
  );
}
