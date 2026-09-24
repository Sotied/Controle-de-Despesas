import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/repositories/financial_entries_repository.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';

class EntryListFilters {
  const EntryListFilters({
    this.search = '',
    this.fromDate,
    this.toDate,
    this.type,
    this.accountId,
    this.categoryId,
    this.sortDescending = true,
  });

  final String search;
  final DateTime? fromDate;
  final DateTime? toDate;
  final EntryType? type;
  final int? accountId;
  final int? categoryId;
  final bool sortDescending;

  bool get hasActiveFilters =>
      search.trim().isNotEmpty ||
      fromDate != null ||
      toDate != null ||
      type != null ||
      accountId != null ||
      categoryId != null;

  EntryListFilters copyWith({
    String? search,
    Object? fromDate = _unset,
    Object? toDate = _unset,
    Object? type = _unset,
    Object? accountId = _unset,
    Object? categoryId = _unset,
    bool? sortDescending,
  }) {
    return EntryListFilters(
      search: search ?? this.search,
      fromDate: identical(fromDate, _unset)
          ? this.fromDate
          : fromDate as DateTime?,
      toDate: identical(toDate, _unset) ? this.toDate : toDate as DateTime?,
      type: identical(type, _unset) ? this.type : type as EntryType?,
      accountId: identical(accountId, _unset)
          ? this.accountId
          : accountId as int?,
      categoryId: identical(categoryId, _unset)
          ? this.categoryId
          : categoryId as int?,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }

  static const _unset = Object();
}

class EntryListFiltersNotifier extends Notifier<EntryListFilters> {
  @override
  EntryListFilters build() => const EntryListFilters();

  void setSearch(String value) => state = state.copyWith(search: value);

  void setType(EntryType? type) => state = state.copyWith(type: type);

  void setAccount(int? accountId) =>
      state = state.copyWith(accountId: accountId);

  void setCategory(int? categoryId) =>
      state = state.copyWith(categoryId: categoryId);

  void setPeriod(DateTime? from, DateTime? to) =>
      state = state.copyWith(fromDate: from, toDate: to);

  void clearPeriod() => state = state.copyWith(fromDate: null, toDate: null);

  void toggleSort() =>
      state = state.copyWith(sortDescending: !state.sortDescending);

  void clearAll() => state = EntryListFilters(sortDescending: state.sortDescending);
}

final entryListFiltersProvider =
    NotifierProvider<EntryListFiltersNotifier, EntryListFilters>(
      EntryListFiltersNotifier.new,
    );

final entryListProvider = StreamProvider<List<EntryWithRefs>>((ref) {
  final filters = ref.watch(entryListFiltersProvider);
  final toDate = filters.toDate;

  return ref.watch(financialEntriesRepositoryProvider).watchEntries(
    EntryFilters(
      search: filters.search.trim().isEmpty ? null : filters.search.trim(),
      type: filters.type,
      from: filters.fromDate,
      to: toDate == null
          ? null
          : DateTime(toDate.year, toDate.month, toDate.day + 1),
      accountId: filters.accountId,
      categoryId: filters.categoryId,
      sortDescending: filters.sortDescending,
    ),
  );
});

final currentMonthProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final entriesProvider =
    StreamProvider.family<List<EntryWithRefs>, EntryFilters>((ref, filters) {
      return ref.watch(financialEntriesRepositoryProvider).watchEntries(
        filters,
      );
    });

final entryByIdProvider = StreamProvider.family<EntryWithRefs?, int>((
  ref,
  id,
) {
  return ref.watch(financialEntriesRepositoryProvider).watchEntryById(id);
});

final recentEntriesProvider = StreamProvider<List<EntryWithRefs>>((ref) {
  return ref.watch(financialEntriesRepositoryProvider).watchEntries(
    const EntryFilters(limit: 10),
  );
});

final upcomingDueEntriesProvider = StreamProvider<List<EntryWithRefs>>((ref) {
  return ref
      .watch(financialEntriesRepositoryProvider)
      .watchUpcomingDueEntries();
});

final monthSummaryProvider =
    StreamProvider.family<MonthSummary, DateTime>((ref, monthStart) {
      return ref.watch(financialEntriesRepositoryProvider).watchMonthSummary(
        DateTime(monthStart.year, monthStart.month),
      );
    });

final currentMonthSummaryProvider = StreamProvider<MonthSummary>((ref) {
  final monthStart = ref.watch(currentMonthProvider);
  return ref.watch(financialEntriesRepositoryProvider).watchMonthSummary(
    monthStart,
  );
});
