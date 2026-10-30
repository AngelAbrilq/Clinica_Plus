import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/cie10_repository.dart';
import '../../../models/cie10_entry.dart';

/// Buscador de diagnósticos CIE-10 (local, sin internet).
/// Busca por código ("J06") o por texto sin tildes ("migrana").
class Cie10Picker extends StatefulWidget {
  const Cie10Picker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Cie10Entry? selected;
  final ValueChanged<Cie10Entry?> onChanged;

  @override
  State<Cie10Picker> createState() => _Cie10PickerState();
}

class _Cie10PickerState extends State<Cie10Picker> {
  static const Duration _debounce = Duration(milliseconds: 250);

  final _controller = TextEditingController();
  Timer? _debounceTimer;
  List<Cie10Entry> _results = const [];
  bool _isSearching = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Espera a que el médico deje de escribir antes de buscar.
  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await context.read<Cie10Repository>().search(query);
    if (!mounted || query != _controller.text) return; // respuesta vieja
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  void _select(Cie10Entry entry) {
    _controller.clear();
    setState(() => _results = const []);
    widget.onChanged(entry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selected = widget.selected;

    if (selected != null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              selected.code,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selected.description,
                style: TextStyle(color: colors.onPrimaryContainer),
              ),
            ),
            TextButton(
              onPressed: () => widget.onChanged(null),
              child: const Text('Cambiar'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onQueryChanged,
          decoration: InputDecoration(
            labelText: 'Diagnóstico CIE-10',
            hintText: 'Código o nombre: J06, migraña, lumbago…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        if (_results.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final entry = _results[index];
                  return ListTile(
                    dense: true,
                    leading: Text(
                      entry.code,
                      style: theme.textTheme.labelLarge,
                    ),
                    title: Text(entry.description),
                    onTap: () => _select(entry),
                  );
                },
              ),
            ),
          )
        else if (_controller.text.trim().length >= 2 && !_isSearching)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Sin resultados en el catálogo local.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
