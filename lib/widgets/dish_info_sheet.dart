import 'package:flutter/material.dart';

import '../models/models.dart';

String _g(double? v) {
  if (v == null) return '-';
  if ((v - v.round()).abs() < 1e-6) return '${v.round()}';
  return v.toStringAsFixed(1);
}

/// Bottom sheet: recipe (ingredients + base totals) and macros for this meal portion.
class DishInfoSheet extends StatelessWidget {
  const DishInfoSheet({
    super.key,
    required this.dish,
    required this.mealPortion,
  });

  final DishResponse dish;
  final MealItemResponse mealPortion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final desc = dish.description?.trim();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.dinner_dining_rounded, color: scheme.primary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dish.name ?? 'Plato',
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (desc != null && desc.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(desc, style: tt.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 20),
            Text('Receta completa', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Total receta: ${_g(dish.totalGrams)} g · kcal ${_g(dish.calories)} · P ${_g(dish.protein)} · C ${_g(dish.carbs)} · G ${_g(dish.fat)}',
              style: tt.bodyMedium,
            ),
            if (dish.ingredients.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Ingredientes', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...dish.ingredients.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(line.foodName ?? 'Alimento', style: tt.bodyMedium),
                      ),
                      Text('${_g(line.grams)} g', style: tt.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ],
            const Divider(height: 32),
            Text('En esta comida', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Porción: ${_g(mealPortion.grams)} g',
              style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              'kcal ${_g(mealPortion.calories)} · P ${_g(mealPortion.protein)} · C ${_g(mealPortion.carbs)} · G ${_g(mealPortion.fat)}',
              style: tt.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
