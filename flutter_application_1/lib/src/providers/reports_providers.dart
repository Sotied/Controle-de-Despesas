import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/src/providers/financial_entries_providers.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_application_1/src/repositories/reports_repository.dart';

class ReportFilters {
  const ReportFilters({
    this.tabIndex = 0,
    required this.month,
    this.accountId,
  });

  final int tabIndex;
  final DateTime month;
  final int? accountId;

  ReportFilters copyWith({
    int? tabIndex,
    DateTime? month,
    Object? accountId = _unset,
  }) {
    return ReportFilters(
      tabIndex: tabIndex ?? this.tabIndex,
      month: month ?? this.month,
      accountId: identical(accountId, _unset)
          ? this.accountId
          : accountId as int?,
    );
  }

  static const _unset = Object();
}

class ReportFiltersNotifier extends Notifier<ReportFilters> {
  @override
  ReportFilters build() {
    final current = ref.watch(currentMonthProvider);
    return ReportFilters(month: current);
  }

  void setTab(int index) => state = state.copyWith(tabIndex: index);

  void previousMonth() => state = state.copyWith(
    month: DateTime(state.month.year, state.month.month - 1),
  );

  void nextMonth() => state = state.copyWith(
    month: DateTime(state.month.year, state.month.month + 1),
  );

  void setAccount(int? accountId) =>
      state = state.copyWith(accountId: accountId);
}

final reportFiltersProvider =
    NotifierProvider<ReportFiltersNotifier, ReportFilters>(
      ReportFiltersNotifier.new,
    );

final categoryExpensesProvider = StreamProvider<List<CategoryExpenseReport>>((
  ref,
) {
  final filters = ref.watch(reportFiltersProvider);
  return ref.watch(reportsRepositoryProvider).watchExpensesByCategory(
    monthStart: DateTime(filters.month.year, filters.month.month),
    accountId: filters.accountId,
  );
});

final monthlyTotalsProvider = StreamProvider<List<MonthlyTotals>>((ref) {
  final filters = ref.watch(reportFiltersProvider);
  return ref.watch(reportsRepositoryProvider).watchMonthlyTotals(
    endMonth: DateTime(filters.month.year, filters.month.month),
    months: 6,
    accountId: filters.accountId,
  );
});

final periodTotalsProvider = StreamProvider<PeriodTotals>((ref) {
  final filters = ref.watch(reportFiltersProvider);
  return ref.watch(reportsRepositoryProvider).watchPeriodTotals(
    from: DateTime(filters.month.year, filters.month.month),
    to: DateTime(filters.month.year, filters.month.month + 1),
    accountId: filters.accountId,
  );
});
