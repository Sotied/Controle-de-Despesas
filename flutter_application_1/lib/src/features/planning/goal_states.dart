import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';

class GoalFormState {
  const GoalFormState({this.saving = false, this.errorMessage});

  final bool saving;
  final String? errorMessage;

  GoalFormState copyWith({bool? saving, String? errorMessage}) {
    return GoalFormState(
      saving: saving ?? this.saving,
      errorMessage: errorMessage,
    );
  }
}

class GoalFormNotifier extends Notifier<GoalFormState> {
  @override
  GoalFormState build() => const GoalFormState();

  Future<bool> save({
    required int? goalId,
    required String descriptionText,
    required String targetText,
    required DateTime targetDate,
  }) async {
    final description = descriptionText.trim();
    if (description.isEmpty) {
      state = state.copyWith(errorMessage: 'Informe uma descrição para a meta.');
      return false;
    }

    final targetCents = parseMoneyToCents(targetText);
    if (targetCents == null || targetCents <= 0) {
      state = state.copyWith(errorMessage: 'Informe um valor alvo válido.');
      return false;
    }

    state = state.copyWith(saving: true, errorMessage: null);

    final repository = ref.read(goalsRepositoryProvider);
    try {
      if (goalId != null) {
        await repository.update(
          goalId,
          GoalsCompanion(
            description: Value(description),
            targetAmountCents: Value(targetCents),
            targetDate: Value(targetDate),
          ),
        );
      } else {
        await repository.create(
          GoalsCompanion.insert(
            description: description,
            targetAmountCents: targetCents,
            targetDate: targetDate,
          ),
        );
      }

      state = const GoalFormState();
      return true;
    } on Exception {
      state = state.copyWith(
        saving: false,
        errorMessage: 'Não foi possível salvar a meta.',
      );
      return false;
    }
  }
}

class GoalAporteState {
  const GoalAporteState({this.saving = false, this.errorMessage});

  final bool saving;
  final String? errorMessage;

  GoalAporteState copyWith({bool? saving, String? errorMessage}) {
    return GoalAporteState(
      saving: saving ?? this.saving,
      errorMessage: errorMessage,
    );
  }
}

class GoalAporteNotifier extends Notifier<GoalAporteState> {
  @override
  GoalAporteState build() => const GoalAporteState();

  Future<bool> register({
    required int goalId,
    required String amountText,
  }) async {
    final amountCents = parseMoneyToCents(amountText);
    if (amountCents == null || amountCents <= 0) {
      state = state.copyWith(errorMessage: 'Informe um valor válido.');
      return false;
    }

    state = state.copyWith(saving: true, errorMessage: null);

    try {
      await ref.read(goalsRepositoryProvider).addProgress(goalId, amountCents);
      state = const GoalAporteState();
      return true;
    } on Exception {
      state = state.copyWith(
        saving: false,
        errorMessage: 'Não foi possível registrar o aporte.',
      );
      return false;
    }
  }
}

final goalFormProvider =
    NotifierProvider<GoalFormNotifier, GoalFormState>(GoalFormNotifier.new);

final goalAporteProvider =
    NotifierProvider<GoalAporteNotifier, GoalAporteState>(
      GoalAporteNotifier.new,
    );
