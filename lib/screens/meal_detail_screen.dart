import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../models/models.dart';
import '../services/calbalance_api.dart';
import '../utils/dialog_controllers.dart';
import '../widgets/add_meal_item_dialog.dart';

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
      final m = await _api.mealsGetById(widget.mealId);
      if (mounted) setState(() => _meal = m);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      if (g == null) return;
      await _api.mealItemsUpdateGrams(item.id!, g);
      if (mounted) _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      scheduleDisposeTextControllers([ctrl]);
    }
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
        title: Text('Comida #${widget.mealId}'),
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
                          return Card(
                            child: ListTile(
                              title: Text('food ${it.foodId ?? '-'} · dish ${it.dishId ?? '-'} · ${it.grams ?? '-'} g'),
                              subtitle: Text('kcal ${it.calories?.toStringAsFixed(1) ?? '-'} · P ${it.protein?.toStringAsFixed(1) ?? '-'}'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'e') _editGrams(it);
                                  if (v == 'd') _deleteItem(it);
                                },
                                itemBuilder: (_) => [
                                  if (!isDish)
                                    const PopupMenuItem(value: 'e', child: Text('Gramos')),
                                  const PopupMenuItem(value: 'd', child: Text('Eliminar')),
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
