import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/features/entries/entry_detail_page.dart';
import 'package:flutter_application_1/src/features/entries/entry_filters_sheet.dart';
import 'package:flutter_application_1/src/features/new_entry/new_entry_page.dart';
import 'package:flutter_application_1/src/providers/financial_entries_providers.dart';
import 'package:flutter_application_1/src/repositories/financial_entries_repository.dart';
import 'package:flutter_application_1/src/shared/widgets/async_value_view.dart';
import 'package:flutter_application_1/src/shared/widgets/entry_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EntriesPage extends ConsumerWidget {
  const EntriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(entryListFiltersProvider);
    final entriesAsync = ref.watch(entryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lançamentos'),
        actions: [
          IconButton(
            tooltip: filters.sortDescending
                ? 'Mais recentes primeiro'
                : 'Mais antigos primeiro',
            onPressed: () =>
                ref.read(entryListFiltersProvider.notifier).toggleSort(),
            icon: Icon(
              filters.sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
            ),
          ),
          IconButton(
            tooltip: 'Filtros',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const EntryFiltersSheet(),
            ),
            icon: Badge(
              isLabelVisible: filters.hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const NewEntryPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Novo lançamento'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (value) =>
                  ref.read(entryListFiltersProvider.notifier).setSearch(value),
              decoration: InputDecoration(
                hintText: 'Buscar lançamentos…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filters.search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => ref
                            .read(entryListFiltersProvider.notifier)
                            .setSearch(''),
                      ),
              ),
            ),
          ),
          Expanded(
            child: AsyncValueView(
              asyncValue: entriesAsync,
              dataBuilder: (context, entries) {
                if (entries.isEmpty) {
                  return _EmptyState(hasActiveFilters: filters.hasActiveFilters);
                }
                return _EntriesList(
                  entries: entries,
                  onOpen: (item) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => EntryDetailPage(entryId: item.entry.id),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasActiveFilters});

  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Icon(
            hasActiveFilters ? Icons.filter_alt_off_outlined : Icons.receipt_long,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
          ),
          Text(
            hasActiveFilters
                ? 'Nenhum lançamento encontrado\ncom os filtros atuais.'
                : 'Nenhum lançamento ainda.\nUse o botão abaixo para registrar o primeiro.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _EntriesList extends StatelessWidget {
  const _EntriesList({required this.entries, required this.onOpen});

  final List<EntryWithRefs> entries;
  final ValueChanged<EntryWithRefs> onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = entries[index];
        return EntryTile(item: item, onTap: () => onOpen(item));
      },
    );
  }
}
