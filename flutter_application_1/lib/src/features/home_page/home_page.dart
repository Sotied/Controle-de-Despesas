import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/features/entries/entry_detail_page.dart';
import 'package:flutter_application_1/src/features/entries/entries_page.dart';
import 'package:flutter_application_1/src/features/new_entry/new_entry_page.dart';
import 'package:flutter_application_1/src/providers/accounts_providers.dart';
import 'package:flutter_application_1/src/providers/financial_entries_providers.dart';
import 'package:flutter_application_1/src/providers/recurring_entries_providers.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_application_1/src/repositories/financial_entries_repository.dart';
import 'package:flutter_application_1/src/shared/utils/entry_visuals.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';
import 'package:flutter_application_1/src/shared/widgets/async_value_view.dart';
import 'package:flutter_application_1/src/shared/widgets/entry_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _confirmDue(BuildContext context, WidgetRef ref, EntryWithRefs item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar lançamento'),
        content: Text(
          'Confirmar "${item.entry.description}" no valor de '
          '${formatMoneyCents(item.entry.amountCents)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref
          .read(recurringEntriesRepositoryProvider)
          .confirmDueEntry(item.entry.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Lançamento confirmado.')),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(recurringBootstrapProvider);

    final consolidatedBalance = ref.watch(consolidatedBalanceProvider).value;
    final monthStart = ref.watch(currentMonthProvider);
    final monthSummary = ref.watch(currentMonthSummaryProvider).value;
    final upcomingAsync = ref.watch(upcomingDueEntriesProvider);
    final recentAsync = ref.watch(recentEntriesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const NewEntryPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Novo lançamento'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _BalanceCard(balanceCents: consolidatedBalance),
          const SizedBox(height: 12),
          _MonthSummaryCard(
            summary: monthSummary,
            monthStart: monthStart,
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Próximos vencimentos'),
          AsyncValueView(
            asyncValue: upcomingAsync,
            emptyMessage: 'Nenhum vencimento próximo.',
            dataBuilder: (context, items) => _VerticalList(
              children: [
                for (final item in items)
                  _DueEntryTile(
                    item: item,
                    onConfirm: () => _confirmDue(context, ref, item),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Últimos lançamentos',
            trailing: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const EntriesPage()),
              ),
              child: const Text('Ver todos'),
            ),
          ),
          AsyncValueView(
            asyncValue: recentAsync,
            emptyMessage: 'Nenhum lançamento ainda.',
            dataBuilder: (context, items) => _VerticalList(
              children: [
                for (final item in items)
                  EntryTile(
                    item: item,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            EntryDetailPage(entryId: item.entry.id),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalList extends StatelessWidget {
  const _VerticalList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: children,
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balanceCents});

  final int? balanceCents;

  @override
  Widget build(BuildContext context) {
    final isNegative = (balanceCents ?? 0) < 0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(
              'Saldo consolidado',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              balanceCents == null
                  ? '—'
                  : formatMoneyCents(balanceCents!),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: isNegative
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  const _MonthSummaryCard({required this.summary, required this.monthStart});

  final MonthSummary? summary;
  final DateTime monthStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(
              'Resumo de ${monthName(monthStart.month)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Receitas',
                    value: summary == null
                        ? null
                        : formatMoneyCents(summary!.incomeCents),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Despesas',
                    value: summary == null
                        ? null
                        : formatMoneyCents(summary!.expenseCents),
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Saldo',
                    value: summary == null
                        ? null
                        : formatMoneyCents(summary!.balanceCents),
                    color: (summary?.balanceCents ?? 0) < 0
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value ?? '—',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(
            context,
          ).textTheme.titleSmall)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _DueEntryTile extends StatelessWidget {
  const _DueEntryTile({required this.item, required this.onConfirm});

  final EntryWithRefs item;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final entry = item.entry;
    final dueAt = entry.dueAt;
    final today = DateTime.now();
    final isOverdue =
        dueAt != null &&
        dueAt.isBefore(DateTime(today.year, today.month, today.day));
    final amountPrefix = switch (entry.type) {
      EntryType.expense => '-',
      EntryType.income => '+',
      EntryType.transfer => '',
    };

    final subtitle = dueAt == null
        ? entryStatusLabel(entry.status)
        : isOverdue
        ? 'Atrasado • vencia em ${formatDate(dueAt)}'
        : 'Vence em ${formatDate(dueAt)}';

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onConfirm,
        leading: Icon(
          Icons.schedule,
          color: isOverdue
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          entry.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isOverdue ? Theme.of(context).colorScheme.error : null,
          ),
        ),
        trailing: Text(
          '$amountPrefix${formatMoneyCents(entry.amountCents)}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    );
  }
}
