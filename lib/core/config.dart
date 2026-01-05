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
  /*
  static const String _prodBase = 'https://backend.arbookrookie.xyz/api/rookie';
  static const String _defaultIp = '192.168.1.20';
  static const String _defaultGatewayUrl = 'http://$_defaultIp:8080';
  static const String _defaultUrl = 'http://$_defaultIp:8081';
  static const String _defaultPageServiceUrl = 'http://$_defaultIp:8081';
  static const String _defaultMediaServiceUrl = 'http://$_defaultIp:8082';
  static const String _defaultUnityBackendBase = 'http://$_defaultIp:8083';
  */

  static const String _defaultGatewayUrl = 'https://backend.arbookrookie.xyz/api/rookie';
  static const String _defaultUrl = 'https://backend.arbookrookie.xyz/api/rookie';
  static const String _defaultIp = '192.168.1.26';
  static const String _defaultPageServiceUrl = 'https://backend.arbookrookie.xyz/api/rookie';
  static const String _defaultMediaServiceUrl = 'https://backend.arbookrookie.xyz/api/ai';
  static const String _defaultUnityBackendBase = 'https://backend.arbookrookie.xyz/api/ar';


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

