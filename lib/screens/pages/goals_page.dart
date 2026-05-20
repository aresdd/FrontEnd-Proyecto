import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../models/models.dart';
import '../../services/calbalance_api.dart';
import '../../utils/date_fmt.dart';
import '../../utils/dialog_controllers.dart';
import '../../widgets/section_header.dart';

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
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _upsertGoal(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear objetivo'),
              ),
            ),
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ]),
          if (_loading) LinearProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
            minHeight: 3,
          ),
          if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          if (_current != null) ...[
            SectionHeader(
              title: 'Objetivo vigente',
              subtitle: 'El que aplica a la fecha de hoy',
              icon: Icons.flag_rounded,
            ),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  child: Icon(Icons.flag_rounded, color: Theme.of(context).colorScheme.primary),
                ),
                title: Text(_current!.goalType ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'kcal ${_current!.dailyCalories ?? '-'} · P ${_current!.proteinG ?? '-'} · C ${_current!.carbsG ?? '-'} · G ${_current!.fatG ?? '-'}\n'
                  'inicio ${_current!.startDate ?? '-'} · fin ${_current!.endDate ?? '-'}',
                ),
              ),
            ),
          ],
          SectionHeader(
            title: 'Historial de objetivos',
            subtitle: 'Editar o eliminar rangos anteriores',
            icon: Icons.history_rounded,
          ),
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
