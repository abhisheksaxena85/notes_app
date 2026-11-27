/// Where the app talks to. Override per build with
/// `--dart-define=API_BASE_URL=https://...` (e.g. a local backend).
class ApiConfig {
  ApiConfig._();

  static const _productionBaseUrl = 'https://notesapp-production-d43adec7.up.railway.app';

  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    return configured.isNotEmpty ? configured : _productionBaseUrl;
  }
}
