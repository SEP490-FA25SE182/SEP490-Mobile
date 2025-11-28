import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../model/page_audio.dart';

class PageAudioRepository {
  final Dio _dio;
  PageAudioRepository(this._dio);

  /// GET /api/rookie/page-audios/search?pageId=xxx
  Future<List<PageAudioModel>> getByPageId(String pageId) async {
    try {
      final response = await _dio.get(
        '/api/rookie/page-audios/search',
        queryParameters: {
          'pageId': pageId,
          'size': 100,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['content'] is List) {
        return (data['content'] as List)
            .map((e) => PageAudioModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('PageAudioRepo error: $e');
      rethrow;
    }
  }
}