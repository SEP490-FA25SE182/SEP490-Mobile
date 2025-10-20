import 'package:meta/meta.dart';

@immutable
class CartItem {
  final String cartItemId;
  final int quantity;
  final double price;
  final String cartId;
  final String bookId;

  const CartItem({
    required this.cartItemId,
    required this.quantity,
    required this.price,
    required this.cartId,
    required this.bookId,
  });

  factory CartItem.fromJson(Map<String, dynamic> j) {
    int _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
    double _double(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;

    return CartItem(
      cartItemId: (j['cartItemId'] ?? '').toString(),
      quantity  : _int(j['quantity']),
      price     : _double(j['price']),
      cartId    : (j['cartId'] ?? '').toString(),
      bookId    : (j['bookId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'cartItemId': cartItemId,
    'quantity'  : quantity,
    'price'     : price,
    'cartId'    : cartId,
    'bookId'    : bookId,
  };
}
