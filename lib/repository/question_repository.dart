import 'package:dio/dio.dart';
import '../model/question.dart';

class QuestionRepository {
  final Dio _dio;
  QuestionRepository(this._dio);

  /// GET /api/rookie/questions
  Future<({List<Question> items, int total})> search({
    String? q,
    String? quizId,
    String? isActived,
    int page = 0,
    int size = 20,
    List<String>? sort,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (quizId != null && quizId.trim().isNotEmpty)
        'quizId': quizId.trim(),
      if (isActived != null && isActived.trim().isNotEmpty)
        'isActived': isActived.trim(),
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    };

    final res =
    await _dio.get('/api/rookie/questions', queryParameters: params);

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
        .map((e) => Question.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
    total: total,
    );
  }

  /// GET /api/rookie/questions/{id}
  Future<Question> getById(String id) async {
    final res = await _dio.get('/api/rookie/questions/$id');
    return Question.fromJson((res.data as Map).cast<String, dynamic>());
  }
}
