import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../model/genre.dart';

class GenreRepository {
  final Dio _dio;
  GenreRepository(this._dio);

  /// Lấy danh sách tất cả thể loại
  Future<List<Genre>> list({
    int page = 0,
    int size = 50,
    String sort = 'createdAt-desc',
  }) async {
    try {
      final res = await _dio.get(
        '/api/rookie/genres',
        queryParameters: {
          'page': page,
          'size': size,
          'sort': sort,
        },
      );

      final data = res.data;

      // Trường hợp backend trả về List
      if (data is List) {
        return data
            .map((e) => Genre.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Trường hợp backend trả về Page object
      if (data is Map<String, dynamic>) {
        final list = (data['content'] as List? ?? [])
            .map((e) => Genre.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }

      return const <Genre>[];
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }

  /// Lấy thông tin chi tiết 1 thể loại theo ID
  Future<Genre> getById(String id) async {
    try {
      final res = await _dio.get('/api/rookie/genres/$id');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return Genre.fromJson(data);
      }
      throw Exception('Dữ liệu thể loại không hợp lệ');
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }
}
