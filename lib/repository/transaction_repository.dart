import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/transaction.dart';
import '../util/model.dart';
import '../util/trans_type.dart';

class PageResp<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;

  PageResp({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
  });
}

class TransactionRepository {
  final Dio _dio;
  TransactionRepository(this._dio);

  static const _base = '/api/rookie/transactions';

  /// Tạo mới
  Future<Transaction> create({
    required double totalPrice,
    required int status,
    String? orderId,
    required String paymentMethodId,
    String? walletId,
    int? orderCode,
    IsActived isActived = IsActived.ACTIVE,
    TransactionType transType = TransactionType.PAYMENT,
  }) async {
    final body = {
      'totalPrice': totalPrice,
      'status': status,
      'orderId': orderId,
      'walletId': walletId,
      'paymentMethodId': paymentMethodId,
      if (orderCode != null) 'orderCode': orderCode,
      'isActived': isActived.name,
      'transType'      : transType.name,
    };
    final res = await _dio.post(_base, data: body);
    return Transaction.fromJson(res.data as Map<String, dynamic>);
  }

  /// Tạo transaction cho Ví (Wallet)
  Future<Transaction> createWallet({
    required double totalPrice,
    required int status,
    required String orderId,
    String? walletId,
    int? orderCode,
    IsActived isActived = IsActived.ACTIVE,
    TransactionType transType = TransactionType.PAYMENT,
  }) async {
    final body = {
      'totalPrice': totalPrice,
      'status': status,
      'orderId': orderId,
      'walletId': walletId,
      if (orderCode != null) 'orderCode': orderCode,
      'isActived': isActived.name,
      'transType'  : transType.name,
    };
    final res = await _dio.post('$_base/wallet', data: body);
    return Transaction.fromJson(res.data as Map<String, dynamic>);
  }

  /// Tạo transaction cho COD
  Future<Transaction> createCOD({
    required double totalPrice,
    required int status,
    required String orderId,
    int? orderCode,
    IsActived isActived = IsActived.ACTIVE,
  }) async {
    final body = {
      'totalPrice': totalPrice,
      'status': status,
      'orderId': orderId,
      if (orderCode != null) 'orderCode': orderCode,
      'isActived': isActived.name,
    };
    final res = await _dio.post('$_base/cod', data: body);
    return Transaction.fromJson(res.data as Map<String, dynamic>);
  }

  /// Lấy theo id
  Future<Transaction> getById(String id) async {
    final res = await _dio.get('$_base/$id');
    return Transaction.fromJson(res.data as Map<String, dynamic>);
  }

  /// Cập nhật
  Future<Transaction> update(
      String id, {
        double? totalPrice,
        int? status,
        int? orderCode,
        IsActived? isActived,
        TransactionType? transType,
      }) async {
    final body = <String, dynamic>{
      if (totalPrice != null) 'totalPrice': totalPrice,
      if (status != null) 'status': status,
      if (orderCode != null) 'orderCode': orderCode,
      if (isActived != null) 'isActived': isActived.name,
      if (transType != null) 'transType': transType.name,
    };
    final res = await _dio.put('$_base/$id', data: body);
    return Transaction.fromJson(res.data as Map<String, dynamic>);
  }

  /// Soft delete
  Future<void> delete(String id) async {
    await _dio.delete('$_base/$id');
  }

  /// Search (Spring Page)
  Future<PageResp<Transaction>> search({
    String? statusName,
    IsActived? isActived,
    TransactionType? transType,
    String? paymentMethodName,
    String? orderId,
    String? paymentMethodId,
    String? walletId,
    int page = 0,
    int size = 20,
    List<String>? sort,
  }) async {
    final params = {
      if (statusName != null && statusName.trim().isNotEmpty) 'status': statusName.trim(),
      if (isActived != null) 'isActived': isActived.name,
      if (transType != null) 'transType': transType.name,
      if (paymentMethodName != null && paymentMethodName.trim().isNotEmpty)
        'paymentMethodName': paymentMethodName.trim(),
      if (orderId != null && orderId.trim().isNotEmpty) 'orderId': orderId.trim(),
      if (paymentMethodId != null && paymentMethodId.trim().isNotEmpty) 'paymentMethodId': paymentMethodId.trim(),
      if (walletId != null && walletId.trim().isNotEmpty) 'walletId': walletId.trim(),
      'page': page,
      'size': size,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    };

    final res = await _dio.get('$_base/search', queryParameters: params);
    final data = res.data as Map<String, dynamic>;
    final content = (data['content'] as List? ?? [])
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList();

    return PageResp<Transaction>(
      content: content,
      totalElements: (data['totalElements'] as num?)?.toInt() ?? content.length,
      totalPages   : (data['totalPages'] as num?)?.toInt() ?? 1,
      number       : (data['number'] as num?)?.toInt() ?? page,
      size         : (data['size'] as num?)?.toInt() ?? size,
    );
  }
}

