import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_colors.dart';

/// Donut-style chart: consumed vs remaining calories toward daily goal.
class CalorieGoalRing extends StatelessWidget {
  const CalorieGoalRing({super.key, required this.n});

  final DailyNutritionSummaryResponse n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final goal = n.goal.calories ?? 0;
    final consumed = n.consumed.calories ?? 0;
    if (goal <= 0) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Sin meta calórica para graficar',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    final remaining = goal - consumed;
    final over = consumed > goal ? consumed - goal : 0.0;
    final inBudget = consumed.clamp(0.0, goal);
    final rest = remaining >= 0 ? remaining : 0.0;

    final sections = <PieChartSectionData>[];
    if (inBudget > 0) {
      sections.add(
        PieChartSectionData(
          value: inBudget,
          title: '${inBudget.round()}',
          color: scheme.primary,
          radius: 52,
          titleStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: scheme.onPrimary,
          ),
        ),
      );
    }
    if (rest > 0) {
      sections.add(
        PieChartSectionData(
          value: rest,
          title: '${rest.round()}',
          color: AppColors.neutral300.withValues(alpha: 0.65),
          radius: 48,
          titleStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      );
    }
    if (over > 0) {
      sections.add(
        PieChartSectionData(
          value: over,
          title: '+${over.round()}',
          color: AppColors.accentRose,
          radius: 52,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          value: 1,
          color: scheme.surfaceContainerHighest,
          radius: 48,
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 44,
                sections: sections,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendDot(
                  color: scheme.primary,
                  label: 'Consumidas',
                  value: '${consumed.round()} kcal',
                ),
                const SizedBox(height: 8),
                _LegendDot(
                  color: AppColors.neutral300.withValues(alpha: 0.8),
                  label: 'Restantes',
                  value: '${remaining.round()} kcal',
                ),
                if (over > 0) ...[
                  const SizedBox(height: 8),
                  _LegendDot(
                    color: AppColors.accentRose,
                    label: 'Sobre meta',
                    value: '${over.round()} kcal',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: t.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text(value, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Grouped bars: goal vs consumed for protein, carbs, fat (grams).
class MacroCompareBars extends StatelessWidget {
  const MacroCompareBars({super.key, required this.n});

  final DailyNutritionSummaryResponse n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rawMax = [
      n.goal.protein ?? 0,
      n.consumed.protein ?? 0,
      n.goal.carbs ?? 0,
      n.consumed.carbs ?? 0,
      n.goal.fat ?? 0,
      n.consumed.fat ?? 0,
    ].fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = rawMax <= 0 ? 10.0 : rawMax * 1.15;

    BarChartGroupData group(int x, double goalV, double consV, Color c) {
      return BarChartGroupData(
        x: x,
        barsSpace: 6,
        barRods: [
          BarChartRodData(
            toY: goalV,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            color: c.withValues(alpha: 0.35),
          ),
          BarChartRodData(
            toY: consV,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            color: c,
          ),
        ],
      );
    }

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: 8, top: 12),
        child: BarChart(
          BarChartData(
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? maxY / 4 : 2.5,
              getDrawingHorizontalLine: (v) => FlLine(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (v, m) => Text(
                    v.round().toString(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, m) {
                    const labels = ['Proteína', 'Carbos', 'Grasa'];
                    final i = v.toInt();
                    if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(labels[i], style: Theme.of(context).textTheme.labelSmall),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              group(0, n.goal.protein ?? 0, n.consumed.protein ?? 0, AppColors.macroProtein),
              group(1, n.goal.carbs ?? 0, n.consumed.carbs ?? 0, AppColors.macroCarbs),
              group(2, n.goal.fat ?? 0, n.consumed.fat ?? 0, AppColors.macroFat),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact stat chips for macro percentages from API.
class MacroProgressStrip extends StatelessWidget {
  const MacroProgressStrip({super.key, required this.n});

  final DailyNutritionSummaryResponse n;

  @override
  Widget build(BuildContext context) {
    final p = n.progress;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(label: 'Kcal', value: p.calories, color: Theme.of(context).colorScheme.primary),
        _Chip(label: 'P', value: p.protein, color: AppColors.macroProtein),
        _Chip(label: 'C', value: p.carbs, color: AppColors.macroCarbs),
        _Chip(label: 'G', value: p.fat, color: AppColors.macroFat),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value, required this.color});

  final String label;
  final double? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final v = value;
    final text = v == null ? '—' : '${v.toStringAsFixed(0)}%';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
