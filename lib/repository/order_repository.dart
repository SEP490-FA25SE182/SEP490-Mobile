import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/order.dart';
import '../provider.dart';

class OrderRepository {
  final Dio _dio;
  OrderRepository(this._dio);

  /// POST /api/rookie/users/orders/from-cart/{cartId}/wallet/{walletId}?usePoints={bool}
  Future<Order> moveCartToOrder({
    required String cartId,
    required String walletId,
    bool usePoints = false,
  }) async {
    final url = '/api/rookie/users/orders/from-cart/$cartId/wallet/$walletId';
    final res = await _dio.post(
      url,
      queryParameters: {'usePoints': usePoints},
      options: Options(contentType: Headers.jsonContentType),
    );
    return Order.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<Order> getById(String id) async {
    final res = await _dio.get('/api/rookie/users/orders/$id');
    return Order.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<List<Order>> getByCartId(String cartId) async {
    final res = await _dio.get('/api/rookie/users/orders/cart/$cartId');
    final raw = res.data;
    final items = (raw is List) ? raw : <dynamic>[];
    return items
        .whereType<Map>()
        .map((e) => Order.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<List<Order>> getByWalletId(String walletId) async {
    final res = await _dio.get('/api/rookie/users/orders/wallet/$walletId');
    final raw = res.data;
    final items = (raw is List) ? raw : <dynamic>[];
    return items
        .whereType<Map>()
        .map((e) => Order.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// GET SEARCH
  Future<List<Order>> search({
    required String userId,
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    final res = await _dio.get(
      '/api/rookie/users/orders/search',
      queryParameters: <String, dynamic>{
        'userId': userId,
        if (status != null) 'status': status,
        'page': page,
        'size': size,
      },
    );

    final data = res.data;

    final List items;
    if (data is Map && data['content'] is List) {
      items = data['content'] as List;
    } else if (data is List) {
      items = data;
    } else {
      items = const <dynamic>[];
    }

    return items
        .whereType<Map>()
        .map((e) => Order.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// PUT /api/rookie/users/orders/{id}
  Future<Order> update(
      String id, {
        int? amount,
        double? totalPrice,
        int? status,
        String? userAddressId,
        String? reason,
      }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'totalPrice': totalPrice,
      'status': status,
      'userAddressId': userAddressId,
      'reason': reason,
    }..removeWhere((_, v) => v == null);

    final res = await _dio.put(
      '/api/rookie/users/orders/$id',
      data: body,
      options: Options(contentType: Headers.jsonContentType),
    );
    return Order.fromJson((res.data as Map).cast<String, dynamic>());
  }


}

