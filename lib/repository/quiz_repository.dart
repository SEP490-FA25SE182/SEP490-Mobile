import 'package:dio/dio.dart';
import '../model/quiz.dart';
import '../model/quiz_play.dart';

class QuizRepository {
  final Dio _dio;
  QuizRepository(this._dio);

  /// GET /api/rookie/quizzes
  /// Hỗ trợ search + filter + phân trang
  Future<({List<Quiz> items, int total})> search({
    String? q,
    String? chapterId,
    String? isActived,
    int page = 0,
    int size = 20,
    List<String>? sort, // ví dụ: ['title-ASC', 'updatedAt-DESC']
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (chapterId != null && chapterId.trim().isNotEmpty)
        'chapterId': chapterId.trim(),
      if (isActived != null && isActived.trim().isNotEmpty)
        'isActived': isActived.trim(),
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    };

    final res =
    await _dio.get('/api/rookie/quizzes', queryParameters: params);

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
        .map((e) => Quiz.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
    total: total,
    );
  }

  /// GET /api/rookie/quizzes/{id}
  Future<Quiz> getById(String id) async {
    final res = await _dio.get('/api/rookie/quizzes/$id');
    return Quiz.fromJson((res.data as Map).cast<String, dynamic>());
  }

  /// GET /api/rookie/quizzes/{id}/play
  Future<QuizPlay> getPlayData(String id) async {
    final res = await _dio.get('/api/rookie/quizzes/$id/play');
    return QuizPlay.fromJson(
        (res.data as Map).cast<String, dynamic>());
  }

}
