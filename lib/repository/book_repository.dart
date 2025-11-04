import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../model/book.dart';

class BookRepository {
  final Dio _dio;
  BookRepository(this._dio);

  Future<List<Book>> list({
    int page = 0,
    int size = 20,
    String sort = 'createdAt-desc',
    String? search,
    String? genreId,
  }) async {
    try {
      final query = {
        'page': page,
        'size': size,
        'sort': sort,
        if (search != null && search.isNotEmpty) 'q': search,
        if (genreId != null && genreId.isNotEmpty) 'genreId': genreId,
      };

      final res = await _dio.get(
        '/api/rookie/users/books',
        queryParameters: query,
      );

      final data = res.data;
      if (data is List) {
        return data.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (data is Map<String, dynamic>) {
        final list = (data['content'] as List? ?? [])
            .map((e) => Book.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      return const <Book>[];
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }



  Future<List<Book>> newestBooks({int limit = 5}) async {
    try {
      final res = await _dio.get(
        '/api/rookie/users/books',
        queryParameters: {'sort': 'updatedAt-desc', 'size': limit, 'page': 0},
      );

      final data = res.data;
      if (data is List) {
        return data.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (data is Map<String, dynamic>) {
        final list = (data['content'] as List? ?? [])
            .map((e) => Book.fromJson(e as Map<String, dynamic>))
            .toList();
        return list.take(limit).toList();
      }
      return const <Book>[];
    } on DioException catch (e) {
      mapDioError(e);
      return const <Book>[];
    }
  }


  Future<Book> getById(String id) async {
    try {
      final res = await _dio.get('/api/rookie/users/books/$id');

      final data = res.data;
      if (data is Map<String, dynamic>) {
        return Book.fromJson(data);
      }

      throw Exception('Dữ liệu sách không hợp lệ');
    } on DioException catch (e) {
      mapDioError(e);
      rethrow; // để FutureProvider biết lỗi
    }
  }

  Future<List<Book>> getBooksByShelfId(String shelfId, {int page = 0, int size = 20, List<String>? sort}) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        if (sort != null && sort.isNotEmpty) 'sort': sort,
      };

      final res = await _dio.get(
        '/api/rookie/users/books/bookshelves/$shelfId',
        queryParameters: queryParams,
      );

      final data = res.data;
      if (data is Map<String, dynamic>) {
        final content = data['content'] as List? ?? [];
        return content.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
      }

      return const <Book>[];
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }

}
