import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/app.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/app_database_provider.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const ExpenseControlApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> teardownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await db.close();
  }

  void setWindowSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Finder appBarTitle(String text) => find.descendant(
    of: find.byType(AppBar),
    matching: find.text(text),
  );

  Finder railLabel(String text) => find.descendant(
    of: find.byType(NavigationRail),
    matching: find.text(text),
  );

  testWidgets('navega pelas seis seções com a NavigationBar', (tester) async {
    setWindowSize(tester, const Size(400, 800));
    await pumpApp(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(appBarTitle('Home'), findsOneWidget);

    await tester.tap(find.byTooltip('Lançamentos'));
    await tester.pumpAndSettle();
    expect(appBarTitle('Lançamentos'), findsOneWidget);
    expect(find.text('Buscar lançamentos…'), findsOneWidget);

    await tester.tap(find.byTooltip('Contas'));
    await tester.pumpAndSettle();
    expect(appBarTitle('Contas'), findsOneWidget);
    expect(find.text('Saldo consolidado'), findsOneWidget);

    await tester.tap(find.byTooltip('Planejamento'));
    await tester.pumpAndSettle();
    expect(appBarTitle('Planejamento'), findsOneWidget);
    expect(find.text('Contas recorrentes'), findsOneWidget);

    await tester.tap(find.byTooltip('Relatórios'));
    await tester.pumpAndSettle();
    expect(appBarTitle('Relatórios'), findsOneWidget);

    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();
    expect(appBarTitle('Configurações'), findsOneWidget);
    expect(find.text('Categorias'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('preserva o estado da lista de lançamentos ao trocar de seção', (
    tester,
  ) async {
    setWindowSize(tester, const Size(400, 800));

    final bankId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Banco', type: AccountType.bank),
        );
    await db
        .into(db.financialEntries)
        .insert(
          FinancialEntriesCompanion.insert(
            description: 'Mercado',
            type: EntryType.expense,
            amountCents: 20000,
            sourceAccountId: bankId,
            occurredAt: DateTime.now(),
          ),
        );
    await db
        .into(db.financialEntries)
        .insert(
          FinancialEntriesCompanion.insert(
            description: 'Café',
            type: EntryType.expense,
            amountCents: 2500,
            sourceAccountId: bankId,
            occurredAt: DateTime.now(),
          ),
        );

    await pumpApp(tester);

    await tester.tap(find.byTooltip('Lançamentos'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'mercado');
    await tester.pumpAndSettle();

    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Café'), findsNothing);

    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Saldo consolidado'), findsOneWidget);

    await tester.tap(find.byTooltip('Lançamentos'));
    await tester.pumpAndSettle();

    expect(find.text('mercado'), findsOneWidget);
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Café'), findsNothing);

    await teardownApp(tester);
  });

  testWidgets('usa NavigationRail com rótulos em telas largas', (
    tester,
  ) async {
    setWindowSize(tester, const Size(1200, 800));
    await pumpApp(tester);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(railLabel('Contas'));
    await tester.pumpAndSettle();

    expect(appBarTitle('Contas'), findsOneWidget);
    expect(find.text('Saldo consolidado'), findsOneWidget);

    await tester.tap(railLabel('Configurações'));
    await tester.pumpAndSettle();
    expect(appBarTitle('Configurações'), findsOneWidget);
    expect(find.text('Categorias'), findsOneWidget);

    await teardownApp(tester);
  });
}
