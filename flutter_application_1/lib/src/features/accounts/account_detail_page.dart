import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/providers/accounts_providers.dart';
import 'package:flutter_application_1/src/providers/financial_entries_providers.dart';
import 'package:flutter_application_1/src/repositories/financial_entries_repository.dart';
import 'package:flutter_application_1/src/shared/theme/custom_theme.dart';
import 'package:flutter_application_1/src/shared/utils/account_visuals.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';
import 'package:flutter_application_1/src/shared/widgets/async_value_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountDetailPage extends ConsumerWidget {
  const AccountDetailPage({super.key, required this.accountId});

  final int accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(accountWithBalanceByIdProvider(accountId));
    final entriesAsync = ref.watch(
      entriesProvider(EntryFilters(accountId: accountId)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Conta')),
      body: accountAsync.when(
        skipLoadingOnReload: true,
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Conta não encontrada.'));
          }

          final account = item.account;
          final isCreditCard = account.type == AccountType.creditCard;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        Row(
                          children: [
                            Icon(
                              accountTypeIcon(account.type),
                              size: 20,
                              color: CustomColors.onSurfaceMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                account.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            if (account.isArchived)
                              const Chip(
                                label: Text('Arquivada'),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        Text(
                          accountTypeLabel(account.type),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCreditCard ? 'Saldo do cartão' : 'Saldo atual',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          formatMoneyCents(item.balanceCents),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: item.balanceCents < 0
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                        if (isCreditCard && account.creditLimitCents != null)
                          Text(
                            'Limite: ${formatMoneyCents(account.creditLimitCents!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Histórico',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Expanded(
                child: AsyncValueView(
                  asyncValue: entriesAsync,
                  emptyMessage: 'Nenhum lançamento nesta conta.',
                  dataBuilder: (context, entries) => _EntryHistoryList(
                    entries: entries,
                    accountId: accountId,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text('Não foi possível carregar a conta.')),
      ),
    );
  }
}

class _EntryHistoryList extends StatelessWidget {
  const _EntryHistoryList({required this.entries, required this.accountId});

  final List<EntryWithRefs> entries;
  final int accountId;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = entries[index];
        final entry = item.entry;

        final isIncoming = switch (entry.type) {
          EntryType.income => true,
          EntryType.expense => false,
          EntryType.transfer => entry.destinationAccountId == accountId,
        };
        final amountCents = isIncoming
            ? entry.amountCents
            : -entry.amountCents;

        final subtitleParts = <String>[formatDate(entry.occurredAt)];
        if (item.category != null) {
          subtitleParts.add(item.category!.name);
        }
        if (entry.type == EntryType.transfer) {
          subtitleParts.add(
            isIncoming
                ? 'De ${item.sourceAccount.name}'
                : 'Para ${item.destinationAccount?.name ?? 'outra conta'}',
          );
        }

        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(
              isIncoming ? Icons.arrow_upward : Icons.arrow_downward,
              color: isIncoming
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.error,
            ),
            title: Text(entry.description),
            subtitle: Text(
              subtitleParts.join(' • '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Text(
              '${amountCents < 0 ? '-' : '+'}${formatMoneyCents(amountCents.abs())}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isIncoming
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        );
      },
    );
  }
}
