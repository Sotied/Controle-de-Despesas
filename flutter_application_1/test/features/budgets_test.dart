import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/app_database_provider.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/features/planning/budgets_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late int bankId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );

    bankId = await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(name: 'Banco', type: AccountType.bank),
        );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<int> categoryId(String name) async {
    final categories = await db.select(db.categories).get();
    return categories.singleWhere((category) => category.name == name).id;
  }

  Future<void> insertExpense({
    required String description,
    required int amountCents,
    required int categoryId,
  }) {
    return db
        .into(db.financialEntries)
        .insert(
          FinancialEntriesCompanion.insert(
            description: description,
            type: EntryType.expense,
            amountCents: amountCents,
            sourceAccountId: bankId,
            categoryId: Value(categoryId),
            occurredAt: DateTime.now(),
          ),
        );
  }

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BudgetsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('cria orçamento pelo formulário e exibe o progresso', (
    tester,
  ) async {
    final foodId = await categoryId('Alimentação');
    await insertExpense(
      description: 'Mercado',
      amountCents: 5000,
      categoryId: foodId,
    );

    await pumpPage(tester);

    await tester.tap(find.text('Novo orçamento'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<int>, 'Categoria'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alimentação').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Limite mensal'),
      '100,00',
    );
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Orçamento adicionado.'), findsOneWidget);
    expect(find.text('Alimentação'), findsOneWidget);
    expect(find.text(r'R$ 50,00 de R$ 100,00'), findsOneWidget);
    expect(find.text(r'Restam R$ 50,00'), findsOneWidget);

    final budgets = await db.select(db.budgets).get();
    expect(budgets, hasLength(1));
    expect(budgets.single.amountCents, 10000);
  });

  testWidgets('alerta quando o limite é ultrapassado', (tester) async {
    final foodId = await categoryId('Alimentação');
    await db
        .into(db.budgets)
        .insert(
          BudgetsCompanion.insert(
            categoryId: foodId,
            amountCents: 10000,
          ),
        );
    await insertExpense(
      description: 'Mercado',
      amountCents: 12000,
      categoryId: foodId,
    );

    await pumpPage(tester);

    expect(find.text(r'R$ 120,00 de R$ 100,00'), findsOneWidget);
    expect(find.text(r'Excedido em R$ 20,00'), findsOneWidget);
  });

  testWidgets('exclui orçamento com confirmação', (tester) async {
    final foodId = await categoryId('Alimentação');
    await db
        .into(db.budgets)
        .insert(
          BudgetsCompanion.insert(
            categoryId: foodId,
            amountCents: 10000,
          ),
        );

    await pumpPage(tester);

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

    expect(find.textContaining('Nenhum orçamento definido'), findsOneWidget);

    final budgets = await db.select(db.budgets).get();
    expect(budgets, isEmpty);
  });
}
