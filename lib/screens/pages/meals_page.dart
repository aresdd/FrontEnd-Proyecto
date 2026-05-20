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
    setState(() {
      _loading = true;
      _error = null;
    });
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
            decoration: const InputDecoration(
              labelText: 'Tipo (ej. DESAYUNO, COMIDA, CENA)',
              prefixIcon: Icon(Icons.restaurant_rounded),
            ),
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
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.12),
                  scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comidas del día',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        _iso,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _createMeal,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nueva'),
                ),
                IconButton(
                  tooltip: 'Elegir fecha',
                  onPressed: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (p != null && mounted) {
                      setState(() => _date = p);
                      _load();
                    }
                  },
                  icon: const Icon(Icons.calendar_month_rounded),
                ),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                  ),
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
        ),
        if (_loading) LinearProgressIndicator(color: scheme.primary, minHeight: 3),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_error!, style: TextStyle(color: scheme.error)),
          ),
        Expanded(
          child: RefreshIndicator(
            color: scheme.primary,
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (_day != null && _day!.meals.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Total día · ${_day!.totals.calories?.toStringAsFixed(0) ?? '-'} kcal',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                if (_day != null)
                  ..._day!.meals.map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: scheme.primary.withValues(alpha: 0.12),
                            foregroundColor: scheme.primary,
                            child: const Icon(Icons.restaurant_rounded, size: 20),
                          ),
                          title: Text(
                            row.mealType ?? 'Comida',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${row.calories?.toStringAsFixed(0) ?? '-'} kcal',
                          ),
                          trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                          onTap: row.mealId == null
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => MealDetailScreen(mealId: row.mealId!),
                                    ),
                                  );
                                },
                        ),
                      ),
                    ),
                  ),
                if (_day == null && !_loading && _error == null)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Sin comidas hoy. Crea una.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
