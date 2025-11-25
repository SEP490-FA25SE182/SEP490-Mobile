import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/marker.dart';
import '../core/config.dart';

class MarkerRepository {
  final String _apiBaseUrl;

  MarkerRepository(this._apiBaseUrl);
  String get _arBaseUrl {
    if (_apiBaseUrl.contains(':8081')) {
      return _apiBaseUrl.replaceFirst(':8081', ':8083');
    }
    return _apiBaseUrl.replaceFirst(RegExp(r':\d+'), ':8083');
  }

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
