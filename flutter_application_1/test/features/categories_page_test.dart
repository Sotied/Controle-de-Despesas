import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/app_database_provider.dart';
import 'package:flutter_application_1/src/features/categories/categories_page.dart';
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
        child: const MaterialApp(home: CategoriesPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lista categorias iniciais separadas por tipo', (tester) async {
    await pumpPage(tester);

    expect(find.text('Alimentação'), findsOneWidget);
    expect(find.text('Transporte'), findsOneWidget);
    expect(find.text('Salário'), findsNothing);

    await tester.tap(find.text('Receitas'));
    await tester.pumpAndSettle();

    expect(find.text('Salário'), findsOneWidget);
    expect(find.text('Alimentação'), findsNothing);
  });

  testWidgets('cria nova categoria pelo formulário', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Receitas'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Freelance');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Freelance'), findsOneWidget);
  });

  testWidgets('impede categoria duplicada do mesmo tipo', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Alimentação');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Já existe uma categoria "Alimentação" desse tipo.'),
      findsOneWidget,
    );
    expect(find.text('Adicionar'), findsOneWidget);
  });

  testWidgets('exclui categoria com confirmação', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Alimentação'), findsNothing);
  });

  testWidgets('arquiva e restaura categoria', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Arquivar'));
    await tester.pumpAndSettle();

    expect(find.text('Alimentação'), findsNothing);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pumpAndSettle();

    expect(find.text('Alimentação'), findsOneWidget);
    expect(find.text('Arquivada'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restaurar'));
    await tester.pumpAndSettle();

    expect(find.text('Arquivada'), findsNothing);
    expect(find.text('Alimentação'), findsOneWidget);
  });
}
