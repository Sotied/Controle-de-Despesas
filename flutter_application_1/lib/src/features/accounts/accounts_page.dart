import 'package:drift/native.dart' show SqliteException;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/features/accounts/account_detail_page.dart';
import 'package:flutter_application_1/src/features/accounts/account_form_sheet.dart';
import 'package:flutter_application_1/src/features/accounts/accounts_state.dart';
import 'package:flutter_application_1/src/providers/accounts_providers.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_application_1/src/repositories/accounts_repository.dart';
import 'package:flutter_application_1/src/shared/utils/account_visuals.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';
import 'package:flutter_application_1/src/shared/widgets/async_value_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  Future<void> _openForm(BuildContext context, {Account? account}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AccountFormSheet(account: account),
    );

    if (saved ?? false) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              account == null ? 'Conta adicionada.' : 'Conta atualizada.',
            ),
          ),
        );
    }
  }

  void _openDetail(BuildContext context, int accountId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccountDetailPage(accountId: accountId),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir conta'),
        content: Text(
          'Deseja excluir "${account.name}"? Essa ação não pode ser desfeita.',
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
        await ref.read(accountsRepositoryProvider).deleteAccount(account.id);
      } on SqliteException catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                error.resultCode == 19
                    ? 'Não é possível excluir "${account.name}" porque existem lançamentos vinculados. Arquive-a para ocultar.'
                    : 'Não foi possível excluir a conta.',
              ),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(accountsViewProvider);
    final accountsAsync = ref.watch(accountsListProvider(viewState.showArchived));
    final consolidatedBalance = ref.watch(consolidatedBalanceProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas'),
        actions: [
          IconButton(
            tooltip: viewState.showArchived
                ? 'Ocultar arquivadas'
                : 'Mostrar arquivadas',
            onPressed: () =>
                ref.read(accountsViewProvider.notifier).toggleShowArchived(),
            icon: Icon(
              viewState.showArchived ? Icons.visibility_off : Icons.visibility,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova conta'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      'Saldo consolidado',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      consolidatedBalance == null
                          ? '—'
                          : formatMoneyCents(consolidatedBalance),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: consolidatedBalance != null &&
                                consolidatedBalance < 0
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: AsyncValueView(
              asyncValue: accountsAsync,
              emptyMessage: viewState.showArchived
                  ? 'Nenhuma conta encontrada.'
                  : 'Nenhuma conta ainda.\nUse o botão abaixo para criar a primeira.',
              dataBuilder: (context, accounts) => _AccountsList(
                accounts: accounts,
                onTap: (account) =>
                    _openDetail(context, account.account.id),
                onEdit: (account) =>
                    _openForm(context, account: account.account),
                onToggleArchived: (account) => ref
                    .read(accountsRepositoryProvider)
                    .setAccountArchived(
                      account.account.id,
                      archived: !account.account.isArchived,
                    ),
                onDelete: (account) =>
                    _confirmDelete(context, ref, account.account),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountsList extends StatelessWidget {
  const _AccountsList({
    required this.accounts,
    required this.onTap,
    required this.onEdit,
    required this.onToggleArchived,
    required this.onDelete,
  });

  final List<AccountWithBalance> accounts;
  final ValueChanged<AccountWithBalance> onTap;
  final ValueChanged<AccountWithBalance> onEdit;
  final ValueChanged<AccountWithBalance> onToggleArchived;
  final ValueChanged<AccountWithBalance> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: accounts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = accounts[index];
        final account = item.account;

        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            onTap: () => onTap(item),
            leading: CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withAlpha(40),
              child: Icon(
                accountTypeIcon(account.type),
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              account.name,
              style: account.isArchived
                  ? TextStyle(
                      color: Theme.of(context).disabledColor,
                      decoration: TextDecoration.lineThrough,
                    )
                  : null,
            ),
            subtitle: Text(
              account.isArchived
                  ? '${accountTypeLabel(account.type)} • Arquivada'
                  : accountTypeLabel(account.type),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatMoneyCents(item.balanceCents),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: item.balanceCents < 0
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit(item);
                      case 'archive':
                        onToggleArchived(item);
                      case 'delete':
                        onDelete(item);
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
                      value: 'archive',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          account.isArchived
                              ? Icons.unarchive_outlined
                              : Icons.archive_outlined,
                        ),
                        title: Text(
                          account.isArchived ? 'Restaurar' : 'Arquivar',
                        ),
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
    );
  }
}
