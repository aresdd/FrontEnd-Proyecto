import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_colors.dart';

/// Line chart of body weight over time (uses [BodyProgressResponse.recordedAt] order).
class WeightLineChart extends StatelessWidget {
  const WeightLineChart({super.key, required this.entries});

  final List<BodyProgressResponse> entries;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pts = <({DateTime d, double w})>[];
    for (final e in entries) {
      final w = e.weightKg;
      if (w == null) continue;
      final d = DateTime.tryParse(e.recordedAt ?? '');
      if (d == null) continue;
      pts.add((d: d, w: w));
    }
    pts.sort((a, b) => a.d.compareTo(b.d));
    if (pts.length < 2) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          pts.isEmpty
              ? 'Añade al menos dos registros con peso para ver la tendencia.'
              : 'Necesitas más registros para dibujar la curva.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      );
    }

    final spots = <FlSpot>[];
    double minY = pts.first.w;
    double maxY = pts.first.w;
    for (var i = 0; i < pts.length; i++) {
      final w = pts[i].w;
      spots.add(FlSpot(i.toDouble(), w));
      if (w < minY) minY = w;
      if (w > maxY) maxY = w;
    }
    final pad = (maxY - minY) * 0.15;
    if (pad == 0) {
      minY -= 1;
      maxY += 1;
    } else {
      minY -= pad;
      maxY += pad;
    }

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: 12, top: 12, left: 4),
        child: LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY - minY) / 4,
              getDrawingHorizontalLine: (v) => FlLine(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (v, m) => Text(
                    v.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, m) {
                    final i = v.round();
                    if (i < 0 || i >= pts.length) return const SizedBox.shrink();
                    if (pts.length > 6 && i != 0 && i != pts.length - 1) {
                      return const SizedBox.shrink();
                    }
                    final d = pts[i].d;
                    final label = '${d.day}/${d.month}';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: scheme.primary,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.sky,
                    strokeWidth: 2,
                    strokeColor: scheme.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.25),
                      scheme.primary.withValues(alpha: 0.02),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
