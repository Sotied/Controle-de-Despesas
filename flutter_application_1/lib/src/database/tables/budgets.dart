import 'package:drift/drift.dart';
import 'package:flutter_application_1/src/database/tables/categories.dart';

@DataClassName('Budget')
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get categoryId => integer().unique().references(
    Categories,
    #id,
    onDelete: KeyAction.restrict,
  )();

  IntColumn get amountCents => integer()();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  List<String> get customConstraints => const [
    'CHECK (amount_cents > 0)',
  ];
}
