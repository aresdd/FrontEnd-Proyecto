import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app_scope.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_client.dart';
import 'services/calbalance_api.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Algo salió mal',
              style: TextStyle(fontSize: 18, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              details.exceptionAsString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  };

  runZonedGuarded(
    () => runApp(const CalBalanceApp()),
    (error, stack) {
      debugPrint('Unhandled: $error\n$stack');
    },
  );
}

class CalBalanceApp extends StatefulWidget {
  const CalBalanceApp({super.key});

  @override
  State<CalBalanceApp> createState() => _CalBalanceAppState();
}

class _CalBalanceAppState extends State<CalBalanceApp> {
  late final ApiClient _client = ApiClient();
  late final CalBalanceApi _api = CalBalanceApi(_client);
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final t = await _client.session.getToken();
    if (mounted) {
      setState(() {
        _loggedIn = t != null && t.isNotEmpty;
        _checking = false;
      });
    }
  }

  void _onAuthChanged() {
    if (mounted) setState(() => _loggedIn = true);
  }

  void _onLogout() {
    if (mounted) setState(() => _loggedIn = false);
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      apiClient: _client,
      api: _api,
      child: MaterialApp(
        title: 'CalBalance',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: _checking
            ? const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              )
            : _loggedIn
                ? HomeScreen(onLogout: _onLogout)
                : LoginScreen(onLoggedIn: _onAuthChanged),
      ),
    );
  }
}
