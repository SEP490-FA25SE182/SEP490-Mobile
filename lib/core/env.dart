class Env {
  static const String _defaultIp = '192.168.1.66';
  static const String _defaultGatewayUrl = 'http://$_defaultIp:8080';
  static const String _defaultUrl = 'http://$_defaultIp:8081';
  static const String _defaultPageServiceUrl = 'http://$_defaultIp:8081';
  static const String _defaultMediaServiceUrl = 'http://$_defaultIp:8082';

  // API Gateway (production)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultUrl,
  );

  // Backend IP
  static const String backendIp = String.fromEnvironment(
    'BACKEND_IP',
    defaultValue: _defaultIp,
  );

  // Environment
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  // Dịch vụ riêng
  static const String pageServiceUrl = String.fromEnvironment(
    'PAGE_SERVICE_URL',
    defaultValue: _defaultPageServiceUrl,
  );

  static const String mediaServiceUrl = String.fromEnvironment(
    'MEDIA_SERVICE_URL',
    defaultValue: _defaultMediaServiceUrl,
  );

  // Helper
  static bool get isProduction => appEnv == 'production';
  static bool get isStaging => appEnv == 'staging';
  static bool get isDevelopment => appEnv == 'development';
}