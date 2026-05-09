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
  List<NutritionGoalResponse> _all = [];
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
      final all = await _api.goalsAll();
      NutritionGoalResponse? current;
      try {
        current = await _api.goalsByDate(toIsoDate(DateTime.now()));
      } catch (_) {
        current = null;
      }
      if (mounted) {
        setState(() {
          _all = all;
          _current = current;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<DateTime?> _pickDate({
    required DateTime initial,
    required DateTime first,
    required DateTime last,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
  }

  Future<void> _upsertGoal({NutritionGoalResponse? existing}) async {
    if (!mounted) return;
    final typeCtrl = TextEditingController(text: existing?.goalType ?? 'MAINTENANCE');
    final calCtrl = TextEditingController(text: '${existing?.dailyCalories ?? 2000}');
    final pCtrl = TextEditingController(text: '${existing?.proteinG ?? 120}');
    final cCtrl = TextEditingController(text: '${existing?.carbsG ?? 200}');
    final fCtrl = TextEditingController(text: '${existing?.fatG ?? 60}');

    DateTime startDate =
        DateTime.tryParse(existing?.startDate ?? '') ?? DateTime.now();
    DateTime endDate = DateTime.tryParse(existing?.endDate ?? '') ??
        DateTime.now().add(const Duration(days: 30));

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(existing == null ? 'Nuevo objetivo' : 'Editar objetivo'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'goalType')),
                TextField(controller: calCtrl, decoration: const InputDecoration(labelText: 'dailyCalories'), keyboardType: TextInputType.number),
                TextField(controller: pCtrl, decoration: const InputDecoration(labelText: 'proteinG'), keyboardType: TextInputType.number),
                TextField(controller: cCtrl, decoration: const InputDecoration(labelText: 'carbsG'), keyboardType: TextInputType.number),
                TextField(controller: fCtrl, decoration: const InputDecoration(labelText: 'fatG'), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Inicio'),
                  subtitle: Text(toIsoDate(startDate)),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: () async {
                      final d = await _pickDate(
                        initial: startDate,
                        first: DateTime(2020),
                        last: DateTime(2100),
                      );
                      if (d == null) return;
                      setDialogState(() => startDate = d);
                    },
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fin'),
                  subtitle: Text(toIsoDate(endDate)),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: () async {
                      final d = await _pickDate(
                        initial: endDate,
                        first: DateTime(2020),
                        last: DateTime(2100),
                      );
                      if (d == null) return;
                      setDialogState(() => endDate = d);
                    },
                  ),
                ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(existing == null ? 'Crear' : 'Guardar'),
              ),
            ],
          ),
        ),
      );

      if (ok != true || !mounted) return;

      final gt = typeCtrl.text.trim();
      final dc = int.tryParse(calCtrl.text.trim());
      final pg = int.tryParse(pCtrl.text.trim());
      final cg = int.tryParse(cCtrl.text.trim());
      final fg = int.tryParse(fCtrl.text.trim());

      if (gt.isEmpty || dc == null || pg == null || cg == null || fg == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos inválidos')));
        return;
      }
      if (endDate.isBefore(startDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La fecha de fin debe ser igual o posterior al inicio')),
        );
        return;
      }

      if (existing == null) {
        await _api.goalsCreate(
          goalType: gt,
          dailyCalories: dc,
          proteinG: pg,
          carbsG: cg,
          fatG: fg,
          startDateIso: toIsoDate(startDate),
          endDateIso: toIsoDate(endDate),
        );
      } else {
        await _api.goalsUpdate(
          existing.id!,
          goalType: gt,
          dailyCalories: dc,
          proteinG: pg,
          carbsG: cg,
          fatG: fg,
          startDateIso: toIsoDate(startDate),
          endDateIso: toIsoDate(endDate),
        );
      }
      if (mounted) _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      scheduleDisposeTextControllers([typeCtrl, calCtrl, pCtrl, cCtrl, fCtrl]);
    }
  }

  Future<void> _deleteGoal(NutritionGoalResponse goal) async {
    if (goal.id == null || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar objetivo'),
        content: Text('¿Seguro que quieres eliminar el objetivo ${goal.goalType ?? ''}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _api.goalsDelete(goal.id!);
      if (mounted) _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          Row(children: [
            FilledButton.tonalIcon(
              onPressed: () => _upsertGoal(),
              icon: const Icon(Icons.add),
              label: const Text('Crear objetivo'),
            ),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ]),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          if (_current != null) ...[
            const SizedBox(height: 8),
            Text('Objetivo actual', style: Theme.of(context).textTheme.titleMedium),
            Card(
              child: ListTile(
                title: Text(_current!.goalType ?? ''),
                subtitle: Text(
                  'kcal ${_current!.dailyCalories ?? '-'} · P ${_current!.proteinG ?? '-'} · C ${_current!.carbsG ?? '-'} · G ${_current!.fatG ?? '-'}\n'
                  'inicio ${_current!.startDate ?? '-'} · fin ${_current!.endDate ?? '-'}',
                ),
              ),
            ),
          ],
          const Divider(height: 24),
          Text('Historial de objetivos', style: Theme.of(context).textTheme.titleMedium),
          if (!_loading && _all.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No hay objetivos configurados.')),
          ..._all.map(
            (g) => Card(
              child: ListTile(
                title: Text(g.goalType ?? 'Objetivo'),
                subtitle: Text(
                  'kcal ${g.dailyCalories ?? '-'} · P ${g.proteinG ?? '-'} · C ${g.carbsG ?? '-'} · G ${g.fatG ?? '-'}\n'
                  '${g.startDate ?? '-'} → ${g.endDate ?? '-'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Editar',
                      onPressed: g.id == null ? null : () => _upsertGoal(existing: g),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Eliminar',
                      onPressed: g.id == null ? null : () => _deleteGoal(g),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
