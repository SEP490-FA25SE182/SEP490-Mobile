import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../model/audio.dart';

class AudioRepository {
  final Dio _dio;
  AudioRepository(this._dio);

  /// GET /api/rookie/audios/{id}
  Future<AudioModel> getById(String audioId) async {
    try {
      final response = await _dio.get('/api/rookie/audios/$audioId');
      return AudioModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('AudioRepo error: $e');
      rethrow;
    }
  }

  /// Tối ưu: Lấy nhiều audio cùng lúc
  Future<Map<String, AudioModel>> getManyByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final results = await Future.wait(
      ids.map((id) => getById(id).catchError((_) => null)),
      eagerError: false,
    );
    final map = <String, AudioModel>{};
    for (var i = 0; i < ids.length; i++) {
      if (results[i] != null) {
        map[ids[i]] = results[i] as AudioModel;
      }
    }
    return map;
  }
}