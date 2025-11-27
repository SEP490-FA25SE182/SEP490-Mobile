import '../model/page_illustration.dart';
import 'package:dio/dio.dart';

class PageIllustrationRepository {
  final Dio _dio;

  PageIllustrationRepository(this._dio);

  Future<List<PageIllustrationModel>> getByPageId(String pageId) async {
    final resp = await _dio.get(
      '/api/rookie/page-illustrations/search',
      queryParameters: {'pageId': pageId, 'size': 100},
    );
    final data = resp.data['content'] as List? ?? [];
    return data.map((e) => PageIllustrationModel.fromJson(e)).toList();
  }
}