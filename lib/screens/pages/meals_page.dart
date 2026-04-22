import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../models/models.dart';
import '../../services/calbalance_api.dart';
import '../../utils/date_fmt.dart';
import '../../utils/dialog_controllers.dart';
import '../meal_detail_screen.dart';

class MealsPage extends StatefulWidget {
  const MealsPage({super.key});

  @override
  State<MealsPage> createState() => _MealsPageState();
}

class _MealsPageState extends State<MealsPage> {
  late CalBalanceApi _api;
  bool _didInit = false;

  DateTime _date = DateTime.now();
  DailySummaryResponse? _day;
  bool _loading = false;
  String? _error;

  String get _iso => toIsoDate(_date);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api = AppScope.of(context).api;
    if (!_didInit) {
      _didInit = true;
      Future.microtask(() => _load());
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final d = await _api.mealsDaySummary(_iso);
      if (mounted) setState(() => _day = d);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createMeal() async {
    if (!mounted) return;
    final typeCtrl = TextEditingController(text: 'DESAYUNO');
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nueva comida'),
          content: TextField(
            controller: typeCtrl,
            decoration: const InputDecoration(labelText: 'Tipo (ej. DESAYUNO, COMIDA, CENA)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Crear')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      final mealType = typeCtrl.text.trim();
      if (mealType.isEmpty) return;

      final created = await _api.mealsCreate(mealType: mealType, mealDateIso: _iso);
      if (!mounted) return;
      await _load();
      if (created.id != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => MealDetailScreen(mealId: created.id!)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      scheduleDisposeTextControllers([typeCtrl]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(child: Text('Día: $_iso', style: Theme.of(context).textTheme.titleMedium)),
              FilledButton.tonalIcon(
                onPressed: _createMeal,
                icon: const Icon(Icons.add),
                label: const Text('Nueva'),
              ),
              IconButton(
                onPressed: () async {
                  final p = await showDatePicker(
                    context: context, initialDate: _date,
                    firstDate: DateTime(2020), lastDate: DateTime(2100),
                  );
                  if (p != null && mounted) { setState(() => _date = p); _load(); }
                },
                icon: const Icon(Icons.date_range),
              ),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (_day != null)
                  ..._day!.meals.map((row) => ListTile(
                    title: Text(row.mealType ?? 'Comida'),
                    subtitle: Text('id ${row.mealId}'),
                    onTap: row.mealId == null ? null : () {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => MealDetailScreen(mealId: row.mealId!),
                      ));
                    },
                  )),
                if (_day == null && !_loading && _error == null)
                  const Padding(padding: EdgeInsets.all(24), child: Text('Sin comidas hoy. Crea una.')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
