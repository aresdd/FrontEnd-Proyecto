import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../models/models.dart';
import '../../services/calbalance_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_fmt.dart';
import '../../widgets/charts/nutrition_charts.dart';
import '../../widgets/section_header.dart';
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      DailyNutritionSummaryResponse? n;
      try {
        n = await _api.summaryDay(dateIso: _iso);
      } catch (_) {
        n = null;
      }
      if (!mounted) return;
      DailySummaryResponse? m;
      try {
        m = await _api.mealsDaySummary(_iso);
      } catch (_) {
        m = null;
      }
      if (mounted) {
        setState(() {
          _nutrition = n;
          _mealsDay = m;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: scheme.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.skyDark.withValues(alpha: 0.45),
                        AppColors.darkSurfaceVariant,
                      ]
                    : [
                        AppColors.skyLight,
                        Colors.white,
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
            ),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen del día',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _iso,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: _pickDate,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.calendar_month_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_loading) LinearProgressIndicator(color: scheme.primary, minHeight: 3),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _error!,
                style: TextStyle(color: scheme.error),
              ),
            ),
          if (_nutrition != null) ...[
            SectionHeader(
              title: 'Energía y macros',
              subtitle: 'Objetivo frente a lo registrado hoy',
              icon: Icons.pie_chart_outline_rounded,
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CalorieGoalRing(n: _nutrition!),
                    const SizedBox(height: 8),
                    MacroProgressStrip(n: _nutrition!),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    MacroCompareBars(n: _nutrition!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _macroDetailCard(_nutrition!),
          ],
          if (_nutrition == null && !_loading && _error == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sin datos de nutrición para este día. Configura un objetivo que cubra la fecha y registra comidas.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_mealsDay != null) ...[
            SectionHeader(
              title: 'Comidas del día',
              subtitle:
                  'Total kcal ${_mealsDay!.totals.calories?.toStringAsFixed(0) ?? '-'}',
              icon: Icons.restaurant_menu_rounded,
            ),
            if (_mealsDay!.meals.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Sin comidas este día',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            ..._mealsDay!.meals.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: scheme.primary.withValues(alpha: 0.15),
                      foregroundColor: scheme.primary,
                      child: const Icon(Icons.restaurant_rounded, size: 20),
                    ),
                    title: Text(
                      row.mealType ?? 'Comida',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${row.calories?.toStringAsFixed(0) ?? '-'} kcal',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
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
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _macroDetailCard(DailyNutritionSummaryResponse n) {
    Widget row(String label, MacroBlock b) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Text(
                'kcal ${b.calories?.toStringAsFixed(0) ?? '-'} · '
                'P ${b.protein?.toStringAsFixed(0) ?? '-'} · '
                'C ${b.carbs?.toStringAsFixed(0) ?? '-'} · '
                'G ${b.fat?.toStringAsFixed(0) ?? '-'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalle numérico',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            row('Meta', n.goal),
            row('Consumido', n.consumed),
            row('Restante', n.remaining),
            const Divider(height: 24),
            Text(
              'Progreso respecto a la meta · kcal ${n.progress.calories?.toStringAsFixed(1) ?? '-'}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
