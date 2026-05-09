import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../models/models.dart';
import '../../services/calbalance_api.dart';
import '../../utils/dialog_controllers.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  late CalBalanceApi _api;
  bool _didInit = false;

  List<BodyProgressResponse> _all = [];
  BodyProgressResponse? _latest;
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
      final a = await _api.progressAll();
      if (!mounted) return;
      BodyProgressResponse? l;
      try { l = await _api.progressLatest(); } catch (_) { l = null; }
      if (mounted) setState(() { _all = a; _latest = l; });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    if (!mounted) return;
    final w = TextEditingController();
    final fat = TextEditingController();
    final mus = TextEditingController();

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Registrar progreso'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: w, decoration: const InputDecoration(labelText: 'Peso kg'), keyboardType: TextInputType.number),
            TextField(controller: fat, decoration: const InputDecoration(labelText: '% grasa (opcional)'), keyboardType: TextInputType.number),
            TextField(controller: mus, decoration: const InputDecoration(labelText: 'Masa muscular kg (opcional)'), keyboardType: TextInputType.number),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
          ],
        ),
      );

      if (ok != true || !mounted) return;

      final wv = double.tryParse(w.text.replaceAll(',', '.'));
      final fv = fat.text.trim().isEmpty ? null : double.tryParse(fat.text.replaceAll(',', '.'));
      final mv = mus.text.trim().isEmpty ? null : double.tryParse(mus.text.replaceAll(',', '.'));

      if (wv == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Peso inválido')));
        return;
      }

      await _api.progressCreate(weightKg: wv, bodyFatPercent: fv, muscleMassKg: mv);
      if (mounted) _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      scheduleDisposeTextControllers([w, fat, mus]);
    }
  }

  Future<void> _edit(BodyProgressResponse b) async {
    if (b.id == null || !mounted) return;
    final w = TextEditingController(
      text: b.weightKg == null ? '' : (b.weightKg == b.weightKg!.roundToDouble() ? '${b.weightKg!.round()}' : '${b.weightKg}'),
    );
    final fat = TextEditingController(
      text: b.bodyFatPercent == null
          ? ''
          : (b.bodyFatPercent == b.bodyFatPercent!.roundToDouble()
              ? '${b.bodyFatPercent!.round()}'
              : '${b.bodyFatPercent}'),
    );
    final mus = TextEditingController(
      text: b.muscleMassKg == null
          ? ''
          : (b.muscleMassKg == b.muscleMassKg!.roundToDouble()
              ? '${b.muscleMassKg!.round()}'
              : '${b.muscleMassKg}'),
    );

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Editar registro · ${b.recordedAt ?? ''}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: w,
                decoration: const InputDecoration(labelText: 'Peso kg'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: fat,
                decoration: const InputDecoration(labelText: '% grasa (opcional)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: mus,
                decoration: const InputDecoration(labelText: 'Masa muscular kg (opcional)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
          ],
        ),
      );

      if (ok != true || !mounted) return;

      final wv = double.tryParse(w.text.replaceAll(',', '.'));
      if (wv == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Peso inválido')));
        return;
      }
      final fv = fat.text.trim().isEmpty ? null : double.tryParse(fat.text.replaceAll(',', '.'));
      final mv = mus.text.trim().isEmpty ? null : double.tryParse(mus.text.replaceAll(',', '.'));

      await _api.progressUpdate(b.id!, weightKg: wv, bodyFatPercent: fv, muscleMassKg: mv);
      if (mounted) {
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro actualizado')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      scheduleDisposeTextControllers([w, fat, mus]);
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
            FilledButton.tonalIcon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Nuevo registro')),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ]),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (_latest != null) ...[
            const SizedBox(height: 8),
            Text('Último registro', style: Theme.of(context).textTheme.titleMedium),
            _card(_latest!),
          ],
          const Divider(height: 24),
          Text('Historial', style: Theme.of(context).textTheme.titleMedium),
          if (_all.isEmpty && !_loading)
            const Padding(padding: EdgeInsets.all(16), child: Text('Sin registros todavía')),
          ..._all.map(_card),
        ],
      ),
    );
  }

  Widget _card(BodyProgressResponse b) {
    return Card(
      child: ListTile(
        title: Text('${b.weightKg ?? '-'} kg · ${b.recordedAt ?? ''}'),
        subtitle: Text('Grasa ${b.bodyFatPercent ?? '-'}% · Músculo ${b.muscleMassKg ?? '-'} kg'),
        trailing: b.id == null ? null : const Icon(Icons.edit_outlined),
        onTap: b.id == null ? null : () => _edit(b),
      ),
    );
  }
}
