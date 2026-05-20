import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../models/models.dart';
import '../services/calbalance_api.dart';
import '../utils/dialog_controllers.dart';
import '../widgets/add_meal_item_dialog.dart';
import '../widgets/dish_info_sheet.dart';

String _formatGramsDisplay(double? g) {
  if (g == null) return '-';
  if ((g - g.round()).abs() < 1e-6) return '${g.round()}';
  return g.toStringAsFixed(1);
}

class MealDetailScreen extends StatefulWidget {
  const MealDetailScreen({super.key, required this.mealId});

  final int mealId;

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  late CalBalanceApi _api;
  bool _didInit = false;

  MealResponse? _meal;
  Map<int, DishResponse> _dishesById = {};
  bool _loading = true;
  String? _error;

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
      final mealFuture = _api.mealsGetById(widget.mealId);
      final dishesFuture = _api.dishesList();
      final m = await mealFuture;
      final dishes = await dishesFuture;
      if (!mounted) return;
      final byId = <int, DishResponse>{};
      for (final d in dishes) {
        final id = d.id;
        if (id != null) byId[id] = d;
      }
      setState(() {
        _meal = m;
        _dishesById = byId;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDishInfo(MealItemResponse item) {
    final id = item.dishId;
    if (id == null) return;
    final dish = _dishesById[id];
    if (dish == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el plato. Tira para actualizar.')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DishInfoSheet(dish: dish, mealPortion: item),
    );
  }

  Future<void> _addItem() async {
    if (!mounted) return;
    final result = await showDialog<AddMealItemResult?>(
      context: context,
      builder: (ctx) => AddMealItemDialog(api: _api),
    );
    if (result == null || !mounted) return;
    try {
      await _api.mealItemsCreate(
        mealId: widget.mealId,
        foodId: result.foodId,
        dishId: result.dishId,
        grams: result.grams,
      );
      if (mounted) _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _editGrams(MealItemResponse item) async {
    if (!mounted || item.id == null) return;
    final ctrl = TextEditingController(text: item.grams?.toString() ?? '');
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Actualizar gramos'),
          content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Gramos')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      final g = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
      if (g == null || g <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Introduce una cantidad en gramos mayor que 0.')),
          );
        }
        return;
      }
      await _api.mealItemsUpdateGrams(item.id!, g);
      if (mounted) _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      scheduleDisposeTextControllers([ctrl]);
    }
  }

  String _appBarTitle() {
    if (_loading) return 'Comida';
    final m = _meal;
    if (m == null) return 'Comida';
    final type = m.mealType?.trim();
    final date = m.mealDate?.trim();
    final parts = <String>[];
    if (type != null && type.isNotEmpty) parts.add(type);
    if (date != null && date.isNotEmpty) parts.add(date);
    return parts.isEmpty ? 'Comida' : parts.join(' · ');
  }

  Future<void> _deleteItem(MealItemResponse item) async {
    if (!mounted || item.id == null) return;
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminar ítem'),
          content: const Text('¿Seguro?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      await _api.mealItemsDelete(item.id!);
      if (mounted) _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle()),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addItem, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!, textAlign: TextAlign.center)))
              : _meal == null
                  ? const Center(child: Text('Sin datos'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('${_meal!.mealType ?? ''} · ${_meal!.mealDate ?? ''}', style: Theme.of(context).textTheme.titleLarge),
                        if (_meal!.totals != null) ...[
                          const SizedBox(height: 8),
                          Text('Totales: kcal ${_meal!.totals!.calories?.toStringAsFixed(1) ?? '-'} · P ${_meal!.totals!.protein?.toStringAsFixed(1) ?? '-'} · C ${_meal!.totals!.carbs?.toStringAsFixed(1) ?? '-'} · G ${_meal!.totals!.fat?.toStringAsFixed(1) ?? '-'}'),
                        ],
                        const Divider(height: 24),
                        if (_meal!.items.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Sin ítems. Pulsa + para añadir.')),
                        ..._meal!.items.map((it) {
                          final isDish = it.dishId != null;
                          final apiDishName = it.dishName?.trim();
                          final apiFoodName = it.foodName?.trim();
                          final dishNameFallback =
                              (isDish && it.dishId != null) ? _dishesById[it.dishId!]?.name?.trim() : null;
                          final label = isDish
                              ? ((apiDishName != null && apiDishName.isNotEmpty)
                                  ? apiDishName
                                  : (dishNameFallback != null && dishNameFallback.isNotEmpty)
                                      ? dishNameFallback
                                      : 'Plato')
                              : ((apiFoodName != null && apiFoodName.isNotEmpty)
                                  ? apiFoodName
                                  : 'Alimento');
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                isDish ? Icons.dinner_dining_rounded : Icons.restaurant_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text('$label · ${_formatGramsDisplay(it.grams)} g'),
                              subtitle: Text(
                                'kcal ${it.calories?.toStringAsFixed(1) ?? '-'} · P ${it.protein?.toStringAsFixed(1) ?? '-'} · C ${it.carbs?.toStringAsFixed(1) ?? '-'} · G ${it.fat?.toStringAsFixed(1) ?? '-'}',
                              ),
                              onTap: isDish ? () => _showDishInfo(it) : null,
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded),
                                onSelected: (v) {
                                  if (v == 'e') _editGrams(it);
                                  if (v == 'd') _deleteItem(it);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'e', child: Text('Editar gramos')),
                                  PopupMenuItem(value: 'd', child: Text('Eliminar')),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
    );
  }
}
