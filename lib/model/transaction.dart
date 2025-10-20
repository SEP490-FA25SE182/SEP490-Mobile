import 'package:meta/meta.dart';
import '../util/model.dart';

@immutable
class TransactionModel {
  final String transactionId;
  final double totalPrice;
  final DateTime? updatedAt;     
  final DateTime? createdAt;
  final int status;
  final String paymentMethodId;
  final String orderId;
  final int? orderCode;
  final IsActived isActived;

  const TransactionModel({
    required this.transactionId,
    required this.totalPrice,
    this.updatedAt,
    this.createdAt,
    required this.status,
    required this.paymentMethodId,
    required this.orderId,
    this.orderCode,
    this.isActived = IsActived.ACTIVE,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> j) {
    double _double(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;
    int? _intN(dynamic v) =>
        v == null ? null : (v is int ? v : int.tryParse(v.toString()));

    return TransactionModel(
      transactionId  : (j['transactionId'] ?? '').toString(),
      totalPrice     : _double(j['totalPrice']),
      updatedAt      : parseInstant(j['updatedAt']),
      createdAt      : parseInstant(j['createdAt']),
      status         : _intN(j['status']) ?? 0,
      paymentMethodId: (j['paymentMethodId'] ?? '').toString(),
      orderId        : (j['orderId'] ?? '').toString(),
      orderCode      : _intN(j['orderCode']),
      isActived      : parseIsActived(j['isActived']),
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
    'orderCode'      : orderCode,
    'isActived'      : isActived.name,
  };
}
