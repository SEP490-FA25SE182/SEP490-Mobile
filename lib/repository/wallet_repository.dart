// lib/repository/wallet_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/wallet.dart';
import '../provider.dart'; // chứa dioProvider

class WalletRepository {
  final Dio _dio;
  WalletRepository(this._dio);

  /// GET /api/rookie/users/wallets/user/{userId}
  Future<Wallet?> getByUserId(String userId) async {
    try {
      final res = await _dio.get('/api/rookie/users/wallets/user/$userId');
      return Wallet.fromJson((res.data as Map).cast<String, dynamic>());
    } on DioException catch (_) {
      // Không có ví -> trả null
      return null;
    }
  }

  /// POST /api/rookie/users/wallets
  Future<Wallet> createOne({required String userId, int coin = 0, double balance = 0}) async {
    final body = [
      {
        'userId': userId,
        'coin': coin,
        'balance': balance,
        'isActived': 'ACTIVE',
      }
    ];
    final res = await _dio.post(
      '/api/rookie/users/wallets',
      data: body,
      options: Options(contentType: Headers.jsonContentType),
    );
    final list = (res.data as List?)?.whereType<Map>().toList() ?? const [];
    if (list.isEmpty) {
      throw StateError('Tạo ví thất bại: server trả danh sách rỗng');
    }
    return Wallet.fromJson(list.first.cast<String, dynamic>());
  }

  /// PUT /api/rookie/users/wallets/{id}
  Future<Wallet> update(String walletId, {int? coin, double? balance}) async {
    final body = <String, dynamic>{
      'coin': coin,
      'balance': balance,
    }..removeWhere((_, v) => v == null);

    final res = await _dio.put(
      '/api/rookie/users/wallets/$walletId',
      data: body,
      options: Options(contentType: Headers.jsonContentType),
    );
    return Wallet.fromJson((res.data as Map).cast<String, dynamic>());
  }
}
