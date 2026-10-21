class ApiConfig {
  static String get serverUrl => 'http://127.0.0.1:8000';
  static String get baseUrl => '$serverUrl/api/v1';

  static const Duration timeout = Duration(seconds: 15);
}
