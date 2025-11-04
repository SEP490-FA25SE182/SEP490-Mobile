import 'package:dio/dio.dart';
import '../model/cart.dart';

class CartRepository {
  final Dio _dio;
  CartRepository(this._dio);

  /// GET /api/rookie/users/carts/user/{userId}
  Future<Cart?> getByUserId(String userId) async {
    final res = await _dio.get('/api/rookie/users/carts/user/$userId');
    final data = (res.data as Map).cast<String, dynamic>();
    final cart = Cart.fromJson(data);
    // Lọc ACTIVE ở client (phòng trường hợp BE trả cart INACTIVE)
    return cart.isActived.name == 'ACTIVE' ? cart : null;
  }

  /// PUT /api/rookie/users/carts/{id}
  Future<Cart> update(String cartId, {int? amount, double? totalPrice}) async {
    final body = <String, dynamic>{
      'amount': amount,
      'totalPrice': totalPrice,
      'isActived': 'ACTIVE',
    }..removeWhere((_, v) => v == null);

    final res = await _dio.put(
      '/api/rookie/users/carts/$cartId',
      data: body,
      options: Options(contentType: Headers.jsonContentType),
    );
    return Cart.fromJson((res.data as Map).cast<String, dynamic>());
  }

  /// POST /api/rookie/users/carts
  Future<Cart> createOne({required String userId}) async {
    final body = [
      {
        'userId': userId,
        'amount': 0,
        'totalPrice': 0,
        'isActived': 'ACTIVE',
      }
    ];
    final res = await _dio.post(
      '/api/rookie/users/carts',
      data: body,
      options: Options(contentType: Headers.jsonContentType),
    );

    final list = (res.data as List?)?.whereType<Map>().toList() ?? const [];
    if (list.isEmpty) {
      throw StateError('Tạo cart thất bại: server trả danh sách rỗng');
    }
    return Cart.fromJson(list.first.cast<String, dynamic>());
  }
}

