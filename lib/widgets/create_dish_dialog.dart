import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/calbalance_api.dart';
import 'food_search_picker.dart';

class DishIngredientEntry {
  const DishIngredientEntry({required this.foodId, required this.grams});

  final int foodId;
  final double grams;
}

class CreateDishResult {
  const CreateDishResult({
    required this.name,
    this.description,
    required this.ingredients,
  });

  final String name;
  final String? description;
  final List<DishIngredientEntry> ingredients;
}

class _DraftLine {
  _DraftLine(this.food, {required String gramsText}) : gramsCtrl = TextEditingController(text: gramsText);

  final FoodsResponse food;
  final TextEditingController gramsCtrl;

  void dispose() => gramsCtrl.dispose();
}

class CreateDishDialog extends StatefulWidget {
  const CreateDishDialog({super.key, required this.api});

  final CalBalanceApi api;

  @override
  State<CreateDishDialog> createState() => _CreateDishDialogState();
}

class _CreateDishDialogState extends State<CreateDishDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addGramsCtrl = TextEditingController(text: '100');

  final List<_DraftLine> _lines = [];

  FoodsResponse? _stagingFood;

  double get _totalGrams {
    var sum = 0.0;
    for (final line in _lines) {
      final g = double.tryParse(line.gramsCtrl.text.trim().replaceAll(',', '.'));
      if (g != null && g > 0) sum += g;
    }
    return sum;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addGramsCtrl.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _addStagingLine() {
    final food = _stagingFood;
    final id = food?.id;
    if (food == null || id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige un alimento en la lista')),
      );
      return;
    }
    final g = double.tryParse(_addGramsCtrl.text.trim().replaceAll(',', '.'));
    if (g == null || g <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica gramos válidos para añadir')),
      );
      return;
    }
    final text = g == g.roundToDouble() ? g.round().toString() : g.toString();
    setState(() {
      _lines.add(_DraftLine(food, gramsText: text));
      _stagingFood = null;
    });
  }

  void _removeLine(int index) {
    setState(() {
      final line = _lines.removeAt(index);
      line.dispose();
    });
  }

  void _submit() {
    final n = _nameCtrl.text.trim();
    if (n.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica un nombre')),
      );
      return;
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos un ingrediente')),
      );
      return;
    }
    final ingredients = <DishIngredientEntry>[];
    for (final line in _lines) {
      final id = line.food.id;
      if (id == null) continue;
      final g = double.tryParse(line.gramsCtrl.text.trim().replaceAll(',', '.'));
      if (g == null || g <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gramos inválidos: ${line.food.name ?? "alimento"}')),
        );
        return;
      }
      ingredients.add(DishIngredientEntry(foodId: id, grams: g));
    }
    if (ingredients.length != _lines.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa los ingredientes')),
      );
      return;
    }
    final d = _descCtrl.text.trim();
    Navigator.of(context).pop(CreateDishResult(
      name: n,
      description: d.isEmpty ? null : d,
      ingredients: ingredients,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(child: Text('Nuevo plato', style: theme.textTheme.titleLarge)),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ingredientes (${_lines.length})',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    'Total plato: ${_totalGrams % 1 == 0 ? _totalGrams.round().toString() : _totalGrams.toStringAsFixed(1)} g',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: _lines.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Aún no hay ingredientes. Busca abajo, elige uno y pulsa «Añadir».',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _lines.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final line = _lines[i];
                        final food = line.food;
                        return Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        food.name ?? '',
                                        style: theme.textTheme.titleSmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if ((food.brand ?? '').isNotEmpty)
                                        Text(
                                          food.brand!,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 88,
                                  child: TextField(
                                    controller: line.gramsCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'g',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeLine(i),
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Quitar',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Añadir ingrediente', style: theme.textTheme.titleSmall),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: FoodSearchPicker(
                      api: widget.api,
                      selected: _stagingFood,
                      onSelectionChanged: (f) => setState(() => _stagingFood = f),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addGramsCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Gramos (esta porción)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _addStagingLine,
                          child: const Text('Añadir'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _submit, child: const Text('Crear')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
