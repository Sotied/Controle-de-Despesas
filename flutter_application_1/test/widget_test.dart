import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/app.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/app_database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navega da Home para Configurações', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const ExpenseControlApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saldo consolidado'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('Configurações'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Categorias'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await db.close();
  });
}
