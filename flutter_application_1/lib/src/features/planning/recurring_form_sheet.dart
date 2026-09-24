import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/features/planning/recurring_form_state.dart';
import 'package:flutter_application_1/src/providers/accounts_providers.dart';
import 'package:flutter_application_1/src/providers/categories_providers.dart';
import 'package:flutter_application_1/src/repositories/accounts_repository.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecurringFormSheet extends ConsumerStatefulWidget {
  const RecurringFormSheet({super.key, this.rule});

  final RecurringEntry? rule;

  @override
  ConsumerState<RecurringFormSheet> createState() => _RecurringFormSheetState();
}

class _RecurringFormSheetState extends ConsumerState<RecurringFormSheet> {
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.rule?.description);
  late final TextEditingController _amountController = TextEditingController(
    text: widget.rule == null
        ? ''
        : formatCentsAsInput(widget.rule!.amountCents),
  );
  late final TextEditingController _dayController = TextEditingController(
    text: widget.rule == null ? '' : widget.rule!.dayOfMonth.toString(),
  );

  bool get _isEditing => widget.rule != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(recurringFormProvider.notifier).init(widget.rule);
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await ref
        .read(recurringFormProvider.notifier)
        .save(
          ruleId: widget.rule?.id,
          descriptionText: _descriptionController.text,
          amountText: _amountController.text,
          dayText: _dayController.text,
        );

    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(recurringFormProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accounts =
        ref.watch(accountsWithBalanceProvider).value ??
        const <AccountWithBalance>[];
    final categoryType = form.type == EntryType.expense
        ? CategoryType.expense
        : CategoryType.income;
    final categories =
        ref.watch(
              categoriesByTypeProvider((categoryType, includeArchived: false)),
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
              _isEditing ? 'Editar regra' : 'Nova conta recorrente',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _descriptionController,
              autofocus: !_isEditing,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText: 'Ex.: Aluguel, streaming…',
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Despesa'),
                  avatar: const Icon(Icons.arrow_downward, size: 18),
                  selected: form.type == EntryType.expense,
                  onSelected: _isEditing
                      ? null
                      : (_) =>
                            ref.read(recurringFormProvider.notifier).setType(
                              EntryType.expense,
                            ),
                ),
                ChoiceChip(
                  label: const Text('Receita'),
                  avatar: const Icon(Icons.arrow_upward, size: 18),
                  selected: form.type == EntryType.income,
                  onSelected: _isEditing
                      ? null
                      : (_) =>
                            ref.read(recurringFormProvider.notifier).setType(
                              EntryType.income,
                            ),
                ),
              ],
            ),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Valor',
                prefixText: r'R$ ',
                hintText: '0,00',
              ),
            ),
            DropdownButtonFormField<int>(
              key: ValueKey('recurring-category-${form.type.name}'),
              initialValue: form.categoryId,
              decoration: const InputDecoration(
                labelText: 'Categoria (opcional)',
              ),
              items: [
                for (final category in categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
              ],
              onChanged: (value) =>
                  ref.read(recurringFormProvider.notifier).setCategory(value),
            ),
            DropdownButtonFormField<int>(
              key: ValueKey('recurring-account-${form.accountId}'),
              initialValue: form.accountId,
              decoration: const InputDecoration(labelText: 'Conta'),
              items: [
                for (final item in accounts)
                  DropdownMenuItem(
                    value: item.account.id,
                    child: Text(item.account.name),
                  ),
              ],
              onChanged: (value) =>
                  ref.read(recurringFormProvider.notifier).setAccount(value),
            ),
            TextField(
              controller: _dayController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 2,
              decoration: const InputDecoration(
                labelText: 'Dia do vencimento',
                hintText: '1 a 28',
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
