import 'package:drift/native.dart' show SqliteException;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/features/planning/recurring_form_sheet.dart';
import 'package:flutter_application_1/src/providers/recurring_entries_providers.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_application_1/src/shared/utils/account_visuals.dart';
import 'package:flutter_application_1/src/shared/utils/entry_visuals.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';
import 'package:flutter_application_1/src/shared/widgets/async_value_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecurringEntriesPage extends ConsumerWidget {
  const RecurringEntriesPage({super.key});

  Future<void> _openForm(BuildContext context, {RecurringEntry? rule}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => RecurringFormSheet(rule: rule),
    );

    if (saved ?? false) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              rule == null ? 'Regra adicionada.' : 'Regra atualizada.',
            ),
          ),
        );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RecurringEntry rule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir regra'),
        content: Text(
          'Deseja excluir "${rule.description}"? '
          'Os lançamentos já gerados serão mantidos.',
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
        await ref.read(recurringEntriesRepositoryProvider).delete(rule.id);
      } on SqliteException {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Não foi possível excluir a regra.'),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(recurringEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Contas recorrentes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova regra'),
      ),
      body: AsyncValueView(
        asyncValue: rulesAsync,
        emptyMessage:
            'Nenhuma regra recorrente ainda.\nUse o botão abaixo para criar a primeira.',
        dataBuilder: (context, rules) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          itemCount: rules.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = rules[index];
            final rule = item.rule;
            final typeColor = rule.type == EntryType.expense
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.secondary;

            return Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(
                  Icons.autorenew,
                  color: rule.active
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).disabledColor,
                ),
                title: Text(
                  rule.description,
                  style: rule.active
                      ? null
                      : TextStyle(
                          color: Theme.of(context).disabledColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                ),
                subtitle: Text(
                  [
                    'Dia ${rule.dayOfMonth}',
                    entryTypeLabel(rule.type),
                    accountTypeLabel(item.account.type),
                    if (item.category != null) item.category!.name,
                    if (!rule.active) 'Pausada',
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatMoneyCents(rule.amountCents),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: typeColor,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _openForm(context, rule: rule);
                          case 'toggle':
                            ref
                                .read(recurringEntriesRepositoryProvider)
                                .setActive(rule.id, active: !rule.active);
                          case 'delete':
                            _confirmDelete(context, ref, rule);
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
                        PopupMenuItem(
                          value: 'toggle',
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              rule.active
                                  ? Icons.pause_outlined
                                  : Icons.play_arrow_outlined,
                            ),
                            title: Text(rule.active ? 'Pausar' : 'Retomar'),
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
              ),
            );
          },
        ),
      ),
    );
  }
}
