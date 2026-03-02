// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GastosTableTable extends GastosTable
    with TableInfo<$GastosTableTable, GastosTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GastosTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _descricaoMeta = const VerificationMeta(
    'descricao',
  );
  @override
  late final GeneratedColumn<String> descricao = GeneratedColumn<String>(
    'descricao',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 6,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<String> valor = GeneratedColumn<String>(
    'valor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<DateTime> data = GeneratedColumn<DateTime>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, descricao, valor, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gastos_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<GastosTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('descricao')) {
      context.handle(
        _descricaoMeta,
        descricao.isAcceptableOrUnknown(data['descricao']!, _descricaoMeta),
      );
    } else if (isInserting) {
      context.missing(_descricaoMeta);
    }
    if (data.containsKey('valor')) {
      context.handle(
        _valorMeta,
        valor.isAcceptableOrUnknown(data['valor']!, _valorMeta),
      );
    } else if (isInserting) {
      context.missing(_valorMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GastosTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GastosTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      descricao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descricao'],
      )!,
      valor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valor'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data'],
      )!,
    );
  }

  @override
  $GastosTableTable createAlias(String alias) {
    return $GastosTableTable(attachedDatabase, alias);
  }
}

class GastosTableData extends DataClass implements Insertable<GastosTableData> {
  final int id;
  final String descricao;
  final String valor;
  final DateTime data;
  const GastosTableData({
    required this.id,
    required this.descricao,
    required this.valor,
    required this.data,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['descricao'] = Variable<String>(descricao);
    map['valor'] = Variable<String>(valor);
    map['data'] = Variable<DateTime>(data);
    return map;
  }

  GastosTableCompanion toCompanion(bool nullToAbsent) {
    return GastosTableCompanion(
      id: Value(id),
      descricao: Value(descricao),
      valor: Value(valor),
      data: Value(data),
    );
  }

  factory GastosTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GastosTableData(
      id: serializer.fromJson<int>(json['id']),
      descricao: serializer.fromJson<String>(json['descricao']),
      valor: serializer.fromJson<String>(json['valor']),
      data: serializer.fromJson<DateTime>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'descricao': serializer.toJson<String>(descricao),
      'valor': serializer.toJson<String>(valor),
      'data': serializer.toJson<DateTime>(data),
    };
  }

  GastosTableData copyWith({
    int? id,
    String? descricao,
    String? valor,
    DateTime? data,
  }) => GastosTableData(
    id: id ?? this.id,
    descricao: descricao ?? this.descricao,
    valor: valor ?? this.valor,
    data: data ?? this.data,
  );
  GastosTableData copyWithCompanion(GastosTableCompanion data) {
    return GastosTableData(
      id: data.id.present ? data.id.value : this.id,
      descricao: data.descricao.present ? data.descricao.value : this.descricao,
      valor: data.valor.present ? data.valor.value : this.valor,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GastosTableData(')
          ..write('id: $id, ')
          ..write('descricao: $descricao, ')
          ..write('valor: $valor, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, descricao, valor, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GastosTableData &&
          other.id == this.id &&
          other.descricao == this.descricao &&
          other.valor == this.valor &&
          other.data == this.data);
}

class GastosTableCompanion extends UpdateCompanion<GastosTableData> {
  final Value<int> id;
  final Value<String> descricao;
  final Value<String> valor;
  final Value<DateTime> data;
  const GastosTableCompanion({
    this.id = const Value.absent(),
    this.descricao = const Value.absent(),
    this.valor = const Value.absent(),
    this.data = const Value.absent(),
  });
  GastosTableCompanion.insert({
    this.id = const Value.absent(),
    required String descricao,
    required String valor,
    required DateTime data,
  }) : descricao = Value(descricao),
       valor = Value(valor),
       data = Value(data);
  static Insertable<GastosTableData> custom({
    Expression<int>? id,
    Expression<String>? descricao,
    Expression<String>? valor,
    Expression<DateTime>? data,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (descricao != null) 'descricao': descricao,
      if (valor != null) 'valor': valor,
      if (data != null) 'data': data,
    });
  }

  GastosTableCompanion copyWith({
    Value<int>? id,
    Value<String>? descricao,
    Value<String>? valor,
    Value<DateTime>? data,
  }) {
    return GastosTableCompanion(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      data: data ?? this.data,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (descricao.present) {
      map['descricao'] = Variable<String>(descricao.value);
    }
    if (valor.present) {
      map['valor'] = Variable<String>(valor.value);
    }
    if (data.present) {
      map['data'] = Variable<DateTime>(data.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GastosTableCompanion(')
          ..write('id: $id, ')
          ..write('descricao: $descricao, ')
          ..write('valor: $valor, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GastosTableTable gastosTable = $GastosTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [gastosTable];
}

typedef $$GastosTableTableCreateCompanionBuilder =
    GastosTableCompanion Function({
      Value<int> id,
      required String descricao,
      required String valor,
      required DateTime data,
    });
typedef $$GastosTableTableUpdateCompanionBuilder =
    GastosTableCompanion Function({
      Value<int> id,
      Value<String> descricao,
      Value<String> valor,
      Value<DateTime> data,
    });

class $$GastosTableTableFilterComposer
    extends Composer<_$AppDatabase, $GastosTableTable> {
  $$GastosTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GastosTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GastosTableTable> {
  $$GastosTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GastosTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GastosTableTable> {
  $$GastosTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get descricao =>
      $composableBuilder(column: $table.descricao, builder: (column) => column);

  GeneratedColumn<String> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);

  GeneratedColumn<DateTime> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$GastosTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GastosTableTable,
          GastosTableData,
          $$GastosTableTableFilterComposer,
          $$GastosTableTableOrderingComposer,
          $$GastosTableTableAnnotationComposer,
          $$GastosTableTableCreateCompanionBuilder,
          $$GastosTableTableUpdateCompanionBuilder,
          (
            GastosTableData,
            BaseReferences<_$AppDatabase, $GastosTableTable, GastosTableData>,
          ),
          GastosTableData,
          PrefetchHooks Function()
        > {
  $$GastosTableTableTableManager(_$AppDatabase db, $GastosTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GastosTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GastosTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GastosTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> descricao = const Value.absent(),
                Value<String> valor = const Value.absent(),
                Value<DateTime> data = const Value.absent(),
              }) => GastosTableCompanion(
                id: id,
                descricao: descricao,
                valor: valor,
                data: data,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String descricao,
                required String valor,
                required DateTime data,
              }) => GastosTableCompanion.insert(
                id: id,
                descricao: descricao,
                valor: valor,
                data: data,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GastosTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GastosTableTable,
      GastosTableData,
      $$GastosTableTableFilterComposer,
      $$GastosTableTableOrderingComposer,
      $$GastosTableTableAnnotationComposer,
      $$GastosTableTableCreateCompanionBuilder,
      $$GastosTableTableUpdateCompanionBuilder,
      (
        GastosTableData,
        BaseReferences<_$AppDatabase, $GastosTableTable, GastosTableData>,
      ),
      GastosTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GastosTableTableTableManager get gastosTable =>
      $$GastosTableTableTableManager(_db, _db.gastosTable);
}
