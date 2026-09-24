import 'package:drift/drift.dart';

@DataClassName('AppPreference')
class AppPreferences extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  TextColumn get currencyCode => text().withDefault(const Constant('BRL'))();

  TextColumn get locale => text().withDefault(const Constant('pt_BR'))();

  IntColumn get firstDayOfMonth => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK (id = 1)',
    'CHECK (length(currency_code) = 3)',
    'CHECK (first_day_of_month BETWEEN 1 AND 28)',
  ];
}
