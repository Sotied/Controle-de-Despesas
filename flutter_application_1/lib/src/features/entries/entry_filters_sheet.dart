import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/providers/accounts_providers.dart';
import 'package:flutter_application_1/src/providers/categories_providers.dart';
import 'package:flutter_application_1/src/providers/financial_entries_providers.dart';
import 'package:flutter_application_1/src/repositories/accounts_repository.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EntryFiltersSheet extends ConsumerWidget {
  const EntryFiltersSheet({super.key});

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime initialDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      onPicked(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(entryListFiltersProvider);
    final notifier = ref.read(entryListFiltersProvider.notifier);
    final accounts =
        ref.watch(accountsWithBalanceProvider).value ??
        const <AccountWithBalance>[];
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtros',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (filters.hasActiveFilters)
                  TextButton(
                    onPressed: notifier.clearAll,
                    child: const Text('Limpar filtros'),
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: filters.type == null,
                  onSelected: (_) => notifier.setType(null),
                ),
                ChoiceChip(
                  label: const Text('Despesas'),
                  selected: filters.type == EntryType.expense,
                  onSelected: (_) => notifier.setType(EntryType.expense),
                ),
                ChoiceChip(
                  label: const Text('Receitas'),
                  selected: filters.type == EntryType.income,
                  onSelected: (_) => notifier.setType(EntryType.income),
                ),
                ChoiceChip(
                  label: const Text('Transferências'),
                  selected: filters.type == EntryType.transfer,
                  onSelected: (_) => notifier.setType(EntryType.transfer),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(
                      context,
                      initialDate: filters.fromDate ?? DateTime.now(),
                      onPicked: (date) =>
                          notifier.setPeriod(date, filters.toDate),
                    ),
                    child: Text(
                      filters.fromDate == null
                          ? 'De: qualquer data'
                          : 'De: ${formatDate(filters.fromDate!)}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(
                      context,
                      initialDate: filters.toDate ?? DateTime.now(),
                      onPicked: (date) =>
                          notifier.setPeriod(filters.fromDate, date),
                    ),
                    child: Text(
                      filters.toDate == null
                          ? 'Até: qualquer data'
                          : 'Até: ${formatDate(filters.toDate!)}',
                    ),
                  ),
                ),
              ],
            ),
            DropdownButtonFormField<int>(
              key: ValueKey('filter-account-${filters.accountId}'),
              initialValue: filters.accountId,
              decoration: const InputDecoration(labelText: 'Conta'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                for (final item in accounts)
                  DropdownMenuItem(
                    value: item.account.id,
                    child: Text(item.account.name),
                  ),
              ],
              onChanged: (value) => notifier.setAccount(value),
            ),
            DropdownButtonFormField<int>(
              key: ValueKey('filter-category-${filters.categoryId}'),
              initialValue: filters.categoryId,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                for (final category in categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
              ],
              onChanged: (value) => notifier.setCategory(value),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }
}
