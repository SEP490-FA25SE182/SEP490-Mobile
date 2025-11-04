import 'package:dio/dio.dart';
import '../model/bookshelve.dart';
import '../core/api_client.dart';

class BookshelveRepository {
  final Dio _dio;
  BookshelveRepository(this._dio);

  Future<List<Bookshelve>> listByUser(String userId) async {
    try {
      final res = await _dio.get('/api/rookie/users/$userId/bookshelves');
      final data = res.data;

      if (data is List) {
        return data
            .map((e) => Bookshelve.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (data is Map<String, dynamic>) {
        final list = (data['content'] as List? ?? [])
            .map((e) => Bookshelve.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }

      return const <Bookshelve>[];
    } on DioException catch (e) {
      mapDioError(e);
      rethrow;
    }
  }
}
