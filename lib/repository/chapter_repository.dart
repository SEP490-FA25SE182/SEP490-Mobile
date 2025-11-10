import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../model/chapter.dart';
import '../model/page.dart';

class ChapterRepository {
  final Dio _dio;

  ChapterRepository(this._dio);

  /// GET /api/rookie/users/books/chapters
  /// Supports: pagination, sort, search (q), bookId, publicationStatus, progressStatus, isActived
  Future<List<Chapter>> list({
    int page = 0,
    int size = 20,
    List<String>? sort,
    String? search,
    String? bookId,
    int? publicationStatus, // Byte → int
    int? progressStatus,    // Byte → int
    String? isActived,      // "ACTIVE" / "INACTIVE"
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'size': size,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        if (search != null && search.isNotEmpty) 'q': search,
        if (bookId != null && bookId.isNotEmpty) 'bookId': bookId,
        if (publicationStatus != null) 'publicationStatus': publicationStatus,
        if (progressStatus != null) 'progressStatus': progressStatus,
        if (isActived != null && isActived.isNotEmpty) 'isActived': isActived,
      };

      final response = await _dio.get(
        '/api/rookie/users/books/chapters',
        queryParameters: queryParameters,
      );

      final data = response.data;

      // Backend returns Spring Page<ChapterResponseDTO>
      if (data is Map<String, dynamic>) {
        final content = data['content'] as List? ?? [];
        return content
            .whereType<Map<String, dynamic>>()
            .map((e) => Chapter.fromJson(e))
            .toList();
      }

      // Fallback: if direct list (unlikely but safe)
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((e) => Chapter.fromJson(e))
            .toList();
      }

      return const [];
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }

  /// GET /api/rookie/users/books/chapters/{id}
  Future<Chapter> getById(String chapterId) async {
    try {
      final response = await _dio.get('/api/rookie/users/books/chapters/$chapterId');
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return Chapter.fromJson(data);
      }

      throw Exception('Invalid chapter data received');
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }

  /// POST /api/rookie/users/books/chapters
  Future<Chapter> create(Chapter chapter) async {
    try {
      final response = await _dio.post(
        '/api/rookie/users/books/chapters',
        data: chapter.toJson(),
      );
      return Chapter.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }

  /// PUT /api/rookie/users/books/chapters/{id}
  Future<Chapter> update(String chapterId, Chapter chapter) async {
    try {
      final response = await _dio.put(
        '/api/rookie/users/books/chapters/$chapterId',
        data: chapter.toJson(),
      );
      return Chapter.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }

  /// DELETE /api/rookie/users/books/chapters/{id} → soft delete
  Future<void> softDelete(String chapterId) async {
    try {
      await _dio.delete('/api/rookie/users/books/chapters/$chapterId');
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }

  /// Convenience: Get chapters by bookId (commonly used)
  Future<List<Chapter>> getByBookId(
      String bookId, {
        int page = 0,
        int size = 100,
        List<String> sort = const ['chapterNumber-asc'],
      }) async {
    return list(
      bookId: bookId,
      page: page,
      size: size,
      sort: sort,
    );
  }

  /// Convenience: Get chapter information by chapterId (commonly used)
  Future<List<PageModel>> getPagesByChapterId(String chapterId) async {
    try {
      final response = await _dio.get(
        '/api/rookie/users/books/chapters/$chapterId/pages',
      );

      final data = response.data;

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((json) => PageModel.fromJson(json))
            .toList();
      }

      throw Exception('Invalid pages data');
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }
}