import 'package:dio/dio.dart';
import '../model/bookshelve.dart';
import '../model/book.dart';
import '../core/api_client.dart';

class BookshelveRepository {
  final Dio _dio;
  BookshelveRepository(this._dio);

  /// Fetch paginated list of bookshelves for a user
  Future<List<Bookshelve>> listByUser({
    required String userId,
    int page = 0,
    int size = 20,
    String? searchQuery,
    List<String>? sort,
    String? isActived, // e.g., "ACTIVE" or "INACTIVE"
  }) async {
    try {
      final res = await _dio.get(
        '/api/rookie/users/bookshelves',
        queryParameters: {
          'page': page,
          'size': size,
          if (sort != null && sort.isNotEmpty) 'sort': sort,
          if (searchQuery != null && searchQuery.isNotEmpty) 'q': searchQuery,
          'userId': userId,
          if (isActived != null) 'isActived': isActived,
        },
      );

      final data = res.data;

      if (data is Map<String, dynamic>) {
        final list = (data['content'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(Bookshelve.fromJson)
            .toList();
        return list;
      }

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(Bookshelve.fromJson)
            .toList();
      }

      return const <Bookshelve>[];
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }

  /// Fetch all books belonging to a specific bookshelf
  Future<List<Book>> getBooksByBookshelf({
    required String bookshelfId,
    int page = 0,
    int size = 20,
    List<String>? sort,
  }) async {
    try {
      final res = await _dio.get(
        '/api/rookie/users/bookshelves/$bookshelfId',
        queryParameters: {
          'page': page,
          'size': size,
          if (sort != null && sort.isNotEmpty) 'sort': sort,
        },
      );

      final data = res.data;

      if (data is Map<String, dynamic>) {
        final list = (data['content'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(Book.fromJson)
            .toList();
        return list;
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
