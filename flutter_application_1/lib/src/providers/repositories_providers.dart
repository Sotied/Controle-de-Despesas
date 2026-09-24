import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/src/database/app_database_provider.dart';
import 'package:flutter_application_1/src/repositories/accounts_repository.dart';
import 'package:flutter_application_1/src/repositories/app_preferences_repository.dart';
import 'package:flutter_application_1/src/repositories/budgets_repository.dart';
import 'package:flutter_application_1/src/repositories/categories_repository.dart';
import 'package:flutter_application_1/src/repositories/financial_entries_repository.dart';
import 'package:flutter_application_1/src/repositories/goals_repository.dart';
import 'package:flutter_application_1/src/repositories/recurring_entries_repository.dart';
import 'package:flutter_application_1/src/repositories/reports_repository.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  return AccountsRepository(ref.watch(appDatabaseProvider));
});

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(appDatabaseProvider));
});

final financialEntriesRepositoryProvider =
    Provider<FinancialEntriesRepository>((ref) {
      return FinancialEntriesRepository(ref.watch(appDatabaseProvider));
    });

final appPreferencesRepositoryProvider = Provider<AppPreferencesRepository>((
  ref,
) {
  return AppPreferencesRepository(ref.watch(appDatabaseProvider));
});

final recurringEntriesRepositoryProvider =
    Provider<RecurringEntriesRepository>((ref) {
      return RecurringEntriesRepository(ref.watch(appDatabaseProvider));
    });

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository(ref.watch(appDatabaseProvider));
});

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepository(ref.watch(appDatabaseProvider));
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(appDatabaseProvider));
});
