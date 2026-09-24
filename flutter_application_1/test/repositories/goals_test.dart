import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/repositories/goals_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late GoalsRepository goalsRepository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    goalsRepository = GoalsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('cria meta e calcula progresso com aportes', () async {
    final goalId = await goalsRepository.create(
      GoalsCompanion.insert(
        description: 'Viagem de férias',
        targetAmountCents: 100000,
        targetDate: DateTime.now().add(const Duration(days: 30)),
      ),
    );

    var progress = (await goalsRepository.watchAll().first).single;
    expect(progress.percent, 0);
    expect(progress.remainingCents, 100000);
    expect(progress.isAchieved, isFalse);

    await goalsRepository.addProgress(goalId, 25000);

    progress = (await goalsRepository.watchAll().first).single;
    expect(progress.percent, moreOrLessEquals(25, epsilon: 0.01));
    expect(progress.remainingCents, 75000);
    expect(progress.isAchieved, isFalse);

    await goalsRepository.addProgress(goalId, 75000);

    progress = (await goalsRepository.watchAll().first).single;
    expect(progress.isAchieved, isTrue);
    expect(progress.remainingCents, 0);
    expect(progress.percent, moreOrLessEquals(100, epsilon: 0.01));
  });

  test('atualiza meta', () async {
    final goalId = await goalsRepository.create(
      GoalsCompanion.insert(
        description: 'Reserva',
        targetAmountCents: 50000,
        targetDate: DateTime.now().add(const Duration(days: 60)),
      ),
    );

    await goalsRepository.update(
      goalId,
      const GoalsCompanion(
        description: Value('Reserva de emergência'),
        targetAmountCents: Value(80000),
      ),
    );

    final goal = (await goalsRepository.watchAll().first).single.goal;
    expect(goal.description, 'Reserva de emergência');
    expect(goal.targetAmountCents, 80000);
    expect(goal.savedAmountCents, 0);
  });

  test('exclui meta', () async {
    final goalId = await goalsRepository.create(
      GoalsCompanion.insert(
        description: 'Notebook',
        targetAmountCents: 300000,
        targetDate: DateTime.now().add(const Duration(days: 90)),
      ),
    );

    await goalsRepository.addProgress(goalId, 50000);

    await goalsRepository.delete(goalId);

    expect(await goalsRepository.watchAll().first, isEmpty);
  });

  test('aporte não pode tornar o valor salvo negativo', () async {
    final goalId = await goalsRepository.create(
      GoalsCompanion.insert(
        description: 'Viagem',
        targetAmountCents: 100000,
        targetDate: DateTime.now().add(const Duration(days: 30)),
        savedAmountCents: const Value(100),
      ),
    );

    await goalsRepository.addProgress(goalId, 500);

    final goal = (await goalsRepository.watchAll().first).single.goal;
    expect(goal.savedAmountCents, 600);
  });
}
