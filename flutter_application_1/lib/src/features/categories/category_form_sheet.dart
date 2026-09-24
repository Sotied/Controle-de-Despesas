import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/features/categories/category_form_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({
    super.key,
    this.category,
    required this.initialType,
  });

  final Category? category;
  final CategoryType initialType;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.category?.name,
  );

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(categoryFormProvider.notifier).init(
        widget.category,
        widget.initialType,
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await ref
        .read(categoryFormProvider.notifier)
        .save(categoryId: widget.category?.id, name: _nameController.text);

    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(categoryFormProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Text(
              _isEditing ? 'Editar categoria' : 'Nova categoria',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _nameController,
              autofocus: !_isEditing,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Ex.: Alimentação',
              ),
              onSubmitted: (_) => form.saving ? null : _save(),
            ),
            SegmentedButton<CategoryType>(
              selected: {form.type},
              segments: const [
                ButtonSegment(
                  value: CategoryType.expense,
                  label: Text('Despesa'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: CategoryType.income,
                  label: Text('Receita'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              onSelectionChanged: _isEditing
                  ? null
                  : (selection) => ref
                        .read(categoryFormProvider.notifier)
                        .setType(selection.first),
            ),
            if (form.errorMessage != null)
              Text(
                form.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            FilledButton(
              onPressed: form.saving ? null : _save,
              child: form.saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Salvar alterações' : 'Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}
