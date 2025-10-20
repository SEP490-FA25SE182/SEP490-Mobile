import 'package:meta/meta.dart';
import '../util/model.dart';
import 'cart_item.dart';
import 'order.dart';

@immutable
class Cart {
  final String cartId;
  final int amount;
  final double totalPrice;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final IsActived isActived;
  final String userId;

  final List<CartItem> cartItems;
  final List<Order> orders;

  const Cart({
    required this.cartId,
    required this.amount,
    required this.totalPrice,
    this.updatedAt,
    this.createdAt,
    this.isActived = IsActived.ACTIVE,
    required this.userId,
    this.cartItems = const [],
    this.orders = const [],
  });

  factory Cart.fromJson(Map<String, dynamic> j) {
    int _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
    double _double(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;

    final items = ((j['cartItems'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CartItem.fromJson)
        .toList();

    final ords = ((j['orders'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Order.fromJson)
        .toList();

    return Cart(
      cartId    : (j['cartId'] ?? '').toString(),
      amount    : _int(j['amount']),
      totalPrice: _double(j['totalPrice']),
      updatedAt : parseInstant(j['updatedAt']),
      createdAt : parseInstant(j['createdAt']),
      isActived : parseIsActived(j['isActived']),
      userId    : (j['userId'] ?? '').toString(),
      cartItems : items,
      orders    : ords,
    );
  }

  Map<String, dynamic> toJson() => {
    'cartId'    : cartId,
    'amount'    : amount,
    'totalPrice': totalPrice,
    'updatedAt' : updatedAt?.toIso8601String(),
    'createdAt' : createdAt?.toIso8601String(),
    'isActived' : isActivedToJson(isActived),
    'userId'    : userId,
    'cartItems' : cartItems.map((e) => e.toJson()).toList(),
    'orders'    : orders.map((e) => e.toJson()).toList(),
  };
}
