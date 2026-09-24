import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/features/planning/budget_form_state.dart';
import 'package:flutter_application_1/src/providers/categories_providers.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetFormSheet extends ConsumerStatefulWidget {
  const BudgetFormSheet({super.key, this.budget});

  final Budget? budget;

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  late final TextEditingController _amountController = TextEditingController(
    text: widget.budget == null
        ? ''
        : formatCentsAsInput(widget.budget!.amountCents),
  );

  bool get _isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(budgetFormProvider.notifier).init(widget.budget);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final form = ref.read(budgetFormProvider);
    final saved = await ref
        .read(budgetFormProvider.notifier)
        .save(
          budgetId: widget.budget?.id,
          categoryId: form.categoryId,
          amountText: _amountController.text,
        );

    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(budgetFormProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final categories =
        ref.watch(
              categoriesByTypeProvider(
                (CategoryType.expense, includeArchived: false),
              ),
            ).value ??
            const <Category>[];

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
              _isEditing ? 'Editar orçamento' : 'Novo orçamento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            DropdownButtonFormField<int>(
              key: ValueKey('budget-category-${form.categoryId}'),
              initialValue: form.categoryId,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: [
                for (final category in categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
              ],
              onChanged: _isEditing
                  ? null
                  : (value) =>
                        ref.read(budgetFormProvider.notifier).setCategory(
                          value,
                        ),
            ),
            TextField(
              controller: _amountController,
              autofocus: !_isEditing,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Limite mensal',
                prefixText: r'R$ ',
                hintText: '0,00',
              ),
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
