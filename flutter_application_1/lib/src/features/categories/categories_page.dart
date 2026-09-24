import 'package:drift/native.dart' show SqliteException;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/features/categories/categories_state.dart';
import 'package:flutter_application_1/src/features/categories/category_form_sheet.dart';
import 'package:flutter_application_1/src/providers/categories_providers.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_application_1/src/shared/widgets/async_value_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  Future<void> _openForm(
    BuildContext context, {
    required CategoryType selectedType,
    Category? category,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CategoryFormSheet(
        category: category,
        initialType: selectedType,
      ),
    );

    if (saved ?? false) {
      if (!context.mounted) return;
      final message = category == null
          ? 'Categoria adicionada.'
          : 'Categoria atualizada.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir categoria'),
        content: Text(
          'Deseja excluir "${category.name}"? Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await ref
            .read(categoriesRepositoryProvider)
            .deleteCategory(category.id);
      } on SqliteException catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                error.resultCode == 19
                    ? 'Não é possível excluir "${category.name}" porque existem lançamentos vinculados. Arquive-a para ocultar.'
                    : 'Não foi possível excluir a categoria.',
              ),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(categoriesViewProvider);
    final categoriesAsync = ref.watch(
      categoriesByTypeProvider(
        (viewState.type, includeArchived: viewState.showArchived),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        actions: [
          IconButton(
            tooltip: viewState.showArchived
                ? 'Ocultar arquivadas'
                : 'Mostrar arquivadas',
            onPressed: () =>
                ref.read(categoriesViewProvider.notifier).toggleShowArchived(),
            icon: Icon(
              viewState.showArchived ? Icons.visibility_off : Icons.visibility,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, selectedType: viewState.type),
        icon: const Icon(Icons.add),
        label: const Text('Nova categoria'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<CategoryType>(
              selected: {viewState.type},
              segments: const [
                ButtonSegment(
                  value: CategoryType.expense,
                  label: Text('Despesas'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: CategoryType.income,
                  label: Text('Receitas'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              onSelectionChanged: (selection) => ref
                  .read(categoriesViewProvider.notifier)
                  .setType(selection.first),
            ),
          ),
          Expanded(
            child: AsyncValueView(
              asyncValue: categoriesAsync,
              dataBuilder: (context, categories) => _CategoriesList(
                categories: categories,
                showArchived: viewState.showArchived,
                onEdit: (category) => _openForm(
                  context,
                  selectedType: viewState.type,
                  category: category,
                ),
                onToggleArchived: (category) => ref
                    .read(categoriesRepositoryProvider)
                    .setCategoryArchived(
                      category.id,
                      archived: !category.isArchived,
                    ),
                onDelete: (category) => _confirmDelete(context, ref, category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesList extends StatelessWidget {
  const _CategoriesList({
    required this.categories,
    required this.showArchived,
    required this.onEdit,
    required this.onToggleArchived,
    required this.onDelete,
  });

  final List<Category> categories;
  final bool showArchived;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onToggleArchived;
  final ValueChanged<Category> onDelete;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Icon(
              Icons.category_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
            ),
            Text(
              showArchived
                  ? 'Nenhuma categoria encontrada.'
                  : 'Nenhuma categoria ainda.\nUse o botão abaixo para criar a primeira.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final category = categories[index];
        final isExpense = category.type == CategoryType.expense;

        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isExpense
                  ? Theme.of(context).colorScheme.error.withAlpha(40)
                  : Theme.of(context).colorScheme.secondary.withAlpha(40),
              child: Icon(
                isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                size: 20,
                color: isExpense
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.secondary,
              ),
            ),
            title: Text(
              category.name,
              style: category.isArchived
                  ? TextStyle(
                      color: Theme.of(context).disabledColor,
                      decoration: TextDecoration.lineThrough,
                    )
                  : null,
            ),
            subtitle: category.isArchived
                ? const Text('Arquivada')
                : null,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit(category);
                  case 'archive':
                    onToggleArchived(category);
                  case 'delete':
                    onDelete(category);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar'),
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      category.isArchived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                    ),
                    title: Text(
                      category.isArchived ? 'Restaurar' : 'Arquivar',
                    ),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline),
                    title: Text('Excluir'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
