import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/calbalance_api.dart';

/// Search-by-name UI to pick a food from [CalBalanceApi.foodsSearch].
/// Use inside a [Column] with [Expanded] so the list gets height.
class FoodSearchPicker extends StatefulWidget {
  const FoodSearchPicker({
    super.key,
    required this.api,
    required this.selected,
    required this.onSelectionChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final CalBalanceApi api;
  final FoodsResponse? selected;
  final ValueChanged<FoodsResponse?> onSelectionChanged;
  final EdgeInsetsGeometry padding;

  @override
  State<FoodSearchPicker> createState() => _FoodSearchPickerState();
}

class _FoodSearchPickerState extends State<FoodSearchPicker> {
  final _searchCtrl = TextEditingController();

  List<FoodsResponse> _hits = [];
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _hits = [];
        _error = null;
      });
      widget.onSelectionChanged(null);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.api.foodsSearch(q);
      if (mounted) {
        setState(() => _hits = list);
        widget.onSelectionChanged(null);
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre',
                    hintText: 'Ej. pollo, arroz…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.tonal(
                  onPressed: _loading ? null : _search,
                  child: const Text('Buscar'),
                ),
              ),
            ],
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
            ),
          Expanded(
            child: _hits.isEmpty && !_loading
                ? Center(
                    child: Text(
                      _searchCtrl.text.trim().isEmpty
                          ? 'Busca un alimento por nombre'
                          : 'Sin resultados. Prueba otras palabras.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: _hits.length,
                    itemBuilder: (_, i) {
                      final f = _hits[i];
                      final id = f.id;
                      final isSelected = id != null && widget.selected?.id == id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        color: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.35) : null,
                        child: ListTile(
                          title: Text(f.name ?? ''),
                          subtitle: Text(
                            [
                              if ((f.brand ?? '').isNotEmpty) f.brand!,
                              'kcal/100g ${f.caloriesPer100g?.toStringAsFixed(0) ?? '-'}',
                            ].join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isSelected ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
                          onTap: id == null ? null : () => widget.onSelectionChanged(f),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
