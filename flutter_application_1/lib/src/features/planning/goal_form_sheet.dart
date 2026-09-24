import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/features/planning/goal_states.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoalFormSheet extends ConsumerStatefulWidget {
  const GoalFormSheet({super.key, this.goal});

  final Goal? goal;

  @override
  ConsumerState<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<GoalFormSheet> {
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.goal?.description);
  late final TextEditingController _targetController = TextEditingController(
    text: widget.goal == null
        ? ''
        : formatCentsAsInput(widget.goal!.targetAmountCents),
  );
  late DateTime _targetDate =
      widget.goal?.targetDate ?? DateTime.now().add(const Duration(days: 30));
  late final TextEditingController _dateController = TextEditingController(
    text: formatDate(_targetDate),
  );

  bool get _isEditing => widget.goal != null;

  @override
  void dispose() {
    _descriptionController.dispose();
    _targetController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate.isBefore(DateTime.now())
          ? DateTime.now()
          : _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _targetDate = picked;
        _dateController.text = formatDate(picked);
      });
    }
  }

  Future<void> _save() async {
    final saved = await ref
        .read(goalFormProvider.notifier)
        .save(
          goalId: widget.goal?.id,
          descriptionText: _descriptionController.text,
          targetText: _targetController.text,
          targetDate: _targetDate,
        );

    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(goalFormProvider);
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
              _isEditing ? 'Editar meta' : 'Nova meta',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _descriptionController,
              autofocus: !_isEditing,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText: 'Ex.: Viagem de férias, reserva de emergência…',
              ),
            ),
            TextField(
              controller: _targetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Valor alvo',
                prefixText: r'R$ ',
                hintText: '0,00',
              ),
            ),
            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: 'Prazo',
                suffixIcon: Icon(Icons.calendar_today),
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

class GoalAporteSheet extends ConsumerStatefulWidget {
  const GoalAporteSheet({super.key, required this.goal});

  final Goal goal;

  @override
  ConsumerState<GoalAporteSheet> createState() => _GoalAporteSheetState();
}

class _GoalAporteSheetState extends ConsumerState<GoalAporteSheet> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await ref
        .read(goalAporteProvider.notifier)
        .register(goalId: widget.goal.id, amountText: _amountController.text);

    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(goalAporteProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final remaining = widget.goal.targetAmountCents - widget.goal.savedAmountCents;

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
              'Registrar aporte',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '${widget.goal.description} • Restam ${formatMoneyCents(remaining < 0 ? 0 : remaining)}',
              style: Theme.of(context).textTheme.bodyMedium,
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
                labelText: 'Valor do aporte',
                prefixText: r'R$ ',
                hintText: '0,00',
              ),
              onSubmitted: (_) => form.saving ? null : _save(),
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
                  : const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}
