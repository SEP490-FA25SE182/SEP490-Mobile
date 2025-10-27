import 'package:dio/dio.dart';
import '../model/vn_location.dart';

class VnLocationRepository {
  final Dio _dio;
  VnLocationRepository(this._dio);

  Future<List<VnProvince>> fetchAll() async {
    final res = await _dio.get('https://provinces.open-api.vn/api/', queryParameters: {'depth': 3});
    final data = (res.data as List).cast<Map<String, dynamic>>();
    return data.map((e) => VnProvince.fromJson(e)).toList();
  }
}
