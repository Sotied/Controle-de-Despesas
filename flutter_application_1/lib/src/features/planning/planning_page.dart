import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/features/planning/budgets_page.dart';
import 'package:flutter_application_1/src/features/planning/goals_page.dart';
import 'package:flutter_application_1/src/features/planning/recurring_entries_page.dart';

class PlanningPage extends StatelessWidget {
  const PlanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.query_stats_outlined),
                title: const Text('Orçamento mensal'),
                subtitle: const Text('Previsto x realizado por categoria'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BudgetsPage(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.autorenew),
                title: const Text('Contas recorrentes'),
                subtitle: const Text('Gerencie vencimentos mensais'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RecurringEntriesPage(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Metas financeiras'),
                subtitle: const Text('Defina objetivos e acompanhe'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const GoalsPage(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
