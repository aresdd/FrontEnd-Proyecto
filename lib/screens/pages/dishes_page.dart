import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../models/models.dart';
import '../../services/calbalance_api.dart';
import '../../widgets/create_dish_dialog.dart';

class DishesPage extends StatefulWidget {
  const DishesPage({super.key});

  @override
  State<DishesPage> createState() => _DishesPageState();
}

class _DishesPageState extends State<DishesPage> {
  late CalBalanceApi _api;
  bool _didInit = false;

  List<DishResponse> _list = [];
  bool _loading = false;
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
      final l = await _api.dishesList();
      if (mounted) setState(() => _list = l);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createDish() async {
    if (!mounted) return;
    final result = await showDialog<CreateDishResult?>(
      context: context,
      builder: (ctx) => CreateDishDialog(api: _api),
    );
    if (result == null || !mounted) return;
    try {
      await _api.dishesCreate(
        name: result.name,
        description: result.description,
        foods: result.ingredients
            .map((e) => {'foodId': e.foodId, 'grams': e.grams})
            .toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plato creado')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            FilledButton.tonalIcon(onPressed: _createDish, icon: const Icon(Icons.add), label: const Text('Nuevo plato')),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ]),
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _list.length,
              itemBuilder: (_, i) {
                final d = _list[i];
                return ListTile(
                  title: Text(d.name ?? ''),
                  subtitle: Text('kcal ${d.calories?.toStringAsFixed(0) ?? '-'} · P ${d.protein?.toStringAsFixed(0) ?? '-'} · C ${d.carbs?.toStringAsFixed(0) ?? '-'} · G ${d.fat?.toStringAsFixed(0) ?? '-'}'),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
