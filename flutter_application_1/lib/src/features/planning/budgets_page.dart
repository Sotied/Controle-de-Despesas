import 'package:drift/native.dart' show SqliteException;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/features/planning/budget_form_sheet.dart';
import 'package:flutter_application_1/src/providers/budgets_providers.dart';
import 'package:flutter_application_1/src/providers/financial_entries_providers.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_application_1/src/repositories/budgets_repository.dart';
import 'package:flutter_application_1/src/shared/theme/custom_theme.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';
import 'package:flutter_application_1/src/shared/widgets/async_value_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  Future<void> _openForm(BuildContext context, {Budget? budget}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => BudgetFormSheet(budget: budget),
    );

    if (saved ?? false) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              budget == null ? 'Orçamento adicionado.' : 'Orçamento atualizado.',
            ),
          ),
        );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BudgetProgress progress,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir orçamento'),
        content: Text(
          'Deseja excluir o orçamento de "${progress.categoryName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await ref
            .read(budgetsRepositoryProvider)
            .delete(progress.budget.id);
      } on SqliteException {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Não foi possível excluir o orçamento.'),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthStart = ref.watch(currentMonthProvider);
    final budgetsAsync = ref.watch(budgetsProvider(monthStart));

    return Scaffold(
      appBar: AppBar(title: const Text('Orçamento mensal')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo orçamento'),
      ),
      body: AsyncValueView(
        asyncValue: budgetsAsync,
        emptyMessage:
            'Nenhum orçamento definido ainda.\nUse o botão abaixo para definir um limite por categoria.',
        dataBuilder: (context, budgets) {
          final totalBudgetCents = budgets.fold<int>(
            0,
            (sum, item) => sum + item.budget.amountCents,
          );
          final totalSpentCents = budgets.fold<int>(
            0,
            (sum, item) => sum + item.spentCents,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              _TotalsCard(
                budgetCents: totalBudgetCents,
                spentCents: totalSpentCents,
              ),
              const SizedBox(height: 12),
              for (final progress in budgets) ...[
                _BudgetCard(
                  progress: progress,
                  onEdit: () => _openForm(context, budget: progress.budget),
                  onDelete: () => _confirmDelete(context, ref, progress),
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.budgetCents, required this.spentCents});

  final int budgetCents;
  final int spentCents;

  @override
  Widget build(BuildContext context) {
    final remaining = budgetCents - spentCents;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(
              'Previsto x realizado',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Previsto',
                    value: formatMoneyCents(budgetCents),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Realizado',
                    value: formatMoneyCents(spentCents),
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Restante',
                    value: formatMoneyCents(remaining),
                    color: remaining < 0
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
  const _SummaryItem({required this.label, required this.value, required this.color});

  final String label;
  final String value;
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
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.progress,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetProgress progress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _statusColor(BuildContext context) {
    if (progress.isOver) {
      return Theme.of(context).colorScheme.error;
    }
    if (progress.isNear) {
      return CustomColors.warnBase;
    }
    return Theme.of(context).colorScheme.primary;
  }

  String _statusText(BuildContext context) {
    if (progress.isOver) {
      return 'Excedido em ${formatMoneyCents(progress.spentCents - progress.budget.amountCents)}';
    }
    return 'Restam ${formatMoneyCents(progress.remainingCents)}'
        '${progress.isNear ? ' • próximo do limite' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    progress.categoryName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  '${formatMoneyCents(progress.spentCents)} de ${formatMoneyCents(progress.budget.amountCents)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Editar'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline),
                        title: Text('Excluir'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.usage.clamp(0.0, 1.0),
                minHeight: 8,
                color: statusColor,
                backgroundColor: CustomColors.outline.withAlpha(80),
              ),
            ),
            Text(
              _statusText(context),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: progress.isOver || progress.isNear
                    ? statusColor
                    : Theme.of(context).colorScheme.onSurface.withAlpha(160),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
