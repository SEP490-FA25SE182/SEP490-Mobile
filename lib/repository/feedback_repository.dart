import 'package:dio/dio.dart';
import '../model/feedback.dart';

class FeedbackRepository {
  final Dio _dio;
  FeedbackRepository(this._dio);

  Future<BookFeedback> create(BookFeedback feedback) async {
    final res = await _dio.post(
      '/api/rookie/users/feedbacks',
      data: feedback.toJson(),
    );
    return BookFeedback.fromJson(res.data);
  }

  Future<BookFeedback> update(String id, BookFeedback feedback) async {
    final res = await _dio.put(
      '/api/rookie/users/feedbacks/$id',
      data: feedback.toJson(),
    );
    return BookFeedback.fromJson(res.data);
  }

  Future<BookFeedback> getById(String id) async {
    final res = await _dio.get('/api/rookie/users/feedbacks/$id');
    return BookFeedback.fromJson(res.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/api/rookie/users/feedbacks/$id');
  }

  /// Search feedbacks with optional filters
  Future<List<BookFeedback>> search({
    int page = 0,
    int size = 20,
    List<String>? sort,
    String? q,
    String? bookId,
    String? userId,
    IsActived? isActived,
    FeedbackStatus? status,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      if (q != null && q.isNotEmpty) 'q': q,
      if (bookId != null) 'bookId': bookId,
      if (userId != null) 'userId': userId,
      if (isActived != null) 'isActived': isActived.name.toUpperCase(),
      if (status != null) 'status': status.name.toUpperCase(),
    };

    final res = await _dio.get(
      '/api/rookie/users/feedbacks',
      queryParameters: params,
    );

    final List items = res.data['content'] ?? [];
    return items
        .map((j) => BookFeedback.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<BookFeedback> updateStatus(String id, FeedbackStatus status) async {
    final res = await _dio.patch(
      '/api/rookie/users/feedbacks/$id/status',
      data: {'status': status.name.toUpperCase()},
    );
    return BookFeedback.fromJson(res.data);
  }
}