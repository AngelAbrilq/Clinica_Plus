import 'package:drift/drift.dart';

/// Tabla local (SQLite) del catálogo CIE-10.
/// [searchText] guarda "código + descripción" normalizado (sin tildes)
/// para que la búsqueda sea rápida y tolerante.
class Cie10Codes extends Table {
  TextColumn get code => text()();
  TextColumn get description => text()();
  TextColumn get searchText => text()();

  @override
  Set<Column<Object>> get primaryKey => {code};
}
