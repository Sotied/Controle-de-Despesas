import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/app_database_provider.dart';
import 'package:flutter_application_1/src/features/planning/goals_page.dart';
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

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GoalsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('cria meta pelo formulário com prazo padrão', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Nova meta'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Descrição'),
      'Viagem de férias',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Valor alvo'),
      '1.000,00',
    );
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Meta adicionada.'), findsOneWidget);
    expect(find.text('Viagem de férias'), findsOneWidget);
    expect(find.text(r'R$ 0,00 de R$ 1.000,00 • 0%'), findsOneWidget);
    expect(find.textContaining('30 dias restantes'), findsOneWidget);

    final goals = await db.select(db.goals).get();
    expect(goals, hasLength(1));
    expect(goals.single.targetAmountCents, 100000);
    expect(goals.single.savedAmountCents, 0);
  });

  testWidgets('registra aportes e atinge a meta', (tester) async {
    await db
        .into(db.goals)
        .insert(
          GoalsCompanion.insert(
            description: 'Reserva de emergência',
            targetAmountCents: 10000,
            targetDate: DateTime.now().add(const Duration(days: 30)),
          ),
        );

    await pumpPage(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Aporte').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Valor do aporte'),
      '40,00',
    );
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    expect(find.text('Aporte registrado.'), findsOneWidget);
    expect(find.text(r'R$ 40,00 de R$ 100,00 • 40%'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Aporte').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Valor do aporte'),
      '60,00',
    );
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    expect(find.text('Meta atingida!'), findsOneWidget);

    final goal = await db.select(db.goals).getSingle();
    expect(goal.savedAmountCents, 10000);
  });

  testWidgets('exclui meta com confirmação', (tester) async {
    await db
        .into(db.goals)
        .insert(
          GoalsCompanion.insert(
            description: 'Notebook',
            targetAmountCents: 300000,
            targetDate: DateTime.now().add(const Duration(days: 90)),
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

    expect(find.textContaining('Nenhuma meta definida'), findsOneWidget);

    final goals = await db.select(db.goals).get();
    expect(goals, isEmpty);
  });
}
