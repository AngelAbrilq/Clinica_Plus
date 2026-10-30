import '../../models/cie10_entry.dart';
import '../../utils/search_normalizer.dart';
import 'cie10_catalog_loader.dart';
import 'cie10_repository.dart';

/// CIE-10 en memoria: para web (SQLite en web requiere archivos wasm extra)
/// y para tests. Misma interfaz que la versión SQLite.
class InMemoryCie10Repository implements Cie10Repository {
  InMemoryCie10Repository({Future<List<Cie10Entry>> Function()? loader})
    : _loader = loader ?? Cie10CatalogLoader.load;

  final Future<List<Cie10Entry>> Function() _loader;
  List<(Cie10Entry, String)> _index = const [];
  Future<void>? _loading;

  @override
  Future<void> ensureLoaded() => _loading ??= () async {
    final catalog = await _loader();
    _index = [
      for (final entry in catalog)
        (
          entry,
          SearchNormalizer.normalize('${entry.code} ${entry.description}'),
        ),
    ];
  }();

  @override
  Future<List<Cie10Entry>> search(String query, {int limit = 25}) async {
    await ensureLoaded();
    final normalized = SearchNormalizer.normalize(query);
    if (normalized.isEmpty) return const [];
    final codePrefix = query.trim().toUpperCase();
    final matches = [
      for (final (entry, searchText) in _index)
        if (entry.code.startsWith(codePrefix) ||
            searchText.contains(normalized))
          entry,
    ]..sort((a, b) => a.code.compareTo(b.code));
    return matches.take(limit).toList();
  }
}
