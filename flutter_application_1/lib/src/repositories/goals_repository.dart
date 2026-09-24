import 'package:drift/drift.dart';
import 'package:flutter_application_1/src/database/app_database.dart';

class GoalProgress {
  const GoalProgress({required this.goal, required this.today});

  final Goal goal;
  final DateTime today;

  double get percent =>
      goal.targetAmountCents == 0
          ? 0
          : goal.savedAmountCents / goal.targetAmountCents * 100;

  int get remainingCents => goal.targetAmountCents - goal.savedAmountCents;

  bool get isAchieved => goal.savedAmountCents >= goal.targetAmountCents;

  bool get isOverdue =>
      !isAchieved &&
      DateTime(
        goal.targetDate.year,
        goal.targetDate.month,
        goal.targetDate.day,
      ).isBefore(DateTime(today.year, today.month, today.day));

  int get daysRemaining =>
      DateTime(
        goal.targetDate.year,
        goal.targetDate.month,
        goal.targetDate.day,
      ).difference(DateTime(today.year, today.month, today.day)).inDays;
}

class GoalsRepository {
  GoalsRepository(this.db);

  final AppDatabase db;

  Stream<List<GoalProgress>> watchAll() {
    return (db.select(
      db.goals,
    )..orderBy([(tbl) => OrderingTerm.asc(tbl.targetDate)]))
        .watch()
        .map(
          (rows) => rows
              .map((goal) => GoalProgress(goal: goal, today: DateTime.now()))
              .toList(),
        );
  }

  Future<int> create(GoalsCompanion entry) =>
      db.into(db.goals).insert(entry);

  Future<int> update(int id, GoalsCompanion entry) => (db.update(
    db.goals,
  )..where((tbl) => tbl.id.equals(id))).write(
    entry.copyWith(updatedAt: Value(DateTime.now())),
  );

  Future<int> delete(int id) =>
      (db.delete(db.goals)..where((tbl) => tbl.id.equals(id))).go();

  Future<void> addProgress(int id, int amountCents) async {
    final goal = await (db.select(
      db.goals,
    )..where((tbl) => tbl.id.equals(id))).getSingle();

    await (db.update(db.goals)..where((tbl) => tbl.id.equals(id))).write(
      GoalsCompanion(
        savedAmountCents: Value(goal.savedAmountCents + amountCents),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
