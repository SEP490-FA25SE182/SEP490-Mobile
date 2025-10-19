import 'package:shared_preferences/shared_preferences.dart';

class SecureStore {
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  Future<String?> readAccessToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kAccess);
    // Khi chuyển sang flutter_secure_storage: đọc từ secure storage
  }

  Future<void> writeTokens({required String access, String? refresh}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAccess, access);
    if (refresh != null) await sp.setString(_kRefresh, refresh);
  }

  Future<String?> readRefreshToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kRefresh);
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kAccess);
    await sp.remove(_kRefresh);
  }

  /// Demo: giả lập refresh — thực tế hãy gọi API refresh của bạn
  Future<String?> tryRefreshToken() async {
    final rt = await readRefreshToken();
    if (rt == null) return null;
    // TODO: call /auth/refresh -> lấy access mới
    // Tạm: giả lập
    final newAccess = 'access_${DateTime.now().millisecondsSinceEpoch}';
    await writeTokens(access: newAccess, refresh: rt);
    return newAccess;
  }
}
