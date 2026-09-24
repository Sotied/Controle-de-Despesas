import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/features/accounts/account_form_state.dart';
import 'package:flutter_application_1/src/shared/utils/account_visuals.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class AccountFormSheet extends ConsumerStatefulWidget {
  const AccountFormSheet({super.key, this.account});

  final Account? account;

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.account?.name,
  );
  late final TextEditingController _balanceController = TextEditingController(
    text: widget.account == null ||
            widget.account!.type == AccountType.creditCard
        ? ''
        : formatCentsAsInput(widget.account!.initialBalanceCents),
  );
  late final TextEditingController _limitController = TextEditingController(
    text: widget.account?.creditLimitCents == null
        ? ''
        : formatCentsAsInput(widget.account!.creditLimitCents!),
  );

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(accountFormProvider.notifier).init(widget.account);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final form = ref.read(accountFormProvider);
    final saved = await ref
        .read(accountFormProvider.notifier)
        .save(
          accountId: widget.account?.id,
          name: _nameController.text,
          balanceText: form.type == AccountType.creditCard
              ? ''
              : _balanceController.text,
          limitText: form.type == AccountType.creditCard
              ? _limitController.text
              : '',
        );

    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(accountFormProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isCreditCard = form.type == AccountType.creditCard;

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
              _isEditing ? 'Editar conta' : 'Nova conta',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _nameController,
              autofocus: !_isEditing,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Ex.: Banco principal',
              ),
              onSubmitted: (_) => form.saving ? null : _save(),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in AccountType.values)
                  ChoiceChip(
                    label: Text(accountTypeLabel(type)),
                    avatar: Icon(accountTypeIcon(type), size: 18),
                    selected: form.type == type,
                    onSelected: _isEditing
                        ? null
                        : (_) =>
                              ref.read(accountFormProvider.notifier).setType(
                                type,
                              ),
                  ),
              ],
            ),
            if (!isCreditCard)
              TextField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Saldo inicial (opcional)',
                  hintText: '0,00',
                ),
              ),
            if (isCreditCard)
              TextField(
                controller: _limitController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Limite do cartão (opcional)',
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
