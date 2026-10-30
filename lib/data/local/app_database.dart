import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/cie10_codes.dart';

// Archivo generado por: dart run build_runner build --delete-conflicting-outputs
part 'app_database.g.dart';

/// Base de datos SQLite local de la app (drift).
/// Hoy guarda el catálogo CIE-10; mañana puede cachear agenda o sedes.
@DriftDatabase(tables: [Cie10Codes])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'clinica_plus'));

  /// Subir este número y agregar una migración al cambiar tablas.
  @override
  int get schemaVersion => 1;

  Future<int> countCie10() async {
    final row = await customSelect('SELECT COUNT(*) AS total FROM cie10_codes')
        .getSingle();
    return row.read<int>('total');
  }

  Future<void> replaceCie10(List<Cie10CodesCompanion> rows) => batch(
    (batch) =>
        batch.insertAll(cie10Codes, rows, mode: InsertMode.insertOrReplace),
  );

  /// Busca por prefijo de código (ej. "J06") o por texto en la descripción.
  Future<List<Cie10Code>> searchCie10({
    required String normalizedQuery,
    required String codePrefix,
    int limit = 25,
  }) =>
      (select(cie10Codes)
            ..where(
              (row) =>
                  row.code.like('$codePrefix%') |
                  row.searchText.like('%$normalizedQuery%'),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.code)])
            ..limit(limit))
          .get();
}
