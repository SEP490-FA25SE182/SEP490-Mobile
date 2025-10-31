import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/order_detail.dart';
import '../provider.dart';

class OrderDetailRepository {
  final Dio _dio;
  OrderDetailRepository(this._dio);

  // GET /order/{orderId}
  Future<List<OrderDetail>> listByOrder(String orderId) async {
    final res = await _dio.get('/api/rookie/users/order/order-details/order/$orderId');
    final raw = res.data;
    final items = (raw is List) ? raw : <dynamic>[];
    return items
        .whereType<Map>()
        .map((e) => OrderDetail.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}
