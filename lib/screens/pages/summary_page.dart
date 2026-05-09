import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../models/models.dart';
import '../../services/calbalance_api.dart';
import '../../utils/date_fmt.dart';
import '../meal_detail_screen.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  late CalBalanceApi _api;
  bool _didInit = false;

  DateTime _date = DateTime.now();
  DailyNutritionSummaryResponse? _nutrition;
  DailySummaryResponse? _mealsDay;
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
      DailyNutritionSummaryResponse? n;
      try { n = await _api.summaryDay(dateIso: _iso); } catch (_) { n = null; }
      if (!mounted) return;
      DailySummaryResponse? m;
      try { m = await _api.mealsDaySummary(_iso); } catch (_) { m = null; }
      if (mounted) setState(() { _nutrition = n; _mealsDay = m; });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2020), lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: Text('Resumen $_iso', style: Theme.of(context).textTheme.titleLarge)),
            IconButton(onPressed: _pickDate, icon: const Icon(Icons.calendar_today)),
          ]),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          if (_nutrition != null) ...[
            const SizedBox(height: 12),
            Text('Objetivo vs consumido', style: Theme.of(context).textTheme.titleMedium),
            _macroTable(_nutrition!),
          ],
          if (_nutrition == null && !_loading && _error == null)
            const Padding(padding: EdgeInsets.all(16), child: Text('Sin datos de nutrición. Crea un objetivo y añade comidas.')),
          if (_mealsDay != null) ...[
            const Divider(height: 32),
            Text('Comidas del día', style: Theme.of(context).textTheme.titleMedium),
            Text('Totales día: kcal ${_mealsDay!.totals.calories?.toStringAsFixed(0) ?? '-'}'),
            if (_mealsDay!.meals.isEmpty)
              const Padding(padding: EdgeInsets.all(16), child: Text('Sin comidas hoy')),
            ..._mealsDay!.meals.map((row) => ListTile(
              title: Text(row.mealType ?? 'Comida'),
              subtitle: Text('kcal ${row.calories?.toStringAsFixed(0) ?? '-'} · id ${row.mealId}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: row.mealId == null
                  ? null
                  : () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => MealDetailScreen(mealId: row.mealId!),
                        ),
                      );
                      if (mounted) _load();
                    },
            )),
          ],
        ],
      ),
    );
  }

  Widget _macroTable(DailyNutritionSummaryResponse n) {
    Widget row(String label, MacroBlock b) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text('$label · kcal ${b.calories?.toStringAsFixed(0) ?? '-'} · P ${b.protein?.toStringAsFixed(0) ?? '-'} · C ${b.carbs?.toStringAsFixed(0) ?? '-'} · G ${b.fat?.toStringAsFixed(0) ?? '-'}'),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          row('Meta', n.goal),
          row('Consumido', n.consumed),
          row('Restante', n.remaining),
          const Divider(),
          Text('Progreso % · kcal ${n.progress.calories?.toStringAsFixed(1) ?? '-'}'),
        ]),
      ),
    );
  }
}
