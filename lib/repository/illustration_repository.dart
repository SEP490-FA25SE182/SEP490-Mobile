import '../model/illustration.dart';
import 'package:dio/dio.dart';

class IllustrationRepository {
  final Dio _dio;
  IllustrationRepository(this._dio);

  Future<IllustrationModel> getById(String id) async {
    final resp = await _dio.get('/api/rookie/illustrations/$id');
    return IllustrationModel.fromJson(resp.data);
  }

  Future<Map<String, IllustrationModel>> getManyByIds(List<String> ids) async {
    final futures = ids.map((id) => getById(id));
    final results = await Future.wait(futures);
    return {for (var i in results) i.illustrationId: i};
  }
}