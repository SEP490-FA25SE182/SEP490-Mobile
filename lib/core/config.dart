class AppConfig {
  final String apiBaseUrl;
  final String env;
  final String backendIp;
  final String pageServiceUrl;
  final String mediaServiceUrl;
  final String unityBackendBase;

  const AppConfig({
    required this.apiBaseUrl,
    required this.env,
    required this.backendIp,
    required this.pageServiceUrl,
    required this.mediaServiceUrl,
    required this.unityBackendBase,
  });

  // ==== default ====
  static const String _defaultIp = 'https://backend.arbookrookie.xyz/api/rookie';
  static const String _defaultGatewayUrl = '$_defaultIp:8080';
  static const String _defaultUrl = '$_defaultIp:8081';
  static const String _defaultPageServiceUrl = '$_defaultIp:8081';
  static const String _defaultMediaServiceUrl = '$_defaultIp:8082';
  static const String _defaultUnityBackendBase = '$_defaultIp:8083';

  /// Đọc từ biến môi trường khi build (`--dart-define`)
  factory AppConfig.fromEnv() => AppConfig(
    apiBaseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: _defaultUrl,
    ),
    env: const String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    ),
    backendIp: const String.fromEnvironment(
      'BACKEND_IP',
      defaultValue: _defaultIp,
    ),
    pageServiceUrl: const String.fromEnvironment(
      'PAGE_SERVICE_URL',
      defaultValue: _defaultPageServiceUrl,
    ),
    mediaServiceUrl: const String.fromEnvironment(
      'MEDIA_SERVICE_URL',
      defaultValue: _defaultMediaServiceUrl,
    ),
    unityBackendBase: const String.fromEnvironment(
      'UNITY_BACKEND_BASE',
      defaultValue: _defaultUnityBackendBase,
    ),
  );

  // Helper
  bool get isProduction => env == 'production';
  bool get isStaging => env == 'staging';
  bool get isDevelopment => env == 'development';
}

/// Có thể dùng luôn instance này ở mọi nơi
final AppConfig appConfig = AppConfig.fromEnv();

