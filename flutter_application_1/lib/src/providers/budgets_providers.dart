import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/src/providers/financial_entries_providers.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_application_1/src/repositories/budgets_repository.dart';

final budgetsProvider =
    StreamProvider.family<List<BudgetProgress>, DateTime>((ref, monthStart) {
      return ref.watch(budgetsRepositoryProvider).watchForMonth(
        DateTime(monthStart.year, monthStart.month),
      );
    });

final currentMonthBudgetsProvider = StreamProvider<List<BudgetProgress>>((
  ref,
) {
  final monthStart = ref.watch(currentMonthProvider);
  return ref.watch(budgetsRepositoryProvider).watchForMonth(
    DateTime(monthStart.year, monthStart.month),
  );
});
