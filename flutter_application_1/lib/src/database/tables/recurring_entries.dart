import 'package:drift/drift.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/database/tables/accounts.dart';
import 'package:flutter_application_1/src/database/tables/categories.dart';

@DataClassName('RecurringEntry')
class RecurringEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get description => text().withLength(min: 1, max: 120)();

  TextColumn get type => textEnum<EntryType>()();

  IntColumn get amountCents => integer()();

  IntColumn get categoryId => integer().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
  )();

  IntColumn get accountId => integer().references(
    Accounts,
    #id,
    onDelete: KeyAction.restrict,
  )();

  IntColumn get dayOfMonth => integer()();

  DateTimeColumn get startDate => dateTime()();

  DateTimeColumn get endDate => dateTime().nullable()();

  BoolColumn get active => boolean().withDefault(const Constant(true))();

  DateTimeColumn get lastGeneratedDueAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  List<String> get customConstraints => const [
    'CHECK (amount_cents > 0)',
    'CHECK (day_of_month BETWEEN 1 AND 28)',
    "CHECK (type <> 'transfer')",
  ];
}
