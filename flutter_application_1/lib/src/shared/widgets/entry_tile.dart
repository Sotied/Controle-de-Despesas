import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/database/database_enums.dart';
import 'package:flutter_application_1/src/repositories/financial_entries_repository.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';

class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.item, this.onTap});

  final EntryWithRefs item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final entry = item.entry;

    final (icon, color, amountPrefix) = switch (entry.type) {
      EntryType.expense => (
        Icons.arrow_downward,
        Theme.of(context).colorScheme.error,
        '-',
      ),
      EntryType.income => (
        Icons.arrow_upward,
        Theme.of(context).colorScheme.secondary,
        '+',
      ),
      EntryType.transfer => (
        Icons.swap_horiz,
        Theme.of(context).colorScheme.primary,
        '',
      ),
    };

    final subtitleParts = <String>[formatDate(entry.occurredAt)];
    if (item.category != null) {
      subtitleParts.add(item.category!.name);
    }
    if (entry.type == EntryType.transfer) {
      subtitleParts.add(
        '${item.sourceAccount.name} → ${item.destinationAccount?.name ?? '—'}',
      );
    } else {
      subtitleParts.add(item.sourceAccount.name);
    }

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(
          entry.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitleParts.join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          '$amountPrefix${formatMoneyCents(entry.amountCents)}',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: color),
        ),
      ),
    );
  }
}
