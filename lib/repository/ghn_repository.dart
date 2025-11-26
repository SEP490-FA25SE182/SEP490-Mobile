import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../model/ghn_models.dart';
import '../model/ghn_shipping_fee.dart';
import '../model/ghn_shipping_fee_request_dto.dart';

class GhnRepository {
  final Dio _dio;
  GhnRepository(this._dio);

  /// GET /api/rookie/shipping/provinces
  Future<List<GhnProvince>> getProvinces() async {
    try {
      final res = await _dio.get('/api/rookie/shipping/provinces');

      if (res.data == null) {
        debugPrint('GHN Provinces: res.data is null');
        return [];
      }

      List<dynamic> list = [];
      if (res.data is List) {
        list = res.data;
      } else if (res.data is Map && res.data['data'] is List) {
        list = res.data['data'];
      } else {
        debugPrint('GHN Provinces: Unexpected data format → ${res.data.runtimeType}');
        return [];
      }

      return list
          .where((e) => e is Map<String, dynamic>)
          .map((e) => GhnProvince.fromJson(e))
          .toList();
    } catch (e, s) {
      debugPrint('GHN Provinces Error: $e\n$s');
      return [];
    }
  }

  /// GET /api/rookie/shipping/districts?provinceId=...
  Future<List<GhnDistrict>> getDistricts(int provinceId) async {
    try {
      final res = await _dio.get(
        '/api/rookie/shipping/districts',
        queryParameters: {'provinceId': provinceId},
      );

      if (res.data == null || res.data is! List) {
        final dynamic maybeList = res.data is Map ? res.data['data'] : null;
        if (maybeList is List) {
          return maybeList
              .map((e) => GhnDistrict.fromJson((e as Map).cast<String, dynamic>()))
              .toList();
        }
        return [];
      }

      return (res.data as List)
          .map((e) => GhnDistrict.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (e, s) {
      debugPrint('GHN Districts Error: $e\n$s');
      return [];
    }
  }

  /// GET /api/rookie/shipping/wards?districtId=...
  Future<List<GhnWard>> getWards(int districtId) async {
    try {
      final res = await _dio.get(
        '/api/rookie/shipping/wards',
        queryParameters: {'districtId': districtId},
      );

      if (res.data == null || res.data is! List) {
        final dynamic maybeList = res.data is Map ? res.data['data'] : null;
        if (maybeList is List) {
          return maybeList
              .map((e) => GhnWard.fromJson((e as Map).cast<String, dynamic>()))
              .toList();
        }
        return [];
      }

      return (res.data as List)
          .map((e) => GhnWard.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (e, s) {
      debugPrint('GHN Wards Error: $e\n$s');
      return [];
    }
  }

  Future<GhnShippingFee> calculateFee(GhnShippingFeeRequestDTO request) async {
    try {
      final res = await _dio.post(
        '/api/rookie/shipping/calculate-fee',
        data: request.toJson(),
        options: Options(contentType: Headers.jsonContentType),
      );

      if (res.data is! Map<String, dynamic>) {
        throw Exception('Invalid response format from server');
      }

      return GhnShippingFee.fromJson(res.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }
}