import 'package:meta/meta.dart';

@immutable
class OrderDetail {
  final String orderDetailId;
  final int quantity;
  final double price;
  final String orderId;
  final String bookId;

  const OrderDetail({
    required this.orderDetailId,
    required this.quantity,
    required this.price,
    required this.orderId,
    required this.bookId,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> j) {
    int _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
    double _double(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;

    return OrderDetail(
      orderDetailId: (j['orderDetailId'] ?? '').toString(),
      quantity     : _int(j['quantity']),
      price        : _double(j['price']),
      orderId      : (j['orderId'] ?? '').toString(),
      bookId       : (j['bookId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'orderDetailId': orderDetailId,
    'quantity'     : quantity,
    'price'        : price,
    'orderId'      : orderId,
    'bookId'       : bookId,
  };
}
