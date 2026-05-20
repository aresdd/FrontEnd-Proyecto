import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app_scope.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_client.dart';
import 'services/calbalance_api.dart';
import 'services/theme_preferences.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: AppColors.neutral100,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.accentRose),
            const SizedBox(height: 12),
            Text(
              'Algo salió mal',
              style: TextStyle(fontSize: 18, color: AppColors.neutral900),
            ),
            const SizedBox(height: 8),
            Text(
              details.exceptionAsString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.neutral600),
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
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final tokenFuture = _client.session.getToken();
    final themeFuture = ThemePreferences.load();
    final token = await tokenFuture;
    final theme = await themeFuture;
    if (!mounted) return;
    setState(() {
      _loggedIn = token != null && token.isNotEmpty;
      _themeMode = theme;
      _checking = false;
    });
  }

  void _onAuthChanged() {
    if (mounted) setState(() => _loggedIn = true);
  }

  void _onLogout() {
    if (mounted) setState(() => _loggedIn = false);
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    ThemePreferences.save(mode);
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
      themeMode: _themeMode,
      onThemeModeChanged: _setThemeMode,
      child: MaterialApp(
        title: 'CalBalance',
        debugShowCheckedModeBanner: false,
        themeMode: _themeMode,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: _checking
            ? Scaffold(
                backgroundColor: AppColors.skyLight,
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.skyDark),
                ),
              )
            : _loggedIn
                ? HomeScreen(onLogout: _onLogout)
                : LoginScreen(onLoggedIn: _onAuthChanged),
      ),
    );
  }
}
