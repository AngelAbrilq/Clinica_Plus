import '../../models/cie10_entry.dart';
import '../../utils/search_normalizer.dart';
import '../local/app_database.dart';
import 'cie10_catalog_loader.dart';
import 'cie10_repository.dart';

/// CIE-10 en SQLite (drift). Se siembra desde el asset la primera vez;
/// luego las búsquedas funcionan sin conexión.
class DriftCie10Repository implements Cie10Repository {
  DriftCie10Repository(this._database);

  final AppDatabase _database;
  Future<void>? _loading;

  @override
  Future<void> ensureLoaded() => _loading ??= _seedIfNeeded();

  Future<void> _seedIfNeeded() async {
    final catalog = await Cie10CatalogLoader.load();
    if (await _database.countCie10() >= catalog.length) return;
    await _database.replaceCie10([
      for (final entry in catalog)
        Cie10CodesCompanion.insert(
          code: entry.code,
          description: entry.description,
          searchText: SearchNormalizer.normalize(
            '${entry.code} ${entry.description}',
          ),
        ),
    ]);
  }

  @override
  Future<List<Cie10Entry>> search(String query, {int limit = 25}) async {
    await ensureLoaded();
    final normalized = SearchNormalizer.normalize(query);
    if (normalized.isEmpty) return const [];
    final rows = await _database.searchCie10(
      normalizedQuery: normalized,
      codePrefix: query.trim().toUpperCase(),
      limit: limit,
    );
    return rows
        .map((row) => Cie10Entry(code: row.code, description: row.description))
        .toList();
  }
}
