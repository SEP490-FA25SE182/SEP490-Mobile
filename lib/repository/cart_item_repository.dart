import 'package:dio/dio.dart';
import '../model/cart_item.dart';

class CartItemRepository {
  final Dio _dio;
  CartItemRepository(this._dio);

  /// GET /api/rookie/users/carts/cart-items/cart/{cartId}
  Future<List<CartItem>> listByCart(String cartId) async {
    final res = await _dio.get('/api/rookie/users/carts/cart-items/cart/$cartId');
    final raw = res.data;
    final items = (raw is List) ? raw : <dynamic>[];
    return items
        .whereType<Map>()
        .map((e) => CartItem.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// POST /api/rookie/users/carts/cart-items/cart/{cartId}
  Future<CartItem> create({
    required String cartId,
    required String bookId,
    required int quantity,
    required double price,
  }) async {
    final body = {
      'bookId': bookId,
      'quantity': quantity,
      'price': price,
    };
    final res = await _dio.post('/api/rookie/users/carts/cart-items/cart/$cartId',
        data: body, options: Options(contentType: Headers.jsonContentType));
    return CartItem.fromJson((res.data as Map).cast<String, dynamic>());
  }

  /// PUT /api/rookie/users/carts/cart-items/{id}
  Future<CartItem> update(String cartItemId, {int? quantity, double? price}) async {
    final body = <String, dynamic>{
      'quantity': quantity,
      'price': price,
    }..removeWhere((_, v) => v == null);

    final res = await _dio.put(
      '/api/rookie/users/carts/cart-items/$cartItemId',
      data: body,
      options: Options(contentType: Headers.jsonContentType),
    );
    return CartItem.fromJson((res.data as Map).cast<String, dynamic>());
  }

  /// DELETE /api/rookie/users/carts/cart-items/{id}
  Future<void> remove(String cartItemId) async {
    await _dio.delete('/api/rookie/users/carts/cart-items/$cartItemId');
  }

  /// DELETE /api/rookie/users/carts/cart-items/cart/{cartId}/clear
  Future<void> clearCart(String cartId) async {
    await _dio.delete('/api/rookie/users/carts/cart-items/cart/$cartId/clear');
  }
}
