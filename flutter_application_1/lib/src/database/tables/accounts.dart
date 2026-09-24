import 'package:drift/drift.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';

@DataClassName('Account')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 80)();

  TextColumn get type => textEnum<AccountType>()();

  IntColumn get initialBalanceCents =>
      integer().withDefault(const Constant(0))();

  IntColumn get creditLimitCents => integer().nullable()();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  List<String> get customConstraints => const [
    'CHECK (credit_limit_cents IS NULL OR credit_limit_cents >= 0)',
  ];
}
