import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';

class RecurringFormState {
  const RecurringFormState({
    this.type = EntryType.expense,
    this.categoryId,
    this.accountId,
    this.saving = false,
    this.errorMessage,
  });

  final EntryType type;
  final int? categoryId;
  final int? accountId;
  final bool saving;
  final String? errorMessage;

  RecurringFormState copyWith({
    EntryType? type,
    Object? categoryId = _unset,
    Object? accountId = _unset,
    bool? saving,
    String? errorMessage,
  }) {
    return RecurringFormState(
      type: type ?? this.type,
      categoryId: identical(categoryId, _unset)
          ? this.categoryId
          : categoryId as int?,
      accountId: identical(accountId, _unset)
          ? this.accountId
          : accountId as int?,
      saving: saving ?? this.saving,
      errorMessage: errorMessage,
    );
  }

  static const _unset = Object();
}

class RecurringFormNotifier extends Notifier<RecurringFormState> {
  @override
  RecurringFormState build() => const RecurringFormState();

  void init(RecurringEntry? rule) {
    state = RecurringFormState(
      type: rule?.type ?? EntryType.expense,
      categoryId: rule?.categoryId,
      accountId: rule?.accountId,
    );
  }

  void setType(EntryType type) =>
      state = state.copyWith(type: type, categoryId: null);

  void setCategory(int? categoryId) =>
      state = state.copyWith(categoryId: categoryId);

  void setAccount(int? accountId) =>
      state = state.copyWith(accountId: accountId);

  Future<bool> save({
    required int? ruleId,
    required String descriptionText,
    required String amountText,
    required String dayText,
  }) async {
    final description = descriptionText.trim();
    if (description.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Informe uma descrição para a regra.',
      );
      return false;
    }

    final amountCents = parseMoneyToCents(amountText);
    if (amountCents == null || amountCents <= 0) {
      state = state.copyWith(errorMessage: 'Informe um valor válido.');
      return false;
    }

    final day = int.tryParse(dayText.trim());
    if (day == null || day < 1 || day > 28) {
      state = state.copyWith(
        errorMessage: 'Informe um dia do mês entre 1 e 28.',
      );
      return false;
    }

    if (state.accountId == null) {
      state = state.copyWith(errorMessage: 'Selecione a conta.');
      return false;
    }

    state = state.copyWith(saving: true, errorMessage: null);

    final repository = ref.read(recurringEntriesRepositoryProvider);
    try {
      final today = DateTime.now();
      final startDate = DateTime(today.year, today.month, today.day);

      if (ruleId != null) {
        await repository.update(
          ruleId,
          RecurringEntriesCompanion(
            description: Value(description),
            type: Value(state.type),
            amountCents: Value(amountCents),
            categoryId: Value(state.categoryId),
            accountId: Value(state.accountId!),
            dayOfMonth: Value(day),
          ),
        );
      } else {
        await repository.create(
          RecurringEntriesCompanion.insert(
            description: description,
            type: state.type,
            amountCents: amountCents,
            accountId: state.accountId!,
            dayOfMonth: day,
            startDate: startDate,
            categoryId: Value(state.categoryId),
          ),
        );
      }

      state = const RecurringFormState();
      return true;
    } on Exception {
      state = state.copyWith(
        saving: false,
        errorMessage: 'Não foi possível salvar a regra.',
      );
      return false;
    }
  }
}

final recurringFormProvider =
    NotifierProvider<RecurringFormNotifier, RecurringFormState>(
      RecurringFormNotifier.new,
    );
