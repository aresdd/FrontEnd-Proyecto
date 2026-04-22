import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/calbalance_api.dart';
import 'food_search_picker.dart';

class AddMealItemResult {
  const AddMealItemResult({this.foodId, this.dishId, required this.grams})
      : assert(foodId != null || dishId != null, 'food or dish required');

  final int? foodId;
  final int? dishId;
  final double grams;
}

enum _ItemKind { food, dish }

class AddMealItemDialog extends StatefulWidget {
  const AddMealItemDialog({super.key, required this.api});

  final CalBalanceApi api;

  @override
  State<AddMealItemDialog> createState() => _AddMealItemDialogState();
}

class _AddMealItemDialogState extends State<AddMealItemDialog> {
  _ItemKind _kind = _ItemKind.food;

  final _gramsCtrl = TextEditingController(text: '100');
  final _dishFilterCtrl = TextEditingController();

  List<DishResponse> _dishes = [];
  bool _dishesLoading = false;
  String? _dishesError;

  FoodsResponse? _pickedFood;
  DishResponse? _pickedDish;

  @override
  void initState() {
    super.initState();
    _loadDishes();
    _dishFilterCtrl.addListener(_onDishFilterChanged);
  }

  void _onDishFilterChanged() {
    if (_kind == _ItemKind.dish) setState(() {});
  }

  Future<void> _loadDishes() async {
    setState(() {
      _dishesLoading = true;
      _dishesError = null;
    });
    try {
      final list = await widget.api.dishesList();
      if (mounted) setState(() => _dishes = list);
    } catch (e) {
      if (mounted) setState(() => _dishesError = '$e');
    } finally {
      if (mounted) setState(() => _dishesLoading = false);
    }
  }

  List<DishResponse> get _filteredDishes {
    final q = _dishFilterCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _dishes;
    return _dishes.where((d) {
      final n = (d.name ?? '').toLowerCase();
      final desc = (d.description ?? '').toLowerCase();
      return n.contains(q) || desc.contains(q);
    }).toList();
  }

  void _submit() {
    if (_kind == _ItemKind.food) {
      final g = double.tryParse(_gramsCtrl.text.trim().replaceAll(',', '.'));
      if (g == null || g <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Indica gramos válidos')),
        );
        return;
      }
      final id = _pickedFood?.id;
      if (id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Elige un alimento de la lista')),
        );
        return;
      }
      Navigator.of(context).pop(AddMealItemResult(foodId: id, grams: g));
    } else {
      final dish = _pickedDish;
      final id = dish?.id;
      if (id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Elige un plato de la lista')),
        );
        return;
      }
      final total = dish!.totalGrams;
      if (total == null || total <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay peso total del plato. Actualiza la lista (pull) o el servidor.'),
          ),
        );
        return;
      }
      Navigator.of(context).pop(AddMealItemResult(dishId: id, grams: total));
    }
  }

  @override
  void dispose() {
    _dishFilterCtrl.removeListener(_onDishFilterChanged);
    _gramsCtrl.dispose();
    _dishFilterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Añadir ítem', style: theme.textTheme.titleLarge),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<_ItemKind>(
                segments: const [
                  ButtonSegment(
                    value: _ItemKind.food,
                    label: Text('Alimento'),
                    icon: Icon(Icons.egg_alt_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: _ItemKind.dish,
                    label: Text('Plato'),
                    icon: Icon(Icons.restaurant_menu_outlined, size: 18),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (s) {
                  setState(() {
                    _kind = s.first;
                    _pickedFood = null;
                    _pickedDish = null;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _kind == _ItemKind.food ? _buildFoodPane() : _buildDishPane(theme)),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_kind == _ItemKind.food)
                    TextField(
                      controller: _gramsCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Gramos',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    )
                  else
                    _DishGramsHint(
                      picked: _pickedDish,
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _submit,
                        child: const Text('Añadir'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodPane() {
    return FoodSearchPicker(
      api: widget.api,
      selected: _pickedFood,
      onSelectionChanged: (f) => setState(() => _pickedFood = f),
    );
  }

  Widget _buildDishPane(ThemeData theme) {
    if (_dishesLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    }
    if (_dishesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_dishesError!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: _loadDishes, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _dishFilterCtrl,
            decoration: const InputDecoration(
              labelText: 'Filtrar platos',
              hintText: 'Nombre…',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.filter_list, size: 20),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _loadDishes,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Actualizar lista'),
            ),
          ),
          Expanded(
            child: _filteredDishes.isEmpty
                ? Center(
                    child: Text(
                      _dishes.isEmpty
                          ? 'No tienes platos. Créalos en la pestaña Platos.'
                          : 'Ningún plato coincide con el filtro.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredDishes.length,
                    itemBuilder: (_, i) {
                      final d = _filteredDishes[i];
                      final id = d.id;
                      final selected = id != null && _pickedDish?.id == id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        color: selected ? theme.colorScheme.primaryContainer.withOpacity(0.35) : null,
                        child: ListTile(
                          title: Text(d.name ?? ''),
                          subtitle: Text(
                            [
                              if (d.totalGrams != null && d.totalGrams! > 0)
                                '${_fmtGrams(d.totalGrams!)} g totales',
                              'kcal ${d.calories?.toStringAsFixed(0) ?? '-'} · P ${d.protein?.toStringAsFixed(0) ?? '-'}',
                            ].join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: selected ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
                          onTap: id == null ? null : () => setState(() => _pickedDish = d),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String _fmtGrams(double g) {
  if ((g - g.round()).abs() < 1e-6) return g.round().toString();
  return g.toStringAsFixed(1);
}

class _DishGramsHint extends StatelessWidget {
  const _DishGramsHint({required this.picked});

  final DishResponse? picked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = picked?.totalGrams;
    final text = picked == null
        ? 'El plato se añade con el peso total definido por la suma de sus ingredientes (no se puede cambiar aquí).'
        : total != null && total > 0
            ? 'Se añadirá el plato completo: ${_fmtGrams(total)} g (suma de ingredientes). Los macros usan esa porción.'
            : 'Este plato no tiene gramos totales en el servidor. Actualiza la app o vuelve a cargar la lista de platos.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
