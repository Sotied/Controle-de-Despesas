import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/repositories/accounts_repository.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';

final accountsWithBalanceProvider =
    StreamProvider<List<AccountWithBalance>>((ref) {
      return ref.watch(accountsRepositoryProvider).watchAllWithBalance();
    });

final accountsListProvider =
    StreamProvider.family<List<AccountWithBalance>, bool>((
      ref,
      includeArchived,
    ) {
      return ref
          .watch(accountsRepositoryProvider)
          .watchAllWithBalance(includeArchived: includeArchived);
    });

final accountWithBalanceByIdProvider =
    StreamProvider.family<AccountWithBalance?, int>((ref, id) {
      return ref
          .watch(accountsRepositoryProvider)
          .watchAllWithBalance(includeArchived: true)
          .map((accounts) {
            for (final item in accounts) {
              if (item.account.id == id) {
                return item;
              }
            }
            return null;
          });
    });

final consolidatedBalanceProvider = StreamProvider<int>((ref) {
  return ref.watch(accountsRepositoryProvider).watchConsolidatedBalance();
});

final accountByIdProvider = StreamProvider.family<Account?, int>((ref, id) {
  return ref.watch(accountsRepositoryProvider).watchById(id);
});
