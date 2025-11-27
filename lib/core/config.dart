class AppConfig {
  final String apiBaseUrl;
  final String env;
  const AppConfig({required this.apiBaseUrl, required this.env});

  factory AppConfig.fromEnv() => AppConfig(
    apiBaseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://192.168.1.201:8081',
    ),
    env: const String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
  );

}
