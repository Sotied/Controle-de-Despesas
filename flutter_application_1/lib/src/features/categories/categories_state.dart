import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';

class CategoriesViewState {
  const CategoriesViewState({
    this.type = CategoryType.expense,
    this.showArchived = false,
  });

  final CategoryType type;
  final bool showArchived;

  CategoriesViewState copyWith({CategoryType? type, bool? showArchived}) {
    return CategoriesViewState(
      type: type ?? this.type,
      showArchived: showArchived ?? this.showArchived,
    );
  }
}

class CategoriesViewNotifier extends Notifier<CategoriesViewState> {
  @override
  CategoriesViewState build() => const CategoriesViewState();

  void setType(CategoryType type) => state = state.copyWith(type: type);

  void toggleShowArchived() =>
      state = state.copyWith(showArchived: !state.showArchived);
}

final categoriesViewProvider =
    NotifierProvider<CategoriesViewNotifier, CategoriesViewState>(
      CategoriesViewNotifier.new,
    );
