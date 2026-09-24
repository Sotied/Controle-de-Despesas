import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';

class CategoryFormState {
  const CategoryFormState({
    this.type = CategoryType.expense,
    this.saving = false,
    this.errorMessage,
  });

  final CategoryType type;
  final bool saving;
  final String? errorMessage;

  CategoryFormState copyWith({
    CategoryType? type,
    bool? saving,
    String? errorMessage,
  }) {
    return CategoryFormState(
      type: type ?? this.type,
      saving: saving ?? this.saving,
      errorMessage: errorMessage,
    );
  }
}

class CategoryFormNotifier extends Notifier<CategoryFormState> {
  @override
  CategoryFormState build() => const CategoryFormState();

  void init(Category? category, CategoryType initialType) {
    state = CategoryFormState(type: category?.type ?? initialType);
  }

  void setType(CategoryType type) => state = state.copyWith(type: type);

  Future<bool> save({required int? categoryId, required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(errorMessage: 'Informe um nome para a categoria.');
      return false;
    }

    state = state.copyWith(saving: true, errorMessage: null);

    try {
      if (categoryId != null) {
        await ref
            .read(categoriesRepositoryProvider)
            .updateCategory(
              categoryId,
              CategoriesCompanion(name: Value(trimmed)),
            );
      } else {
        await ref
            .read(categoriesRepositoryProvider)
            .createCategory(
              CategoriesCompanion.insert(name: trimmed, type: state.type),
            );
      }
      state = const CategoryFormState();
      return true;
    } on SqliteException catch (error) {
      state = state.copyWith(
        saving: false,
        errorMessage: error.resultCode == 19
            ? 'Já existe uma categoria "$trimmed" desse tipo.'
            : 'Não foi possível salvar a categoria.',
      );
      return false;
    } on Exception {
      state = state.copyWith(
        saving: false,
        errorMessage: 'Não foi possível salvar a categoria.',
      );
      return false;
    }
  }
}

final categoryFormProvider =
    NotifierProvider<CategoryFormNotifier, CategoryFormState>(
      CategoryFormNotifier.new,
    );
