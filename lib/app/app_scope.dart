import 'package:flutter/widgets.dart';

import '../services/api_client.dart';
import '../services/calbalance_api.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.apiClient,
    required this.api,
    required super.child,
  });

  final ApiClient apiClient;
  final CalBalanceApi api;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AppScope oldWidget) {
    return apiClient != oldWidget.apiClient || api != oldWidget.api;
  }
}
