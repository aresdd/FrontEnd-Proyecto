import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/calbalance_api.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.apiClient,
    required this.api,
    required this.themeMode,
    required this.onThemeModeChanged,
    required super.child,
  });

  final ApiClient apiClient;
  final CalBalanceApi api;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AppScope oldWidget) {
    return apiClient != oldWidget.apiClient ||
        api != oldWidget.api ||
        themeMode != oldWidget.themeMode ||
        onThemeModeChanged != oldWidget.onThemeModeChanged;
  }
}
