import 'package:dio/dio.dart';
import '../model/answer.dart';

class AnswerRepository {
  final Dio _dio;
  AnswerRepository(this._dio);

  /// GET /api/rookie/answers
  Future<({List<Answer> items, int total})> search({
    String? q,
    String? questionId,
    bool? isCorrect,
    String? isActived,
    int page = 0,
    int size = 20,
    List<String>? sort,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (questionId != null && questionId.trim().isNotEmpty)
        'questionId': questionId.trim(),
      if (isCorrect != null) 'isCorrect': isCorrect,
      if (isActived != null && isActived.trim().isNotEmpty)
        'isActived': isActived.trim(),
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    };

    final res =
    await _dio.get('/api/rookie/answers', queryParameters: params);

    final raw = res.data;
    final list = (raw is Map && raw['content'] is List)
        ? (raw['content'] as List)
        : <dynamic>[];
    final total = (raw is Map && raw['totalElements'] != null)
        ? int.tryParse('${raw['totalElements']}')
        ?? list.length
        : list.length;

    return (
    items: list
        .map((e) => Answer.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
    total: total,
    );
  }

  /// GET /api/rookie/answers/{id}
  Future<Answer> getById(String id) async {
    final res = await _dio.get('/api/rookie/answers/$id');
    return Answer.fromJson((res.data as Map).cast<String, dynamic>());
  }
}
