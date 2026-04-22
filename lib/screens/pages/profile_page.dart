import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../models/models.dart';
import '../../services/calbalance_api.dart';
import '../../utils/date_fmt.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late CalBalanceApi _api;
  bool _didInit = false;

  String? _email;
  UserInfoResponse? _info;
  bool _loading = false;
  bool _saving = false;
  bool _deactivating = false;
  String? _error;

  final _heightCtrl = TextEditingController();
  DateTime? _birthDate;
  ActivityLevel? _activityLevel;

  @override
  void dispose() {
    _heightCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api = AppScope.of(context).api;
    if (!_didInit) {
      _didInit = true;
      Future.microtask(() => _load());
    }
  }

  void _applyInfoToForm(UserInfoResponse info) {
    _heightCtrl.text = info.heightCm != null
        ? (info.heightCm == info.heightCm!.roundToDouble()
            ? info.heightCm!.round().toString()
            : info.heightCm.toString())
        : '';
    _birthDate = info.birthDate;
    _activityLevel = info.activityLevel;
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final email = await _api.usersMe();
      final info = await _api.usersMeInfo();
      if (!mounted) return;
      setState(() {
        _email = email;
        _info = info;
        _applyInfoToForm(info);
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null && mounted) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!mounted || _saving) return;
    final heightText = _heightCtrl.text.trim().replaceAll(',', '.');
    double? heightCm;
    if (heightText.isNotEmpty) {
      heightCm = double.tryParse(heightText);
      if (heightCm == null || heightCm <= 0 || heightCm > 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Altura inválida (usa cm, entre 1 y 300).')),
        );
        return;
      }
    }

    final hasAny = _activityLevel != null || _birthDate != null || heightCm != null;
    if (!hasAny) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica al menos nivel de actividad, fecha de nacimiento o altura.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = await _api.usersUpdateInfo(
        activityLevel: _activityLevel,
        birthDate: _birthDate,
        heightCm: heightCm,
      );
      if (!mounted) return;
      setState(() {
        _info = updated;
        _applyInfoToForm(updated);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDeactivate() async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar cuenta'),
        content: const Text(
          'Tu cuenta quedará desactivada y no podrás volver a iniciar sesión con ella.\n\n¿Seguro que quieres continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deactivating = true);
    var success = false;
    try {
      await _api.usersMeDeactivate();
      await _api.logout();
      success = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _deactivating = false);
    }
    if (success && mounted) widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text('Perfil', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ),
          if (_email != null) ...[
            const SizedBox(height: 12),
            Text('Email', style: theme.textTheme.labelLarge),
            Text(_email!, style: theme.textTheme.bodyLarge),
          ],
          const SizedBox(height: 20),
          Text('Datos personales', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _heightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Altura (cm)',
              border: OutlineInputBorder(),
              hintText: 'Ej. 175',
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fecha de nacimiento'),
            subtitle: Text(
              _birthDate == null ? 'Sin definir' : toIsoDate(_birthDate!),
              style: theme.textTheme.bodyLarge,
            ),
            trailing: IconButton(
              onPressed: _pickBirthDate,
              icon: const Icon(Icons.calendar_today_outlined),
              tooltip: 'Elegir fecha',
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ActivityLevel?>(
            value: _activityLevel,
            hint: const Text('Selecciona nivel (opcional)'),
            decoration: const InputDecoration(
              labelText: 'Nivel de actividad',
              border: OutlineInputBorder(),
            ),
            items: ActivityLevel.values
                .map(
                  (a) => DropdownMenuItem<ActivityLevel?>(
                    value: a,
                    child: Text(a.labelEs),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _activityLevel = v),
          ),
          if (_info?.createdAt != null) ...[
            const SizedBox(height: 16),
            Text(
              'Cuenta desde: ${toIsoDate(_info!.createdAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading || _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar cambios'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Recargar datos'),
          ),
          const SizedBox(height: 32),
          Text('Cuenta', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Desactivar tu cuenta en el servidor. Los datos se conservan, pero no podrás acceder de nuevo.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading || _deactivating ? null : _confirmDeactivate,
            icon: _deactivating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.no_accounts_outlined),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
            ),
            label: Text(_deactivating ? 'Desactivando…' : 'Desactivar cuenta'),
          ),
        ],
      ),
    );
  }
}
