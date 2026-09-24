import 'package:drift/drift.dart';

@DataClassName('Goal')
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get description => text().withLength(min: 1, max: 120)();

  IntColumn get targetAmountCents => integer()();

  IntColumn get savedAmountCents =>
      integer().withDefault(const Constant(0))();

  DateTimeColumn get targetDate => dateTime()();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  List<String> get customConstraints => const [
    'CHECK (target_amount_cents > 0)',
    'CHECK (saved_amount_cents >= 0)',
  ];
}
