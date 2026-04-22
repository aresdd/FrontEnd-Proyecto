import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../models/models.dart';
import '../../services/calbalance_api.dart';
import '../../utils/date_fmt.dart';
import '../../utils/dialog_controllers.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  late CalBalanceApi _api;
  bool _didInit = false;

  NutritionGoalResponse? _current;
  bool _loading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api = AppScope.of(context).api;
    if (!_didInit) {
      _didInit = true;
      Future.microtask(() => _loadCurrent());
    }
  }

  Future<void> _loadCurrent() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final g = await _api.goalsCurrent();
      if (mounted) setState(() => _current = g);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    if (!mounted) return;
    final typeCtrl = TextEditingController(text: 'MAINTENANCE');
    final calCtrl = TextEditingController(text: '2000');
    final pCtrl = TextEditingController(text: '120');
    final cCtrl = TextEditingController(text: '200');
    final fCtrl = TextEditingController(text: '60');

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nuevo objetivo'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'goalType')),
              TextField(controller: calCtrl, decoration: const InputDecoration(labelText: 'dailyCalories'), keyboardType: TextInputType.number),
              TextField(controller: pCtrl, decoration: const InputDecoration(labelText: 'proteinG'), keyboardType: TextInputType.number),
              TextField(controller: cCtrl, decoration: const InputDecoration(labelText: 'carbsG'), keyboardType: TextInputType.number),
              TextField(controller: fCtrl, decoration: const InputDecoration(labelText: 'fatG'), keyboardType: TextInputType.number),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Crear')),
          ],
        ),
      );

      if (ok != true || !mounted) return;

      final gt = typeCtrl.text.trim();
      final dc = int.tryParse(calCtrl.text.trim());
      final pg = int.tryParse(pCtrl.text.trim());
      final cg = int.tryParse(cCtrl.text.trim());
      final fg = int.tryParse(fCtrl.text.trim());

      if (gt.isEmpty || dc == null || pg == null || cg == null || fg == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos inválidos')));
        return;
      }

      await _api.goalsCreate(goalType: gt, dailyCalories: dc, proteinG: pg, carbsG: cg, fatG: fg, startDateIso: toIsoDate(DateTime.now()));
      if (mounted) _loadCurrent();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      scheduleDisposeTextControllers([typeCtrl, calCtrl, pCtrl, cCtrl, fCtrl]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadCurrent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          Row(children: [
            FilledButton.tonalIcon(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Crear objetivo')),
            IconButton(onPressed: _loadCurrent, icon: const Icon(Icons.refresh)),
          ]),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          if (_current != null) ...[
            const SizedBox(height: 8),
            Text('Objetivo actual', style: Theme.of(context).textTheme.titleMedium),
            Card(
              child: ListTile(
                title: Text(_current!.goalType ?? ''),
                subtitle: Text('kcal ${_current!.dailyCalories ?? '-'} · P ${_current!.proteinG ?? '-'} · C ${_current!.carbsG ?? '-'} · G ${_current!.fatG ?? '-'}\ninicio ${_current!.startDate ?? '-'} · activo ${_current!.active ?? '-'}'),
              ),
            ),
          ],
          if (!_loading && _current == null && _error == null)
            const Padding(padding: EdgeInsets.all(16), child: Text('No hay objetivo configurado. Crea uno.')),
        ],
      ),
    );
  }
}
