import 'package:dio/dio.dart';
import '../model/blog.dart';

enum UpdatedOrder { latest, oldest }

String _orderToQuery(UpdatedOrder o) => o == UpdatedOrder.oldest ? 'OLDEST' : 'LATEST';

class BlogRepository {
  final Dio _dio;
  BlogRepository(this._dio);

  /// GET /api/rookie/blogs/search/user?q=...
  Future<({List<Blog> items, int total})> searchForUser({
    required String q,
    int page = 0,
    int size = 20,
  }) async {
    final res = await _dio.get(
      '/api/rookie/blogs/search/user',
      queryParameters: {
        if (q.trim().isNotEmpty) 'q': q.trim(),
        'page': page,
        'size': size,
      },
    );

    final raw = res.data;
    final list = (raw is Map && raw['content'] is List)
        ? (raw['content'] as List)
        : <dynamic>[];
    final total = (raw is Map && raw['totalElements'] != null)
        ? int.tryParse('${raw['totalElements']}') ?? list.length
        : list.length;

    return (
    items: list.map((e) => Blog.fromJson((e as Map).cast<String, dynamic>())).toList(),
    total: total,
    );
  }


  /// GET /api/rookie/blogs/filter?order=LATEST|OLDEST
  Future<({List<Blog> items, int total})> filterByUpdated({
    UpdatedOrder order = UpdatedOrder.latest,
    int page = 0,
    int size = 20,
  }) async {
    final res = await _dio.get('/api/rookie/blogs/filter', queryParameters: {
      'order': _orderToQuery(order),
      'page': page,
      'size': size,
    });

    final raw = res.data;
    final list = (raw is Map && raw['content'] is List) ? (raw['content'] as List) : <dynamic>[];
    final total = (raw is Map && raw['totalElements'] != null) ? int.tryParse('${raw['totalElements']}') ?? list.length : list.length;

    return (
    items: list.map((e) => Blog.fromJson((e as Map).cast<String, dynamic>())).toList(),
    total: total,
    );
  }

  /// GET /api/rookie/blogs/{id}
  Future<Blog> getById(String id) async {
    final res = await _dio.get('/api/rookie/blogs/$id');
    return Blog.fromJson((res.data as Map).cast<String, dynamic>());
  }
}
