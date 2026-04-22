import 'dart:convert';

class ApiException implements Exception {
  ApiException(this.statusCode, this.body);

  final int? statusCode;
  final String body;

  /// Best-effort server message (JSON `message` / `detail` / `error` / `title`, else raw body).
  String get message {
    try {
      final j = jsonDecode(body);
      if (j is Map<String, dynamic>) {
        for (final key in ['message', 'detail', 'error', 'title']) {
          final v = j[key]?.toString().trim();
          if (v != null && v.isNotEmpty) return v;
        }
      }
    } catch (_) {}
    return body;
  }

  /// Short text for SnackBars and dialogs. [403] uses Spanish copy and server context when useful.
  String get userMessageEs {
    if (statusCode == 403) {
      return _forbiddenMessageEs(body);
    }
    return _genericErrorString();
  }

  String _genericErrorString() {
    final code = statusCode ?? '?';
    final msg = message;
    final short = msg.length > 300 ? '${msg.substring(0, 300)}...' : msg;
    return 'Error $code: $short';
  }

  @override
  String toString() => userMessageEs;
}

String _forbiddenMessageEs(String body) {
  final ctx = _meaningfulForbiddenDetail(body);
  if (ctx == null) {
    return 'No tienes permiso para realizar esta acción.';
  }
  final mapped = _translateForbiddenContext(ctx);
  if (mapped != null) return mapped;
  if (_looksLikelySpanish(ctx)) {
    final s = ctx.length > 220 ? '${ctx.substring(0, 217)}…' : ctx;
    return s;
  }
  final snippet = ctx.length > 140 ? '${ctx.substring(0, 137)}…' : ctx;
  return 'No tienes permiso para esta acción. Detalle: $snippet';
}

bool _isNoiseForbiddenToken(String? v) {
  if (v == null) return true;
  final s = v.trim();
  if (s.isEmpty) return true;
  final low = s.toLowerCase();
  return low == 'forbidden' || s == '403' || low == 'unauthorized';
}

/// Returns a non-empty hint from the response when it adds context beyond a bare 403.
String? _meaningfulForbiddenDetail(String body) {
  final t = body.trim();
  if (t.isEmpty) return null;
  if (t.startsWith('<!') || t.toLowerCase().startsWith('<html')) return null;

  try {
    final decoded = jsonDecode(t);
    if (decoded is Map<String, dynamic>) {
      String? take(String key) {
        final v = decoded[key]?.toString().trim();
        if (v == null || v.isEmpty) return null;
        if (_isNoiseForbiddenToken(v)) return null;
        return v;
      }

      return take('message') ?? take('detail') ?? take('title') ?? take('error');
    }
  } catch (_) {
    if (_isNoiseForbiddenToken(t)) return null;
    return t;
  }
  return null;
}

String? _translateForbiddenContext(String ctx) {
  final l = ctx.toLowerCase();

  if (l.contains('user is disabled') ||
      l.contains('account is disabled') ||
      l.contains('account has been disabled') ||
      l.contains('usuario deshabilitado') ||
      l.contains('cuenta desactivada')) {
    return 'Esta cuenta está desactivada. No puedes usar la app hasta que se reactive.';
  }
  if (l.contains('inactive') && (l.contains('user') || l.contains('account'))) {
    return 'Esta cuenta no está activa.';
  }
  if (l.contains('access denied') || l.contains('access is denied')) {
    return 'Acceso denegado. No tienes permiso para esta acción.';
  }
  if (l.contains('full authentication is required') ||
      l.contains('not authenticated') ||
      l.contains('anonymous')) {
    return 'Tu sesión ha caducado o no estás autenticado. Inicia sesión de nuevo.';
  }
  if (l.contains('token') && (l.contains('expired') || l.contains('invalid') || l.contains('malformed'))) {
    return 'El token de acceso no es válido o ha caducado. Inicia sesión de nuevo.';
  }
  if (l.contains('csrf')) {
    return 'La petición fue rechazada por seguridad. Prueba a cerrar sesión y volver a entrar.';
  }
  if (l.contains('insufficient') && l.contains('privilege')) {
    return 'No tienes privilegios suficientes para esta acción.';
  }
  return null;
}

bool _looksLikelySpanish(String s) {
  final l = s.toLowerCase();
  return s.contains('ñ') ||
      s.contains('Ñ') ||
      l.contains(' sesión') ||
      l.contains('sesión') ||
      l.contains(' permiso') ||
      l.contains('permiso') ||
      l.contains('cuenta') ||
      l.contains('inicia sesión') ||
      l.contains('autentic');
}
