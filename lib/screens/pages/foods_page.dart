import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../models/models.dart';
import '../../services/calbalance_api.dart';
import '../../utils/dialog_controllers.dart';

class FoodsPage extends StatefulWidget {
  const FoodsPage({super.key});

  @override
  State<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends State<FoodsPage> {
  late CalBalanceApi _api;

  final _query = TextEditingController();
  List<FoodsResponse> _results = [];
  bool _searching = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api = AppScope.of(context).api;
  }

  Future<void> _search() async {
    if (!mounted) return;
    final q = _query.text.trim();
    if (q.isEmpty) { setState(() => _results = []); return; }
    setState(() { _searching = true; _error = null; });
    try {
      final list = await _api.foodsSearch(q);
      if (mounted) setState(() => _results = list);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _createFood() async {
    if (!mounted) return;
    final name = TextEditingController();
    final brand = TextEditingController();
    final cal = TextEditingController(text: '100');
    final prot = TextEditingController(text: '10');
    final carb = TextEditingController(text: '10');
    final fat = TextEditingController(text: '5');

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Crear alimento'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: brand, decoration: const InputDecoration(labelText: 'Marca (opcional)')),
              TextField(controller: cal, decoration: const InputDecoration(labelText: 'kcal/100g'), keyboardType: TextInputType.number),
              TextField(controller: prot, decoration: const InputDecoration(labelText: 'proteína/100g'), keyboardType: TextInputType.number),
              TextField(controller: carb, decoration: const InputDecoration(labelText: 'carbos/100g'), keyboardType: TextInputType.number),
              TextField(controller: fat, decoration: const InputDecoration(labelText: 'grasa/100g'), keyboardType: TextInputType.number),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
          ],
        ),
      );

      if (ok != true || !mounted) return;

      final n = name.text.trim();
      final brandStr = brand.text.trim();
      final c = double.tryParse(cal.text.replaceAll(',', '.'));
      final p = double.tryParse(prot.text.replaceAll(',', '.'));
      final cb = double.tryParse(carb.text.replaceAll(',', '.'));
      final f = double.tryParse(fat.text.replaceAll(',', '.'));

      if (n.isEmpty || c == null || p == null || cb == null || f == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos inválidos')));
        return;
      }

      await _api.foodsCreate(name: n, brand: brandStr.isEmpty ? null : brandStr, caloriesPer100g: c, proteinPer100g: p, carbsPer100g: cb, fatPer100g: f);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alimento creado')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      scheduleDisposeTextControllers([name, brand, cal, prot, carb, fat]);
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: TextField(controller: _query, decoration: const InputDecoration(labelText: 'Buscar alimentos', border: OutlineInputBorder()), onSubmitted: (_) => _search())),
            const SizedBox(width: 8),
            FilledButton(onPressed: _searching ? null : _search, child: const Text('Buscar')),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: OutlinedButton.icon(onPressed: _createFood, icon: const Icon(Icons.add), label: const Text('Crear alimento')),
        ),
        if (_searching) const LinearProgressIndicator(),
        if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (_, i) {
              final f = _results[i];
              return ListTile(
                title: Text(f.name ?? ''),
                subtitle: Text('id ${f.id} · ${f.source ?? ''} · kcal/100g ${f.caloriesPer100g ?? '-'}'),
              );
            },
          ),
        ),
      ],
    );
  }
}
