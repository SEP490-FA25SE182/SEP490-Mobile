import 'package:meta/meta.dart';
import '../util/model.dart';
import 'order_detail.dart';

@immutable
class Order {
  final String orderId;
  final int amount;
  final double totalPrice;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final int status;
  final String walletId;
  final String cartId;

  final List<OrderDetail> orderDetails;

  const Order({
    required this.orderId,
    required this.amount,
    required this.totalPrice,
    this.updatedAt,
    this.createdAt,
    required this.status,
    required this.walletId,
    required this.cartId,
    this.orderDetails = const [],
  });

  factory Order.fromJson(Map<String, dynamic> j) {
    int _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
    double _double(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;

    final details = ((j['orderDetails'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OrderDetail.fromJson)
        .toList();

    return Order(
      orderId    : (j['orderId'] ?? '').toString(),
      amount     : _int(j['amount']),
      totalPrice : _double(j['totalPrice']),
      updatedAt  : parseInstant(j['updatedAt']),
      createdAt  : parseInstant(j['createdAt']),
      status     : _int(j['status']),
      walletId   : (j['walletId'] ?? '').toString(),
      cartId     : (j['cartId'] ?? '').toString(),
      orderDetails: details,
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId'    : orderId,
    'amount'     : amount,
    'totalPrice' : totalPrice,
    'updatedAt'  : updatedAt?.toIso8601String(),
    'createdAt'  : createdAt?.toIso8601String(),
    'status'     : status,
    'walletId'   : walletId,
    'cartId'     : cartId,
    'orderDetails': orderDetails.map((e) => e.toJson()).toList(),
  };
}
