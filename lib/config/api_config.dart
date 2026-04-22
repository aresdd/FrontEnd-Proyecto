import 'dart:io' show Platform;

/// Base URL for the Spring Boot API (default port 8080).
///
/// Override at build time with `--dart-define=API_BASE_URL=http://...`
///
/// Auto-detected defaults:
/// - Android emulator: `http://10.0.2.2:8080`
/// - Everything else (desktop, iOS sim): `http://127.0.0.1:8080`
/// - Physical device: pass your LAN IP via dart-define.
/// -- desplegado: https://general-production-c671.up.railway.app
/// 
class ApiConfig {
  ApiConfig._();

  static final String baseUrl = const String.fromEnvironment('API_BASE_URL').isNotEmpty
      ? const String.fromEnvironment('API_BASE_URL')
      : _defaultUrl;

  static String get _defaultUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://10.0.2.2:8080';
  }
}
