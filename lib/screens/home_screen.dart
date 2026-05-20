import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../services/calbalance_api.dart';
import '../theme/app_colors.dart';
import 'pages/dishes_page.dart';
import 'pages/foods_page.dart';
import 'pages/goals_page.dart';
import 'pages/meals_page.dart';
import 'pages/profile_page.dart';
import 'pages/progress_page.dart';
import 'pages/summary_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late CalBalanceApi _api;
  int _index = 0;
  /// Bumped whenever the user opens "Resumen día" so [SummaryPage] remounts and reloads data.
  int _summaryRemountKey = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api = AppScope.of(context).api;
  }

  static const _items = <_DrawerItem>[
    _DrawerItem(Icons.insights_rounded, 'Resumen día'),
    _DrawerItem(Icons.restaurant_rounded, 'Comidas'),
    _DrawerItem(Icons.egg_alt_rounded, 'Alimentos'),
    _DrawerItem(Icons.dinner_dining_rounded, 'Platos'),
    _DrawerItem(Icons.monitor_weight_rounded, 'Progreso'),
    _DrawerItem(Icons.flag_rounded, 'Objetivos'),
    _DrawerItem(Icons.person_rounded, 'Perfil'),
  ];

  Widget _buildPage() {
    switch (_index) {
      case 0:
        return SummaryPage(key: ValueKey(_summaryRemountKey));
      case 1:
        return const MealsPage();
      case 2:
        return const FoodsPage();
      case 3:
        return const DishesPage();
      case 4:
        return const ProgressPage();
      case 5:
        return const GoalsPage();
      case 6:
        return ProfilePage(onLogout: widget.onLogout);
      default:
        return SummaryPage(key: ValueKey(_summaryRemountKey));
    }
  }

  void _toggleTheme() {
    final scope = AppScope.of(context);
    final next = scope.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    scope.onThemeModeChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_items[_index].label),
        actions: [
          IconButton(
            tooltip: 'Modo claro / oscuro',
            onPressed: _toggleTheme,
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              try {
                await _api.logout();
              } catch (_) {}
              if (mounted) widget.onLogout();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [AppColors.skyDark, AppColors.darkSurface]
                      : [AppColors.sky, AppColors.skyDark],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CalBalance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nutrición y hábitos',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    ListTile(
                      leading: Icon(
                        _items[i].icon,
                        color: i == _index ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                      title: Text(_items[i].label),
                      selected: i == _index,
                      selectedColor: scheme.primary,
                      selectedTileColor: scheme.primary.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: () {
                        Navigator.of(context).pop();
                        setState(() {
                          if (i == 0) _summaryRemountKey++;
                          _index = i;
                        });
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              title: const Text('Modo oscuro'),
              trailing: Switch.adaptive(
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: (v) {
                  AppScope.of(context).onThemeModeChanged(
                    v ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              ),
              onTap: _toggleTheme,
            ),
          ],
        ),
      ),
      body: _buildPage(),
    );
  }
}

class _DrawerItem {
  const _DrawerItem(this.icon, this.label);
  final IconData icon;
  final String label;
}
