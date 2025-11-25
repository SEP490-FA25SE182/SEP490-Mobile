import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../model/page.dart';

class PageRepository {
  final Dio _dio;

  PageRepository(this._dio);

  /// GET /api/rookie/users/books/pages
  /// Supports: pagination, sort, search (q), chapterId, isActived
  Future<List<PageModel>> list({
    int page = 0,
    int size = 20,
    List<String>? sort,
    String? search,
    String? chapterId,
    String? isActived, // "ACTIVE" or "INACTIVE"
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'size': size,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        if (search != null && search.isNotEmpty) 'q': search,
        if (chapterId != null && chapterId.isNotEmpty) 'chapterId': chapterId,
        if (isActived != null && isActived.isNotEmpty) 'isActived': isActived,
      };

      final response = await _dio.get(
        '/api/rookie/users/books/pages',
        queryParameters: queryParameters,
      );

      final data = response.data;

      // Spring Data Page<PageResponseDTO>
      if (data is Map<String, dynamic>) {
        final content = data['content'] as List? ?? [];
        return content
            .whereType<Map<String, dynamic>>()
            .map(PageModel.fromJson)
            .toList();
      }

      // Fallback: direct list
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(PageModel.fromJson)
            .toList();
      }

      return const [];
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }

  /// GET /api/rookie/users/books/pages/{id}
  Future<PageModel> getById(String pageId) async {
    try {
      final response = await _dio.get('/api/rookie/users/books/pages/$pageId');
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return PageModel.fromJson(data);
      }

      throw Exception('Invalid page data received');
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }

  /// POST /api/rookie/users/books/pages
  Future<PageModel> create(PageModel page) async {
    try {
      final response = await _dio.post(
        '/api/rookie/users/books/pages',
        data: page.toJson(),
      );
      return PageModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }

  /// PUT /api/rookie/users/books/pages/{id}
  Future<PageModel> update(String pageId, PageModel page) async {
    try {
      final response = await _dio.put(
        '/api/rookie/users/books/pages/$pageId',
        data: page.toJson(),
      );
      return PageModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }

  /// DELETE /api/rookie/users/books/pages/{id} → soft delete
  Future<void> softDelete(String pageId) async {
    try {
      await _dio.delete('/api/rookie/users/books/pages/$pageId');
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }

  /// Convenience: Get all pages of a chapter, sorted by pageNumber
  Future<List<PageModel>> getByChapterId(
      String chapterId, {
        int page = 0,
        int size = 1000,
        List<String> sort = const ['pageNumber-asc'],
      }) async {
    return list(
      chapterId: chapterId,
      page: page,
      size: size,
      sort: sort,
    );
  }

}