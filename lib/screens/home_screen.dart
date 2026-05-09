import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../services/calbalance_api.dart';
import 'pages/dishes_page.dart';
import 'pages/foods_page.dart';
import 'pages/goals_page.dart';
import 'pages/meals_page.dart';
import 'pages/patata_page.dart';
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
    _DrawerItem(Icons.insights, 'Resumen día'),
    _DrawerItem(Icons.restaurant, 'Comidas'),
    _DrawerItem(Icons.egg_alt, 'Alimentos'),
    _DrawerItem(Icons.dinner_dining, 'Platos'),
    _DrawerItem(Icons.monitor_weight, 'Progreso'),
    _DrawerItem(Icons.flag, 'Objetivos'),
    _DrawerItem(Icons.person, 'Perfil'),
    _DrawerItem(Icons.science, 'Patata test'),
  ];

  Widget _buildPage() {
    switch (_index) {
      case 0: return SummaryPage(key: ValueKey(_summaryRemountKey));
      case 1: return const MealsPage();
      case 2: return const FoodsPage();
      case 3: return const DishesPage();
      case 4: return const ProgressPage();
      case 5: return const GoalsPage();
      case 6: return ProfilePage(onLogout: widget.onLogout);
      case 7: return const PatataPage();
      default: return SummaryPage(key: ValueKey(_summaryRemountKey));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_items[_index].label),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              try {
                await _api.logout();
              } catch (_) {}
              if (mounted) widget.onLogout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Text('CalBalance', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            for (var i = 0; i < _items.length; i++)
              ListTile(
                leading: Icon(_items[i].icon),
                title: Text(_items[i].label),
                selected: i == _index,
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
      body: _buildPage(),
    );
  }
}

class _DrawerItem {
  const _DrawerItem(this.icon, this.label);
  final IconData icon;
  final String label;
}
