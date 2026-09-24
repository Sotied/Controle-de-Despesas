import 'package:drift/drift.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 80)();

  TextColumn get type => textEnum<CategoryType>()();

  IntColumn get iconCodePoint => integer().nullable()();

  IntColumn get colorValue => integer().nullable()();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {name, type},
  ];
}
