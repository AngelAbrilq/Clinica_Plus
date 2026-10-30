import '../../models/cie10_entry.dart';

/// Catálogo CIE-10 local (sin internet).
/// Implementaciones: SQLite con drift (Android) y en memoria (web).
abstract interface class Cie10Repository {
  /// Carga el catálogo la primera vez (idempotente).
  Future<void> ensureLoaded();

  Future<List<Cie10Entry>> search(String query, {int limit = 25});
}
