import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/app_database_provider.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/features/planning/planning_page.dart';
import 'package:flutter_application_1/src/features/planning/recurring_entries_page.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: page),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hub do planejamento abre as três seções', (tester) async {
    await pumpPage(tester, const PlanningPage());

    expect(find.text('Orçamento mensal'), findsOneWidget);
    expect(find.text('Contas recorrentes'), findsOneWidget);
    expect(find.text('Metas financeiras'), findsOneWidget);
    expect(find.text('Em breve'), findsNothing);

    await tester.tap(find.text('Orçamento mensal'));
    await tester.pumpAndSettle();
    expect(find.text('Novo orçamento'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Contas recorrentes'));
    await tester.pumpAndSettle();
    expect(find.text('Nova regra'), findsOneWidget);
    expect(find.textContaining('Nenhuma regra recorrente'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Metas financeiras'));
    await tester.pumpAndSettle();
    expect(find.text('Nova meta'), findsOneWidget);
    expect(find.textContaining('Nenhuma meta definida'), findsOneWidget);
  });

  testWidgets('cria regra recorrente pelo formulário', (tester) async {
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Banco', type: AccountType.bank),
        );

    await pumpPage(tester, const RecurringEntriesPage());

    await tester.tap(find.text('Nova regra'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Descrição'),
      'Aluguel',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '1.500,00');
    await tester.enterText(
      find.widgetWithText(TextField, 'Dia do vencimento'),
      '5',
    );
    await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, 'Conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Banco').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Regra adicionada.'), findsOneWidget);
    expect(find.text('Aluguel'), findsOneWidget);
    expect(find.textContaining('Dia 5'), findsOneWidget);

    final rules = await db.select(db.recurringEntries).get();
    expect(rules, hasLength(1));
    expect(rules.single.amountCents, 150000);
    expect(rules.single.dayOfMonth, 5);

    final generated = await db.select(db.financialEntries).get();
    expect(generated, hasLength(1));
    expect(generated.single.status, EntryStatus.pending);
    expect(generated.single.dueAt!.day, 5);
    expect(generated.single.recurringId, rules.single.id);
  });

  testWidgets('exclui regra com confirmação e mantém lançamentos', (
    tester,
  ) async {
    final bankId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Banco', type: AccountType.bank),
        );
    await db
        .into(db.recurringEntries)
        .insert(
          RecurringEntriesCompanion.insert(
            description: 'Streaming',
            type: EntryType.expense,
            amountCents: 2990,
            accountId: bankId,
            dayOfMonth: 10,
            startDate: DateTime.now(),
          ),
        );

    await container
        .read(recurringEntriesRepositoryProvider)
        .generateDueInstances();

    await pumpPage(tester, const RecurringEntriesPage());

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Excluir'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Nenhuma regra recorrente'), findsOneWidget);

    final entries = await db.select(db.financialEntries).get();
    expect(entries, isNotEmpty);
    expect(
      entries.every((entry) => entry.recurringId == null),
      isTrue,
    );
  });

  testWidgets('pausa e retoma regra pelo menu', (tester) async {
    final bankId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Banco', type: AccountType.bank),
        );
    await db
        .into(db.recurringEntries)
        .insert(
          RecurringEntriesCompanion.insert(
            description: 'Streaming',
            type: EntryType.expense,
            amountCents: 2990,
            accountId: bankId,
            dayOfMonth: 10,
            startDate: DateTime.now(),
          ),
        );

    await pumpPage(tester, const RecurringEntriesPage());

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pausar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pausada'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retomar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pausada'), findsNothing);
  });
}
