import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/payment.dart';
import '../provider.dart';

class PaymentRepository {
  final Dio _dio;
  PaymentRepository(this._dio);

  /// POST /api/rookie/payments/{orderId}/checkout?returnUrl=...&cancelUrl=...
  Future<CreateCheckoutResponse> createCheckout(
      String orderId, {
        String? returnUrl,
        String? cancelUrl,
      }) async {
    final res = await _dio.post(
      '/api/rookie/payments/$orderId/checkout',
      queryParameters: <String, dynamic>{
        if (returnUrl != null && returnUrl.isNotEmpty) 'returnUrl': returnUrl,
        if (cancelUrl != null && cancelUrl.isNotEmpty) 'cancelUrl': cancelUrl,
      },
    );
    return CreateCheckoutResponse.fromJson(
      (res.data as Map).cast<String, dynamic>(),
    );
  }

  Future<CreateCheckoutResponse> deposit(
      String walletId, {
        required int amount,
        String? returnUrl,
        String? cancelUrl,
      }) async {
    final res = await _dio.post(
      '/api/rookie/payments/wallets/$walletId/deposit',
      queryParameters: <String, dynamic>{
        'amount': amount,
        if (returnUrl != null && returnUrl.isNotEmpty) 'returnUrl': returnUrl,
        if (cancelUrl != null && cancelUrl.isNotEmpty) 'cancelUrl': cancelUrl,
      },
    );
    return CreateCheckoutResponse.fromJson(
      (res.data as Map).cast<String, dynamic>(),
    );
  }

  /// POST /api/rookie/payments/wallets/{walletId}/withdraw
  Future<CreateCheckoutResponse> withdraw(
      String walletId, {
        required int amount,
        required String accountName,
        required String bankName,
        required String accountNumber,
        String? returnUrl,
        String? cancelUrl,
      }) async {
    final res = await _dio.post(
      '/api/rookie/payments/wallets/$walletId/withdraw',
      queryParameters: <String, dynamic>{
        'amount': amount,
        'accountName': accountName,
        'bankName': bankName,
        'accountNumber': accountNumber,
        if (returnUrl != null && returnUrl.isNotEmpty) 'returnUrl': returnUrl,
        if (cancelUrl != null && cancelUrl.isNotEmpty) 'cancelUrl': cancelUrl,
      },
    );
    return CreateCheckoutResponse.fromJson(
      (res.data as Map).cast<String, dynamic>(),
    );
  }
}


