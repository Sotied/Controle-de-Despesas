import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_application_1/src/repositories/financial_entries_repository.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';

class NewEntryFormState {
  const NewEntryFormState({
    this.entryId,
    this.type = EntryType.expense,
    this.categoryId,
    this.sourceAccountId,
    this.destinationAccountId,
    this.date,
    this.saving = false,
    this.loaded = false,
    this.errorMessage,
  });

  final int? entryId;
  final EntryType type;
  final int? categoryId;
  final int? sourceAccountId;
  final int? destinationAccountId;
  final DateTime? date;
  final bool saving;
  final bool loaded;
  final String? errorMessage;

  bool get isTransfer => type == EntryType.transfer;
  bool get isEditing => entryId != null;

  NewEntryFormState copyWith({
    int? entryId,
    EntryType? type,
    Object? categoryId = _unset,
    Object? sourceAccountId = _unset,
    Object? destinationAccountId = _unset,
    DateTime? date,
    bool? saving,
    bool? loaded,
    String? errorMessage,
  }) {
    return NewEntryFormState(
      entryId: entryId ?? this.entryId,
      type: type ?? this.type,
      categoryId: identical(categoryId, _unset)
          ? this.categoryId
          : categoryId as int?,
      sourceAccountId: identical(sourceAccountId, _unset)
          ? this.sourceAccountId
          : sourceAccountId as int?,
      destinationAccountId: identical(destinationAccountId, _unset)
          ? this.destinationAccountId
          : destinationAccountId as int?,
      date: date ?? this.date,
      saving: saving ?? this.saving,
      loaded: loaded ?? this.loaded,
      errorMessage: errorMessage,
    );
  }

  static const _unset = Object();
}

class NewEntryFormNotifier extends Notifier<NewEntryFormState> {
  @override
  NewEntryFormState build() => const NewEntryFormState();

  DateTime get effectiveDate => state.date ?? DateTime.now();

  void beginEdit(EntryWithRefs item) {
    state = NewEntryFormState(
      entryId: item.entry.id,
      type: item.entry.type,
      categoryId: item.entry.categoryId,
      sourceAccountId: item.entry.sourceAccountId,
      destinationAccountId: item.entry.destinationAccountId,
      date: item.entry.occurredAt,
      loaded: true,
    );
  }

  void selectType(EntryType type) {
    state = state.copyWith(
      type: type,
      categoryId: null,
      destinationAccountId: null,
      errorMessage: null,
    );
  }

  void setCategory(int? categoryId) =>
      state = state.copyWith(categoryId: categoryId);

  void setSource(int? accountId) =>
      state = state.copyWith(sourceAccountId: accountId);

  void setDestination(int? accountId) =>
      state = state.copyWith(destinationAccountId: accountId);

  void setDate(DateTime date) => state = state.copyWith(date: date);

  String? _validate({
    required String descriptionText,
    required String amountText,
  }) {
    final amountCents = parseMoneyToCents(amountText);
    if (amountCents == null || amountCents <= 0) {
      return 'Informe um valor válido.';
    }

    final description = descriptionText.trim();
    if (description.isEmpty) {
      return state.type == EntryType.income
          ? 'Informe a origem.'
          : 'Informe a descrição.';
    }

    if (state.type == EntryType.expense && state.categoryId == null) {
      return 'Selecione a categoria.';
    }

    if (state.sourceAccountId == null) {
      return state.isTransfer
          ? 'Selecione a conta de origem.'
          : 'Selecione a conta.';
    }

    if (state.isTransfer) {
      if (state.destinationAccountId == null) {
        return 'Selecione a conta de destino.';
      }
      if (state.destinationAccountId == state.sourceAccountId) {
        return 'Selecione contas diferentes.';
      }
    }

    return null;
  }

  Future<bool> confirm({
    required String descriptionText,
    required String amountText,
  }) async {
    final error = _validate(
      descriptionText: descriptionText,
      amountText: amountText,
    );

    if (error != null) {
      state = state.copyWith(errorMessage: error, saving: false);
      return false;
    }

    state = state.copyWith(saving: true, errorMessage: null);

    final repository = ref.read(financialEntriesRepositoryProvider);
    try {
      if (state.isEditing) {
        await repository.updateEntry(
          state.entryId!,
          FinancialEntriesCompanion(
            description: Value(descriptionText.trim()),
            type: Value(state.type),
            amountCents: Value(parseMoneyToCents(amountText)!),
            sourceAccountId: Value(state.sourceAccountId!),
            destinationAccountId: Value(
              state.isTransfer ? state.destinationAccountId : null,
            ),
            categoryId: Value(state.isTransfer ? null : state.categoryId),
            occurredAt: Value(effectiveDate),
          ),
        );
      } else {
        await repository.createEntry(
          FinancialEntriesCompanion.insert(
            description: descriptionText.trim(),
            type: state.type,
            amountCents: parseMoneyToCents(amountText)!,
            sourceAccountId: state.sourceAccountId!,
            destinationAccountId: Value(
              state.isTransfer ? state.destinationAccountId : null,
            ),
            categoryId: Value(state.isTransfer ? null : state.categoryId),
            occurredAt: effectiveDate,
          ),
        );
      }

      state = const NewEntryFormState();
      return true;
    } on Exception {
      state = state.copyWith(
        saving: false,
        errorMessage: 'Não foi possível salvar o lançamento.',
      );
      return false;
    }
  }
}

final newEntryFormProvider =
    NotifierProvider<NewEntryFormNotifier, NewEntryFormState>(
      NewEntryFormNotifier.new,
    );
