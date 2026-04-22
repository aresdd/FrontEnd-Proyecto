import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';
import 'session_store.dart';

class ApiClient {
  ApiClient({
    String? baseUrl,
    SessionStore? sessionStore,
    http.Client? httpClient,
  })  : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _session = sessionStore ?? SessionStore(),
        _http = httpClient ?? http.Client();

  final String baseUrl;
  final SessionStore _session;
  final http.Client _http;

  SessionStore get session => _session;

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers({required bool auth}) async {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (auth) {
      final t = await _session.getToken();
      if (t != null && t.isNotEmpty) {
        h['Authorization'] = 'Bearer $t';
      }
    }
    return h;
  }

  void _throwIfBad(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw ApiException(r.statusCode, r.body);
    }
  }

  Future<http.Response> get(
    String path, {
    bool auth = true,
    Map<String, String>? query,
  }) async {
    final r = await _http.get(
      _uri(path, query),
      headers: await _headers(auth: auth),
    );
    _throwIfBad(r);
    return r;
  }

  Future<http.Response> post(
    String path, {
    bool auth = true,
    Object? body,
  }) async {
    final r = await _http.post(
      _uri(path),
      headers: await _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    _throwIfBad(r);
    return r;
  }

  Future<http.Response> patch(
    String path, {
    bool auth = true,
    Object? body,
  }) async {
    final r = await _http.patch(
      _uri(path),
      headers: await _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    _throwIfBad(r);
    return r;
  }

  Future<http.Response> delete(
    String path, {
    bool auth = true,
  }) async {
    final r = await _http.delete(
      _uri(path),
      headers: await _headers(auth: auth),
    );
    _throwIfBad(r);
    return r;
  }

  void close() => _http.close();
}
