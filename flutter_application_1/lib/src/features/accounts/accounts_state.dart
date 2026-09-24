import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountsViewState {
  const AccountsViewState({this.showArchived = false});

  final bool showArchived;

  AccountsViewState copyWith({bool? showArchived}) {
    return AccountsViewState(showArchived: showArchived ?? this.showArchived);
  }
}

class AccountsViewNotifier extends Notifier<AccountsViewState> {
  @override
  AccountsViewState build() => const AccountsViewState();

  void toggleShowArchived() =>
      state = state.copyWith(showArchived: !state.showArchived);
}

final accountsViewProvider =
    NotifierProvider<AccountsViewNotifier, AccountsViewState>(
      AccountsViewNotifier.new,
    );
