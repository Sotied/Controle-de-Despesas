import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';

class BudgetFormState {
  const BudgetFormState({this.categoryId, this.saving = false, this.errorMessage});

  final int? categoryId;
  final bool saving;
  final String? errorMessage;

  BudgetFormState copyWith({
    Object? categoryId = _unset,
    bool? saving,
    String? errorMessage,
  }) {
    return BudgetFormState(
      categoryId: identical(categoryId, _unset)
          ? this.categoryId
          : categoryId as int?,
      saving: saving ?? this.saving,
      errorMessage: errorMessage,
    );
  }

  static const _unset = Object();
}

class BudgetFormNotifier extends Notifier<BudgetFormState> {
  @override
  BudgetFormState build() => const BudgetFormState();

  void init(Budget? budget) {
    state = BudgetFormState(categoryId: budget?.categoryId);
  }

  void setCategory(int? categoryId) =>
      state = state.copyWith(categoryId: categoryId);

  Future<bool> save({
    required int? budgetId,
    required int? categoryId,
    required String amountText,
  }) async {
    if (categoryId == null) {
      state = state.copyWith(errorMessage: 'Selecione a categoria.');
      return false;
    }

    final amountCents = parseMoneyToCents(amountText);
    if (amountCents == null || amountCents <= 0) {
      state = state.copyWith(errorMessage: 'Informe um limite válido.');
      return false;
    }

    state = state.copyWith(saving: true, errorMessage: null);

    final repository = ref.read(budgetsRepositoryProvider);
    try {
      if (budgetId != null) {
        await repository.update(
          budgetId,
          BudgetsCompanion(amountCents: Value(amountCents)),
        );
      } else {
        await repository.create(
          BudgetsCompanion.insert(
            categoryId: categoryId,
            amountCents: amountCents,
          ),
        );
      }

      state = const BudgetFormState();
      return true;
    } on SqliteException catch (error) {
      state = state.copyWith(
        saving: false,
        errorMessage: error.resultCode == 19
            ? 'Já existe um orçamento para essa categoria.'
            : 'Não foi possível salvar o orçamento.',
      );
      return false;
    } on Exception {
      state = state.copyWith(
        saving: false,
        errorMessage: 'Não foi possível salvar o orçamento.',
      );
      return false;
    }
  }
}

final budgetFormProvider =
    NotifierProvider<BudgetFormNotifier, BudgetFormState>(
      BudgetFormNotifier.new,
    );
