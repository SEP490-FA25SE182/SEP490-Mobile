import 'package:dio/dio.dart';
import '../model/quiz_result.dart';

class UserQuizResultRepository {
  final Dio _dio;
  UserQuizResultRepository(this._dio);

  /// GET /api/rookie/books/user-quiz-results
  Future<({List<UserQuizResult> items, int total})> search({
    String? quizId,
    String? userId,
    bool? isComplete,
    bool? isReward,
    String? isActived,
    int page = 0,
    int size = 20,
    List<String>? sort,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
      if (quizId != null && quizId.trim().isNotEmpty)
        'quizId': quizId.trim(),
      if (userId != null && userId.trim().isNotEmpty)
        'userId': userId.trim(),
      if (isComplete != null) 'isComplete': isComplete,
      if (isReward != null) 'isReward': isReward,
      if (isActived != null && isActived.trim().isNotEmpty)
        'isActived': isActived.trim(),
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    };

    final res = await _dio.get(
      '/api/rookie/books/user-quiz-results',
      queryParameters: params,
    );

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
        .map((e) =>
        UserQuizResult.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
    total: total,
    );
  }

  /// GET /api/rookie/books/user-quiz-results/{id}
  Future<UserQuizResult> getById(String id) async {
    final res =
    await _dio.get('/api/rookie/books/user-quiz-results/$id');
    return UserQuizResult.fromJson(
        (res.data as Map).cast<String, dynamic>());
  }

  /// POST /api/rookie/books/user-quiz-results/submit
  ///
  /// body backend mong đợi:
  /// {
  ///   "quizId": "...",
  ///   "userId": "...",
  ///   "answers": [
  ///     {
  ///       "questionId": "...",
  ///       "answerIds": ["...", "..."]
  ///     }
  ///   ]
  /// }
  Future<UserQuizResult> submitQuiz({
    required String quizId,
    required String userId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final body = {
      'quizId': quizId,
      'userId': userId,
      'answers': answers,
    };

    final res = await _dio.post(
      '/api/rookie/books/user-quiz-results/submit',
      data: body,
    );

    return UserQuizResult.fromJson(
        (res.data as Map).cast<String, dynamic>());
  }
}
