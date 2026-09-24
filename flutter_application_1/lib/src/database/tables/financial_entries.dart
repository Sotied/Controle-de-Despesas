import 'package:drift/drift.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/database/tables/accounts.dart';
import 'package:flutter_application_1/src/database/tables/categories.dart';
import 'package:flutter_application_1/src/database/tables/recurring_entries.dart';

@DataClassName('FinancialEntry')
class FinancialEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get description => text().withLength(min: 1, max: 120)();

  TextColumn get type => textEnum<EntryType>()();

  TextColumn get status =>
      textEnum<EntryStatus>().withDefault(const Constant('completed'))();

  IntColumn get amountCents => integer()();

  IntColumn get categoryId => integer().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.restrict,
  )();

  @ReferenceName('sourceEntries')
  IntColumn get sourceAccountId =>
      integer().references(Accounts, #id, onDelete: KeyAction.restrict)();

  @ReferenceName('destinationEntries')
  IntColumn get destinationAccountId => integer().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.restrict,
  )();

  IntColumn get recurringId => integer().nullable().references(
    RecurringEntries,
    #id,
    onDelete: KeyAction.setNull,
  )();

  DateTimeColumn get occurredAt => dateTime()();

  DateTimeColumn get dueAt => dateTime().nullable()();

  TextColumn get notes => text().withLength(max: 500).nullable()();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  List<String> get customConstraints => const [
    'CHECK (amount_cents > 0)',
    'CHECK (destination_account_id IS NULL OR '
        'destination_account_id <> source_account_id)',
    "CHECK ((type = 'transfer' AND destination_account_id IS NOT NULL "
        'AND category_id IS NULL) OR '
        "(type <> 'transfer' AND destination_account_id IS NULL))",
  ];
}
