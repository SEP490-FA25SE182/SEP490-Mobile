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
    List<String>? genreIds,
    double? minPrice,
    double? maxPrice,
    String? authorId,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'size': size,
        'sort': sort,
        'publicationStatus': 1,
        'isActived': 'ACTIVE',

        if (search != null && search.trim().isNotEmpty)
          'q': search.trim(),

        if (genreIds != null && genreIds.isNotEmpty)
          for (final id in genreIds) 'genreId': id,

        if (minPrice != null && minPrice > 0) 'minPrice': minPrice,
        if (maxPrice != null && maxPrice > 0) 'maxPrice': maxPrice,
        if (authorId != null && authorId.isNotEmpty) 'authorId': authorId,
      };

      final res = await _dio.get(
        '/api/rookie/users/books',
        queryParameters: query,
      );

      final data = res.data;

      if (data is List) {
        return data
            .map((e) => Book.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (data is Map<String, dynamic>) {
        final content = data['content'] as List? ?? [];
        return content
            .map((e) => Book.fromJson(e as Map<String, dynamic>))
            .toList();
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
        queryParameters: {'sort': 'updatedAt-desc', 'size': limit, 'page': 0, 'publicationStatus': 1, 'isActived': 'ACTIVE',},
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
        final book = Book.fromJson(data);

        if (book.isActived?.toUpperCase() != 'ACTIVE') {
          throw Exception('Sách không còn hoạt động');
        }
        return book;
      }

      throw Exception('Dữ liệu sách không hợp lệ');
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }

  Future<List<Book>> getBooksByShelfId(
      String shelfId, {
        int page = 0,
        int size = 20,
        List<String>? sort,
      }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        'isActived': 'ACTIVE',
      };

      final res = await _dio.get(
        '/api/rookie/users/books/bookshelves/$shelfId',
        queryParameters: queryParams,
      );

      final data = res.data;
      if (data is Map<String, dynamic>) {
        final content = data['content'] as List? ?? [];
        return content
            .whereType<Map<String, dynamic>>()
            .map(Book.fromJson)
            .toList();
      }
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(Book.fromJson)
            .toList();
      }
      return const <Book>[];
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }

}
