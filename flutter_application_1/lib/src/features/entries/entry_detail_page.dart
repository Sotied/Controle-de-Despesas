import 'package:drift/native.dart' show SqliteException;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/features/new_entry/new_entry_page.dart';
import 'package:flutter_application_1/src/providers/financial_entries_providers.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_application_1/src/repositories/financial_entries_repository.dart';
import 'package:flutter_application_1/src/shared/utils/entry_visuals.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EntryDetailPage extends ConsumerWidget {
  const EntryDetailPage({super.key, required this.entryId});

  final int entryId;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir lançamento'),
        content: const Text(
          'Deseja excluir este lançamento? Essa ação não pode ser desfeita.',
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
            .read(financialEntriesRepositoryProvider)
            .deleteEntry(entryId);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } on SqliteException {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Não foi possível excluir o lançamento.'),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(entryByIdProvider(entryId));

    return Scaffold(
      appBar: AppBar(title: const Text('Lançamento')),
      body: entryAsync.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(
          child: Text('Não foi possível carregar o lançamento.'),
        ),
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Lançamento não encontrado.'));
          }

          return _EntryDetail(
            item: item,
            onEdit: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NewEntryPage(entryId: entryId),
              ),
            ),
            onDelete: () => _confirmDelete(context, ref),
          );
        },
      ),
    );
  }
}

class _EntryDetail extends StatelessWidget {
  const _EntryDetail({required this.item, required this.onEdit, required this.onDelete});

  final EntryWithRefs item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final entry = item.entry;
    final isTransfer = entry.type == EntryType.transfer;
    final isIncoming = entry.type == EntryType.income;
    final amountColor = switch (entry.type) {
      EntryType.expense => Theme.of(context).colorScheme.error,
      EntryType.income => Theme.of(context).colorScheme.secondary,
      EntryType.transfer => Theme.of(context).colorScheme.primary,
    };
    final amountPrefix = isTransfer ? '' : (isIncoming ? '+' : '-');

    final rows = <_DetailRow>[
      _DetailRow('Data', formatDate(entry.occurredAt)),
      if (!isTransfer)
        _DetailRow('Categoria', item.category?.name ?? 'Sem categoria'),
      _DetailRow(
        isTransfer ? 'Conta de origem' : 'Conta',
        item.sourceAccount.name,
      ),
      if (isTransfer)
        _DetailRow(
          'Conta de destino',
          item.destinationAccount?.name ?? '—',
        ),
      _DetailRow('Status', entryStatusLabel(entry.status)),
      if (entry.notes != null && entry.notes!.trim().isNotEmpty)
        _DetailRow('Observações', entry.notes!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: amountColor.withAlpha(40),
                            child: Icon(
                              entryTypeIcon(entry.type),
                              size: 20,
                              color: amountColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 2,
                            children: [
                              Text(
                                entryTypeLabel(entry.type),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '$amountPrefix${formatMoneyCents(entry.amountCents)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(color: amountColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        entry.description,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      for (final row in rows)
                        _DetailRowTile(label: row.label, value: row.value),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: onDelete,
                    child: const Text('Excluir'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;
}

class _DetailRowTile extends StatelessWidget {
  const _DetailRowTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
