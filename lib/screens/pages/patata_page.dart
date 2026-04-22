import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../services/calbalance_api.dart';

class PatataPage extends StatefulWidget {
  const PatataPage({super.key});

  @override
  State<PatataPage> createState() => _PatataPageState();
}

class _PatataPageState extends State<PatataPage> {
  late CalBalanceApi _api;

  String? _out;
  bool _loading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api = AppScope.of(context).api;
  }

  Future<void> _call() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _api.patataTest();
      if (mounted) setState(() => _out = s);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Patata test', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FilledButton(onPressed: _loading ? null : _call, child: const Text('Llamar')),
        if (_loading) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        if (_out != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SelectableText(_out!),
          ),
      ],
    );
  }
}
