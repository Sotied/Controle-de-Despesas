import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';

class AccountFormState {
  const AccountFormState({
    this.type = AccountType.cash,
    this.saving = false,
    this.errorMessage,
  });

  final AccountType type;
  final bool saving;
  final String? errorMessage;

  AccountFormState copyWith({
    AccountType? type,
    bool? saving,
    String? errorMessage,
  }) {
    return AccountFormState(
      type: type ?? this.type,
      saving: saving ?? this.saving,
      errorMessage: errorMessage,
    );
  }
}

class AccountFormNotifier extends Notifier<AccountFormState> {
  @override
  AccountFormState build() => const AccountFormState();

  void init(Account? account) {
    state = AccountFormState(type: account?.type ?? AccountType.cash);
  }

  void setType(AccountType type) => state = state.copyWith(type: type);

  bool get _isCreditCard => state.type == AccountType.creditCard;

  Future<bool> save({
    required int? accountId,
    required String name,
    required String balanceText,
    required String limitText,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(errorMessage: 'Informe um nome para a conta.');
      return false;
    }

    int? initialBalanceCents;
    int? creditLimitCents;
    if (_isCreditCard) {
      if (limitText.trim().isNotEmpty) {
        creditLimitCents = parseMoneyToCents(limitText);
        if (creditLimitCents == null || creditLimitCents < 0) {
          state = state.copyWith(errorMessage: 'Informe um limite válido.');
          return false;
        }
      }
    } else if (balanceText.trim().isNotEmpty) {
      initialBalanceCents = parseMoneyToCents(balanceText);
      if (initialBalanceCents == null) {
        state = state.copyWith(
          errorMessage: 'Informe um saldo inicial válido.',
        );
        return false;
      }
    }

    state = state.copyWith(saving: true, errorMessage: null);

    final repository = ref.read(accountsRepositoryProvider);
    try {
      if (accountId != null) {
        final AccountsCompanion companion;
        if (_isCreditCard) {
          companion = AccountsCompanion(
            name: Value(trimmed),
            creditLimitCents: Value(creditLimitCents),
          );
        } else {
          companion = AccountsCompanion(
            name: Value(trimmed),
            initialBalanceCents: Value(initialBalanceCents ?? 0),
          );
        }

        await repository.updateAccount(accountId, companion);
      } else {
        await repository.createAccount(
          AccountsCompanion.insert(
            name: trimmed,
            type: state.type,
            initialBalanceCents: Value(
              _isCreditCard ? 0 : (initialBalanceCents ?? 0),
            ),
            creditLimitCents: Value(creditLimitCents),
          ),
        );
      }

      state = const AccountFormState();
      return true;
    } on Exception {
      state = state.copyWith(
        saving: false,
        errorMessage: 'Não foi possível salvar a conta.',
      );
      return false;
    }
  }
}

final accountFormProvider =
    NotifierProvider<AccountFormNotifier, AccountFormState>(
      AccountFormNotifier.new,
    );
