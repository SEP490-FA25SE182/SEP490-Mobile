import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../model/genre.dart';

class GenreRepository {
  final Dio _dio;
  GenreRepository(this._dio);


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

      if (data is List) {
        return data.map((e) => Genre.fromJson(e as Map<String, dynamic>)).toList();
      }

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


  Future<List<Genre>> listByBook({
    required String bookId,
    int page = 0,
    int size = 20,
    List<String>? sort,
    String? keyword,
  }) async {
    try {
      final res = await _dio.get(
        '/api/rookie/users/genres',
        queryParameters: {
          'page': page,
          'size': size,
          if (sort != null && sort.isNotEmpty) 'sort': sort,
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          'bookId': bookId,
        },
      );

      final data = res.data;

      if (data is Map<String, dynamic>) {
        final list = (data['content'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(Genre.fromJson)
            .toList();
        return list;
      }

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(Genre.fromJson)
            .toList();
      }

      return const <Genre>[];
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }

}
