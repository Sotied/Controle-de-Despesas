import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_application_1/src/repositories/recurring_entries_repository.dart';

final recurringBootstrapProvider = Provider<void>((ref) {
  ref.watch(recurringEntriesRepositoryProvider).generateDueInstances();
});

final recurringEntriesProvider =
    StreamProvider<List<RecurringEntryWithRefs>>((ref) {
      return ref.watch(recurringEntriesRepositoryProvider).watchAll();
    });
