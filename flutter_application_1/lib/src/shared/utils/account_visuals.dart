import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';

String accountTypeLabel(AccountType type) => switch (type) {
  AccountType.cash => 'Carteira',
  AccountType.bank => 'Banco',
  AccountType.creditCard => 'Cartão',
  AccountType.savings => 'Poupança',
};

IconData accountTypeIcon(AccountType type) => switch (type) {
  AccountType.cash => Icons.account_balance_wallet,
  AccountType.bank => Icons.account_balance,
  AccountType.creditCard => Icons.credit_card,
  AccountType.savings => Icons.savings,
};
