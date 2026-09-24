import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/app_database_provider.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/features/accounts/accounts_page.dart';
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

  Future<int> insertAccount({
    required String name,
    required AccountType type,
    int initialBalanceCents = 0,
  }) {
    return db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: name,
            type: type,
            initialBalanceCents: Value(initialBalanceCents),
          ),
        );
  }

  Future<void> seedData() async {
    final bankId = await insertAccount(
      name: 'Banco principal',
      type: AccountType.bank,
      initialBalanceCents: 100000,
    );
    final savingsId = await insertAccount(
      name: 'Reserva',
      type: AccountType.savings,
    );

    await db
        .into(db.financialEntries)
        .insert(
          FinancialEntriesCompanion.insert(
            description: 'Café',
            type: EntryType.expense,
            amountCents: 2500,
            sourceAccountId: bankId,
            occurredAt: DateTime(2026, 9, 24),
          ),
        );
    await db
        .into(db.financialEntries)
        .insert(
          FinancialEntriesCompanion.insert(
            description: 'Salário',
            type: EntryType.income,
            amountCents: 5000,
            sourceAccountId: bankId,
            occurredAt: DateTime(2026, 9, 24),
          ),
        );
    await db
        .into(db.financialEntries)
        .insert(
          FinancialEntriesCompanion.insert(
            description: 'Reserva mensal',
            type: EntryType.transfer,
            amountCents: 1000,
            sourceAccountId: bankId,
            destinationAccountId: Value(savingsId),
            occurredAt: DateTime(2026, 9, 24),
          ),
        );
  }

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AccountsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder popupOf(String accountName) => find.descendant(
    of: find.widgetWithText(Card, accountName),
    matching: find.byType(PopupMenuButton<String>),
  );

  testWidgets('exibe contas com saldo calculado e consolidado', (
    tester,
  ) async {
    await seedData();
    await pumpPage(tester);

    expect(find.text('Banco principal'), findsOneWidget);
    expect(find.text('Reserva'), findsOneWidget);
    expect(find.text(r'R$ 1.015,00'), findsOneWidget);
    expect(find.text(r'R$ 10,00'), findsOneWidget);
    expect(find.text(r'R$ 1.025,00'), findsOneWidget);
  });

  testWidgets('detalhe mostra saldo e histórico com direção dos valores', (
    tester,
  ) async {
    await seedData();
    await pumpPage(tester);

    await tester.tap(find.text('Banco principal'));
    await tester.pumpAndSettle();

    expect(find.text('Saldo atual'), findsOneWidget);
    expect(find.text(r'R$ 1.015,00'), findsOneWidget);
    expect(find.text('Café'), findsOneWidget);
    expect(find.text('Salário'), findsOneWidget);
    expect(find.text('Reserva mensal'), findsOneWidget);
    expect(find.text(r'-R$ 25,00'), findsOneWidget);
    expect(find.text(r'+R$ 50,00'), findsOneWidget);
    expect(find.text(r'-R$ 10,00'), findsOneWidget);
    expect(find.textContaining('Para Reserva'), findsOneWidget);
  });

  testWidgets('cria conta com saldo inicial pelo formulário', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Nova conta'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Carteira do dia');
    await tester.enterText(
      find.widgetWithText(TextField, 'Saldo inicial (opcional)'),
      '50,00',
    );
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Carteira do dia'), findsOneWidget);
    expect(find.text(r'R$ 50,00'), findsNWidgets(2));
  });

  testWidgets('valida nome obrigatório no formulário', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Nova conta'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe um nome para a conta.'), findsOneWidget);
  });

  testWidgets('edita nome da conta', (tester) async {
    await seedData();
    await pumpPage(tester);

    await tester.tap(popupOf('Banco principal'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Nome'),
      'Banco alterado',
    );
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();

    expect(find.text('Banco alterado'), findsOneWidget);
    expect(find.text('Banco principal'), findsNothing);
  });

  testWidgets('exibe campo de limite para cartão de crédito', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Nova conta'));
    await tester.pumpAndSettle();

    expect(find.text('Saldo inicial (opcional)'), findsOneWidget);
    expect(find.text('Limite do cartão (opcional)'), findsNothing);

    await tester.tap(find.text('Cartão'));
    await tester.pumpAndSettle();

    expect(find.text('Saldo inicial (opcional)'), findsNothing);
    expect(find.text('Limite do cartão (opcional)'), findsOneWidget);
  });

  testWidgets('arquiva e restaura conta', (tester) async {
    await seedData();
    await pumpPage(tester);

    await tester.tap(popupOf('Banco principal'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Arquivar'));
    await tester.pumpAndSettle();

    expect(find.text('Banco principal'), findsNothing);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pumpAndSettle();

    expect(find.text('Banco principal'), findsOneWidget);
    expect(find.textContaining('Arquivada'), findsOneWidget);

    await tester.tap(popupOf('Banco principal'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restaurar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Arquivada'), findsNothing);
  });

  testWidgets('bloqueia exclusão de conta com lançamentos', (tester) async {
    await seedData();
    await pumpPage(tester);

    await tester.tap(popupOf('Banco principal'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(find.textContaining('lançamentos vinculados'), findsOneWidget);
    expect(find.text('Banco principal'), findsOneWidget);
  });

  testWidgets('exclui conta sem lançamentos após confirmação', (tester) async {
    await seedData();
    await pumpPage(tester);

    await tester.tap(find.text('Nova conta'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Nome'),
      'Temporária',
    );
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    await tester.tap(popupOf('Temporária'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Temporária'), findsNothing);
  });
}
