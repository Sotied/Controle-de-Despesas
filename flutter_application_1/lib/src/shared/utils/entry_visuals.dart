import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';

String entryTypeLabel(EntryType type) => switch (type) {
  EntryType.expense => 'Despesa',
  EntryType.income => 'Receita',
  EntryType.transfer => 'Transferência',
};

IconData entryTypeIcon(EntryType type) => switch (type) {
  EntryType.expense => Icons.arrow_downward,
  EntryType.income => Icons.arrow_upward,
  EntryType.transfer => Icons.swap_horiz,
};

String entryStatusLabel(EntryStatus status) => switch (status) {
  EntryStatus.pending => 'Pendente',
  EntryStatus.completed => 'Concluído',
  EntryStatus.cancelled => 'Cancelado',
};
