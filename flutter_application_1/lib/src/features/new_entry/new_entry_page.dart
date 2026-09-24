import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/features/new_entry/new_entry_state.dart';
import 'package:flutter_application_1/src/providers/accounts_providers.dart';
import 'package:flutter_application_1/src/providers/categories_providers.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_application_1/src/repositories/accounts_repository.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewEntryPage extends ConsumerStatefulWidget {
  const NewEntryPage({super.key, this.entryId});

  final int? entryId;

  @override
  ConsumerState<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends ConsumerState<NewEntryPage> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();

  bool get _isEditing => widget.entryId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadEntry();
    } else {
      _dateController.text = formatDate(
        ref.read(newEntryFormProvider.notifier).effectiveDate,
      );
    }
  }

  Future<void> _loadEntry() async {
    final entry = await ref
        .read(financialEntriesRepositoryProvider)
        .findEntryById(widget.entryId!);

    if (!mounted) return;

    if (entry == null) {
      Navigator.of(context).pop();
      return;
    }

    ref.read(newEntryFormProvider.notifier).beginEdit(entry);
    setState(() {
      _descriptionController.text = entry.entry.description;
      _amountController.text = formatCentsAsInput(entry.entry.amountCents);
      _dateController.text = formatDate(entry.entry.occurredAt);
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final notifier = ref.read(newEntryFormProvider.notifier);
    final picked = await showDatePicker(
      context: context,
      initialDate: notifier.effectiveDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      notifier.setDate(picked);
      _dateController.text = formatDate(picked);
    }
  }

  Future<void> _confirm() async {
    final saved = await ref
        .read(newEntryFormProvider.notifier)
        .confirm(
          descriptionText: _descriptionController.text,
          amountText: _amountController.text,
        );

    if (saved && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Lançamento atualizado.'
                  : 'Lançamento adicionado.',
            ),
          ),
        );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(newEntryFormProvider);

    if (_isEditing && !form.loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar lançamento')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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

    final showCategory = !form.isTransfer;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar lançamento' : 'Novo lançamento'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Despesa'),
                    avatar: const Icon(Icons.arrow_downward, size: 18),
                    selected: form.type == EntryType.expense,
                    onSelected: (_) => ref
                        .read(newEntryFormProvider.notifier)
                        .selectType(EntryType.expense),
                  ),
                  ChoiceChip(
                    label: const Text('Receita'),
                    avatar: const Icon(Icons.arrow_upward, size: 18),
                    selected: form.type == EntryType.income,
                    onSelected: (_) => ref
                        .read(newEntryFormProvider.notifier)
                        .selectType(EntryType.income),
                  ),
                  ChoiceChip(
                    label: const Text('Transferência'),
                    avatar: const Icon(Icons.swap_horiz, size: 18),
                    selected: form.isTransfer,
                    onSelected: (_) => ref
                        .read(newEntryFormProvider.notifier)
                        .selectType(EntryType.transfer),
                  ),
                ],
              ),
              TextField(
                controller: _amountController,
                autofocus: true,
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
              TextField(
                controller: _descriptionController,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: form.type == EntryType.income
                      ? 'Origem'
                      : 'Descrição',
                  hintText: form.type == EntryType.income
                      ? 'Ex.: Salário, freelance…'
                      : form.isTransfer
                      ? 'Ex.: PIX para a reserva'
                      : 'Ex.: Mercado, transporte…',
                ),
              ),
              if (showCategory)
                DropdownButtonFormField<int>(
                  key: ValueKey('category-${form.type.name}'),
                  initialValue: form.categoryId,
                  decoration: InputDecoration(
                    labelText: form.type == EntryType.expense
                        ? 'Categoria'
                        : 'Categoria (opcional)',
                  ),
                  items: [
                    for (final category in categories)
                      DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                  ],
                  onChanged: (value) => ref
                      .read(newEntryFormProvider.notifier)
                      .setCategory(value),
                ),
              DropdownButtonFormField<int>(
                key: const ValueKey('source-account'),
                initialValue: form.sourceAccountId,
                decoration: InputDecoration(
                  labelText: form.isTransfer ? 'Conta de origem' : 'Conta',
                ),
                items: [
                  for (final item in accounts)
                    DropdownMenuItem(
                      value: item.account.id,
                      child: Text(item.account.name),
                    ),
                ],
                onChanged: (value) =>
                    ref.read(newEntryFormProvider.notifier).setSource(value),
              ),
              if (form.isTransfer)
                DropdownButtonFormField<int>(
                  key: const ValueKey('destination-account'),
                  initialValue: form.destinationAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Conta de destino',
                  ),
                  items: [
                    for (final item in accounts)
                      DropdownMenuItem(
                        value: item.account.id,
                        child: Text(item.account.name),
                      ),
                  ],
                  onChanged: (value) => ref
                      .read(newEntryFormProvider.notifier)
                      .setDestination(value),
                ),
              TextField(
                controller: _dateController,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Data',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
              if (form.errorMessage != null)
                Text(
                  form.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              FilledButton(
                onPressed: form.saving ? null : _confirm,
                child: form.saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirmar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
