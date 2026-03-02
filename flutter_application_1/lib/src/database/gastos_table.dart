import 'package:drift/drift.dart';

class GastosTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get descricao => text().withLength(min: 6, max: 32)();
  TextColumn get valor => text()();
  DateTimeColumn get data => dateTime()();
}
