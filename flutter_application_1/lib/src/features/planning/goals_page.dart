import 'package:drift/native.dart' show SqliteException;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/features/planning/goal_form_sheet.dart';
import 'package:flutter_application_1/src/providers/goals_providers.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_application_1/src/repositories/goals_repository.dart';
import 'package:flutter_application_1/src/shared/theme/custom_theme.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';
import 'package:flutter_application_1/src/shared/widgets/async_value_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  Future<void> _openForm(BuildContext context, {Goal? goal}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => GoalFormSheet(goal: goal),
    );

    if (saved ?? false) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              goal == null ? 'Meta adicionada.' : 'Meta atualizada.',
            ),
          ),
        );
    }
  }

  Future<void> _openAporte(BuildContext context, Goal goal) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => GoalAporteSheet(goal: goal),
    );

    if (saved ?? false) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Aporte registrado.')),
        );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    GoalProgress progress,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir meta'),
        content: Text('Deseja excluir "${progress.goal.description}"?'),
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
        await ref.read(goalsRepositoryProvider).delete(progress.goal.id);
      } on SqliteException {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Não foi possível excluir a meta.')),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Metas financeiras')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova meta'),
      ),
      body: AsyncValueView(
        asyncValue: goalsAsync,
        emptyMessage:
            'Nenhuma meta definida ainda.\nUse o botão abaixo para criar a primeira.',
        dataBuilder: (context, goals) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          itemCount: goals.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final progress = goals[index];

            return _GoalCard(
              progress: progress,
              onEdit: () => _openForm(context, goal: progress.goal),
              onDelete: () => _confirmDelete(context, ref, progress),
              onAporte: () => _openAporte(context, progress.goal),
            );
          },
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.progress,
    required this.onEdit,
    required this.onDelete,
    required this.onAporte,
  });

  final GoalProgress progress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAporte;

  Color _statusColor(BuildContext context) {
    if (progress.isAchieved) {
      return Theme.of(context).colorScheme.secondary;
    }
    if (progress.isOverdue) {
      return Theme.of(context).colorScheme.error;
    }
    return CustomColors.warnBase;
  }

  String _statusText() {
    if (progress.isAchieved) {
      return 'Meta atingida!';
    }
    if (progress.isOverdue) {
      return 'Atrasada';
    }
    final days = progress.daysRemaining;
    final prazo = days == 0 ? 'vence hoje' : '$days dias restantes';
    return 'Restam ${formatMoneyCents(progress.remainingCents)} • $prazo';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);
    final goal = progress.goal;

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
                    goal.description,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
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
            Text(
              'Prazo: ${formatDate(goal.targetDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (progress.percent / 100).clamp(0.0, 1.0),
                minHeight: 8,
                color: progress.isAchieved
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.primary,
                backgroundColor: CustomColors.outline.withAlpha(80),
              ),
            ),
            Text(
              '${formatMoneyCents(goal.savedAmountCents)} de ${formatMoneyCents(goal.targetAmountCents)} • ${progress.percent.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _statusText(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                    ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: progress.isAchieved ? null : onAporte,
                  child: const Text('Aporte'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
