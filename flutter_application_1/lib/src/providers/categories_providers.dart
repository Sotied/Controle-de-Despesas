import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';

typedef CategoryScope = (CategoryType, {bool includeArchived});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoriesRepositoryProvider).watchCategories();
});

final categoriesByTypeProvider =
    StreamProvider.family<List<Category>, CategoryScope>((ref, scope) {
      return ref.watch(categoriesRepositoryProvider).watchCategories(
        type: scope.$1,
        includeArchived: scope.includeArchived,
      );
    });
