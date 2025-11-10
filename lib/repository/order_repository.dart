import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/book.dart';
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
    print(res.data);
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


  //======== getPurchasedBooks
  Future<List<Book>> getPurchasedBooks(String userId) async {
    try {
      print('🔵 [OrderRepo] Fetching purchased books for user $userId');

      final orders = await search(userId: userId);
      print('🟩 [OrderRepo] Found ${orders.length} orders');

      final Set<String> bookIds = {};

      for (final order in orders) {
        final orderId = order.orderId;
        if (orderId == null) continue;

        try {
          final res = await _dio.get(
            '/api/rookie/users/order/order-details/order/$orderId',
          );
          if (res.data is List) {
            final details = res.data as List;
            for (final detail in details) {
              final bookId = detail['bookId'];
              if (bookId != null) bookIds.add(bookId);
            }
          }
        } catch (e) {
          print('[OrderRepo] Error fetching details for order $orderId: $e');
        }
      }

      print('[OrderRepo] Found ${bookIds.length} unique purchased book IDs');

      final List<Book> books = [];
      for (final id in bookIds) {
        try {
          final res = await _dio.get('/api/rookie/books/$id');
          if (res.data is Map<String, dynamic>) {
            books.add(Book.fromJson(res.data));
          }
        } catch (e) {
          print('[OrderRepo] Could not fetch book $id: $e');
        }
      }

      print('[OrderRepo] Returning ${books.length} purchased books');
      return books;
    } catch (e, st) {
      print('[OrderRepo] Error fetching purchased books: $e\n$st');
      return [];
    }
  }


}

