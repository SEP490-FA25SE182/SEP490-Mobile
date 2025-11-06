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
    String? isActived,
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
        '/api/rookie/users/books/bookshelves/$bookshelfId',
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

  /// Check if a book exists in the newest bookshelf of a user
  Future<bool> isBookInFavorite(String userId, String bookId) async {
    try {
      final newestShelf = await getNewestByUser(userId);
      if (newestShelf == null || (newestShelf.bookshelveId?.isEmpty ?? true)) {
        return false;
      }

      final shelfId = newestShelf.bookshelveId!;
      final books = await getBooksByBookshelf(bookshelfId: shelfId);
      return books.any((b) => b.bookId == bookId);
    } catch (_) {
      return false;
    }
  }

  /// Add a book to a bookshelf
  Future<void> addBookToShelf({
    required String bookId,
    required String bookshelfId,
  }) async {
    try {
      await _dio.post(
        '/api/rookie/users/books/$bookId/bookshelves',
        data: [bookshelfId],
        options: Options(contentType: Headers.jsonContentType),
      );
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }

  /// Remove a book from a bookshelf
  Future<void> removeBookFromShelf({
    required String bookId,
    required String bookshelfId,
  }) async {
    try {
      await _dio.delete(
        '/api/rookie/users/books/$bookId/bookshelves/$bookshelfId',
      );
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }

  /// Fetch newest bookshelf for a user
  Future<Bookshelve?> getNewestByUser(String userId) async {
    try {
      final res = await _dio.get(
        '/api/rookie/users/bookshelves',
        queryParameters: {
          'userId': userId,
          'page': 0,
          'size': 1,
          'sort': ['createdAt-desc'], // newest first
        },
      );

      final data = res.data;
      if (data is Map<String, dynamic>) {
        final list = (data['content'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(Bookshelve.fromJson)
            .toList();
        return list.isNotEmpty ? list.first : null;
      }
      return null;
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }
}
