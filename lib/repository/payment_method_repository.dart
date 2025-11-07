import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/payment_method.dart';
import '../util/model.dart';
import 'transaction_repository.dart' show PageResp;

class PaymentMethodRepository {
  final Dio _dio;
  PaymentMethodRepository(this._dio);

  static const _base = '/api/rookie/payment-methods';

  Future<PaymentMethod> create({
    String? methodName,
    String? provider,
    String? decription,
    IsActived isActived = IsActived.ACTIVE,
  }) async {
    final body = {
      'methodName': methodName,
      'provider': provider,
      'decription': decription,
      'isActived': isActived.name,
    };
    final res = await _dio.post(_base, data: body);
    return PaymentMethod.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PaymentMethod> getById(String id) async {
    final res = await _dio.get('$_base/$id');
    return PaymentMethod.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PaymentMethod> update(
      String id, {
        String? methodName,
        String? provider,
        String? decription,
        IsActived? isActived,
      }) async {
    final body = <String, dynamic>{
      if (methodName != null) 'methodName': methodName,
      if (provider != null) 'provider': provider,
      if (decription != null) 'decription': decription,
      if (isActived != null) 'isActived': isActived.name,
    };
    final res = await _dio.put('$_base/$id', data: body);
    return PaymentMethod.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete('$_base/$id');
  }

  /// Search (Spring Page)
  Future<PageResp<PaymentMethod>> search({
    String? q,
    IsActived? isActived,
    int page = 0,
    int size = 20,
    List<String>? sort,
  }) async {
    final params = {
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (isActived != null) 'isActived': isActived.name,
      'page': page,
      'size': size,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    };

    final res = await _dio.get('$_base/search', queryParameters: params);
    final data = res.data as Map<String, dynamic>;
    final content = (data['content'] as List? ?? [])
        .map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
        .toList();

    return PageResp<PaymentMethod>(
      content: content,
      totalElements: (data['totalElements'] as num?)?.toInt() ?? content.length,
      totalPages   : (data['totalPages'] as num?)?.toInt() ?? 1,
      number       : (data['number'] as num?)?.toInt() ?? page,
      size         : (data['size'] as num?)?.toInt() ?? size,
    );
  }
}
