// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $Cie10CodesTable extends Cie10Codes
    with TableInfo<$Cie10CodesTable, Cie10Code> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $Cie10CodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchTextMeta = const VerificationMeta(
    'searchText',
  );
  @override
  late final GeneratedColumn<String> searchText = GeneratedColumn<String>(
    'search_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [code, description, searchText];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cie10_codes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cie10Code> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('search_text')) {
      context.handle(
        _searchTextMeta,
        searchText.isAcceptableOrUnknown(data['search_text']!, _searchTextMeta),
      );
    } else if (isInserting) {
      context.missing(_searchTextMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  Cie10Code map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cie10Code(
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      searchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_text'],
      )!,
    );
  }

  @override
  $Cie10CodesTable createAlias(String alias) {
    return $Cie10CodesTable(attachedDatabase, alias);
  }
}

class Cie10Code extends DataClass implements Insertable<Cie10Code> {
  final String code;
  final String description;
  final String searchText;
  const Cie10Code({
    required this.code,
    required this.description,
    required this.searchText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['description'] = Variable<String>(description);
    map['search_text'] = Variable<String>(searchText);
    return map;
  }

  Cie10CodesCompanion toCompanion(bool nullToAbsent) {
    return Cie10CodesCompanion(
      code: Value(code),
      description: Value(description),
      searchText: Value(searchText),
    );
  }

  factory Cie10Code.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cie10Code(
      code: serializer.fromJson<String>(json['code']),
      description: serializer.fromJson<String>(json['description']),
      searchText: serializer.fromJson<String>(json['searchText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'description': serializer.toJson<String>(description),
      'searchText': serializer.toJson<String>(searchText),
    };
  }

  Cie10Code copyWith({String? code, String? description, String? searchText}) =>
      Cie10Code(
        code: code ?? this.code,
        description: description ?? this.description,
        searchText: searchText ?? this.searchText,
      );
  Cie10Code copyWithCompanion(Cie10CodesCompanion data) {
    return Cie10Code(
      code: data.code.present ? data.code.value : this.code,
      description: data.description.present
          ? data.description.value
          : this.description,
      searchText: data.searchText.present
          ? data.searchText.value
          : this.searchText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cie10Code(')
          ..write('code: $code, ')
          ..write('description: $description, ')
          ..write('searchText: $searchText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(code, description, searchText);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cie10Code &&
          other.code == this.code &&
          other.description == this.description &&
          other.searchText == this.searchText);
}

class Cie10CodesCompanion extends UpdateCompanion<Cie10Code> {
  final Value<String> code;
  final Value<String> description;
  final Value<String> searchText;
  final Value<int> rowid;
  const Cie10CodesCompanion({
    this.code = const Value.absent(),
    this.description = const Value.absent(),
    this.searchText = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  Cie10CodesCompanion.insert({
    required String code,
    required String description,
    required String searchText,
    this.rowid = const Value.absent(),
  }) : code = Value(code),
       description = Value(description),
       searchText = Value(searchText);
  static Insertable<Cie10Code> custom({
    Expression<String>? code,
    Expression<String>? description,
    Expression<String>? searchText,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (description != null) 'description': description,
      if (searchText != null) 'search_text': searchText,
      if (rowid != null) 'rowid': rowid,
    });
  }

  Cie10CodesCompanion copyWith({
    Value<String>? code,
    Value<String>? description,
    Value<String>? searchText,
    Value<int>? rowid,
  }) {
    return Cie10CodesCompanion(
      code: code ?? this.code,
      description: description ?? this.description,
      searchText: searchText ?? this.searchText,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (searchText.present) {
      map['search_text'] = Variable<String>(searchText.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('Cie10CodesCompanion(')
          ..write('code: $code, ')
          ..write('description: $description, ')
          ..write('searchText: $searchText, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $Cie10CodesTable cie10Codes = $Cie10CodesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [cie10Codes];
}

typedef $$Cie10CodesTableCreateCompanionBuilder = Cie10CodesCompanion Function({
  required String code,
  required String description,
  required String searchText,
  Value<int> rowid,
});
typedef $$Cie10CodesTableUpdateCompanionBuilder = Cie10CodesCompanion Function({
  Value<String> code,
  Value<String> description,
  Value<String> searchText,
  Value<int> rowid,
});

class $$Cie10CodesTableFilterComposer
    extends Composer<_$AppDatabase, $Cie10CodesTable> {
  $$Cie10CodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnFilters(column),
  );
}

class $$Cie10CodesTableOrderingComposer
    extends Composer<_$AppDatabase, $Cie10CodesTable> {
  $$Cie10CodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$Cie10CodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $Cie10CodesTable> {
  $$Cie10CodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => column,
  );
}

class $$Cie10CodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $Cie10CodesTable,
          Cie10Code,
          $$Cie10CodesTableFilterComposer,
          $$Cie10CodesTableOrderingComposer,
          $$Cie10CodesTableAnnotationComposer,
          $$Cie10CodesTableCreateCompanionBuilder,
          $$Cie10CodesTableUpdateCompanionBuilder,
          (
            Cie10Code,
            BaseReferences<_$AppDatabase, $Cie10CodesTable, Cie10Code>,
          ),
          Cie10Code,
          PrefetchHooks Function()
        > {
  $$Cie10CodesTableTableManager(_$AppDatabase db, $Cie10CodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$Cie10CodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$Cie10CodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$Cie10CodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> code = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => Cie10CodesCompanion(
                code: code,
                description: description,
                searchText: searchText,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String code,
                required String description,
                required String searchText,
                Value<int> rowid = const Value.absent(),
              }) => Cie10CodesCompanion.insert(
                code: code,
                description: description,
                searchText: searchText,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$Cie10CodesTable, Cie10Code>(table),
                  BaseReferences<_$AppDatabase, $Cie10CodesTable, Cie10Code>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$Cie10CodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $Cie10CodesTable,
      Cie10Code,
      $$Cie10CodesTableFilterComposer,
      $$Cie10CodesTableOrderingComposer,
      $$Cie10CodesTableAnnotationComposer,
      $$Cie10CodesTableCreateCompanionBuilder,
      $$Cie10CodesTableUpdateCompanionBuilder,
      (Cie10Code, BaseReferences<_$AppDatabase, $Cie10CodesTable, Cie10Code>),
      Cie10Code,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$Cie10CodesTableTableManager get cie10Codes =>
      $$Cie10CodesTableTableManager(_db, _db.cie10Codes);
}
