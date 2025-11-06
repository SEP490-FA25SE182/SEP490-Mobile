import 'package:dio/dio.dart';
import '../model/notification.dart';
import '../../core/api_client.dart';

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  Future<List<AppNotification>> list({
    required String userId,
    int page = 0,
    int size = 50,
    String sort = 'createdAt-desc',
  }) async {
    final res = await _dio.get(
      '/api/rookie/notifications',
      queryParameters: {
        'userId': userId,
        'page': page,
        'size': size,
        'sort': [sort],
      },
    );

    final data = res.data;
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> markAsRead(String id) async {
    await _dio.patch('/api/rookie/notifications/$id/read');
  }
}
