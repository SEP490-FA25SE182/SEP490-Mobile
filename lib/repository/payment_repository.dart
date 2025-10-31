import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/payment.dart';
import '../provider.dart';

class PaymentRepository {
  final Dio _dio;
  PaymentRepository(this._dio);

  /// POST /api/rookie/payments/{orderId}/checkout
  Future<CreateCheckoutResponse> createCheckout(String orderId) async {
    final res = await _dio.post('/api/rookie/payments/$orderId/checkout');
    return CreateCheckoutResponse.fromJson((res.data as Map).cast<String, dynamic>());
  }
}


