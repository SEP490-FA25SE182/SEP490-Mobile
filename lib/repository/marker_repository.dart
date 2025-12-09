import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/marker.dart';
import '../core/config.dart';

class MarkerRepository {
  final String _baseUrl;

  MarkerRepository(this._baseUrl);
  String get _arBaseUrl =>
      _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;

  /// Gọi /api/rookie/markers/search?pageId=...&page=0&size=1
  /// Trả về marker đầu tiên hoặc null nếu không có.
  Future<MarkerModel?> findFirstByPageId(String pageId) async {
    final uri = Uri.parse('$_arBaseUrl/api/rookie/markers/search').replace(
      queryParameters: {
        'pageId': pageId,
        'page': '0',
        'size': '1',
      },
    );

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception(
          'Lỗi gọi search marker: HTTP ${res.statusCode} - ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final content = (data['content'] as List?) ?? const [];

    if (content.isEmpty) return null;

    final first = content.first as Map<String, dynamic>;
    return MarkerModel.fromJson(first);
  }
}

/// tiện nếu bạn muốn tạo sẵn 1 instance dùng chung
MarkerRepository createMarkerRepositoryFromEnv() {
  final config = AppConfig.fromEnv();
  return MarkerRepository(config.apiBaseUrl);
}
