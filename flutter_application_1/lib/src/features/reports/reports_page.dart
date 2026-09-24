import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/providers/accounts_providers.dart';
import 'package:flutter_application_1/src/providers/reports_providers.dart';
import 'package:flutter_application_1/src/repositories/accounts_repository.dart';
import 'package:flutter_application_1/src/repositories/reports_repository.dart';
import 'package:flutter_application_1/src/shared/theme/custom_theme.dart';
import 'package:flutter_application_1/src/shared/utils/money.dart';
import 'package:flutter_application_1/src/shared/widgets/async_value_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(reportFiltersProvider);
    final notifier = ref.read(reportFiltersProvider.notifier);
    final accounts =
        ref.watch(accountsWithBalanceProvider).value ??
        const <AccountWithBalance>[];

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Mês anterior',
                  onPressed: notifier.previousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '${monthName(filters.month.month)} ${filters.month.year}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Próximo mês',
                  onPressed: notifier.nextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: DropdownButtonFormField<int>(
              key: ValueKey('report-account-${filters.accountId}'),
              initialValue: filters.accountId,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'Conta',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                for (final item in accounts)
                  DropdownMenuItem(
                    value: item.account.id,
                    child: Text(item.account.name),
                  ),
              ],
              onChanged: (value) => notifier.setAccount(value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Por categoria'),
                  selected: filters.tabIndex == 0,
                  onSelected: (_) => notifier.setTab(0),
                ),
                ChoiceChip(
                  label: const Text('Evolução mensal'),
                  selected: filters.tabIndex == 1,
                  onSelected: (_) => notifier.setTab(1),
                ),
                ChoiceChip(
                  label: const Text('Receitas x despesas'),
                  selected: filters.tabIndex == 2,
                  onSelected: (_) => notifier.setTab(2),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: filters.tabIndex,
              children: const [
                _CategoryExpensesView(),
                _MonthlyEvolutionView(),
                _IncomeVsExpenseView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryExpensesView extends ConsumerWidget {
  const _CategoryExpensesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(categoryExpensesProvider);

    return AsyncValueView(
      asyncValue: expensesAsync,
      emptyMessage: 'Sem gastos no período.',
      dataBuilder: (context, reports) {
        final totalSpent = reports.fold<int>(0, (sum, r) => sum + r.totalCents);
        final maxTotal = reports
            .map((r) => r.totalCents)
            .fold<int>(1, (a, b) => a > b ? a : b);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            for (final report in reports)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            report.categoryName,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Text(
                          formatMoneyCents(report.totalCents),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: report.totalCents / maxTotal,
                        minHeight: 8,
                        color: Theme.of(context).colorScheme.error,
                        backgroundColor: CustomColors.outline.withAlpha(80),
                      ),
                    ),
                    Text(
                      '${(report.totalCents / totalSpent * 100).toStringAsFixed(0)}% do total',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MonthlyEvolutionView extends ConsumerWidget {
  const _MonthlyEvolutionView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(monthlyTotalsProvider);

    return AsyncValueView(
      asyncValue: totalsAsync,
      dataBuilder: (context, totals) {
        final maxTotal = totals
            .map((t) => t.incomeCents > t.expenseCents
                ? t.incomeCents
                : t.expenseCents)
            .fold<int>(1, (a, b) => a > b ? a : b);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    Text(
                      'Últimos 6 meses',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SizedBox(
                      height: 140,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final total in totals)
                            Expanded(
                              child: _MonthColumn(
                                total: total,
                                max: maxTotal,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      spacing: 16,
                      children: [
                        _LegendDot(
                          color: Theme.of(context).colorScheme.secondary,
                          label: 'Receitas',
                        ),
                        _LegendDot(
                          color: Theme.of(context).colorScheme.error,
                          label: 'Despesas',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MonthColumn extends StatelessWidget {
  const _MonthColumn({required this.total, required this.max});

  final MonthlyTotals total;
  final int max;

  @override
  Widget build(BuildContext context) {
    Widget bar(int value, Color color) {
      final height = value <= 0
          ? 2.0
          : (100.0 * value / max).clamp(4.0, 100.0);
      return Container(
        width: 12,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            bar(
              total.incomeCents,
              Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 4),
            bar(total.expenseCents, Theme.of(context).colorScheme.error),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          monthNames[total.month.month - 1].substring(0, 3),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _IncomeVsExpenseView extends ConsumerWidget {
  const _IncomeVsExpenseView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(periodTotalsProvider);

    return AsyncValueView(
      asyncValue: totalsAsync,
      dataBuilder: (context, totals) {
        final combined = totals.incomeCents + totals.expenseCents;
        final incomeShare = combined == 0 ? 0.5 : totals.incomeCents / combined;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    Text(
                      'Comparativo do mês',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _TotalItem(
                            label: 'Receitas',
                            value: formatMoneyCents(totals.incomeCents),
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        Expanded(
                          child: _TotalItem(
                            label: 'Despesas',
                            value: formatMoneyCents(totals.expenseCents),
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        Expanded(
                          child: _TotalItem(
                            label: 'Saldo',
                            value: formatMoneyCents(totals.balanceCents),
                            color: totals.balanceCents < 0
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 12,
                        child: combined == 0
                            ? Container(color: CustomColors.outline.withAlpha(80))
                            : Row(
                                children: [
                                  Flexible(
                                    flex: (incomeShare * 100)
                                        .round()
                                        .clamp(1, 99),
                                    child: Container(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                    ),
                                  ),
                                  Flexible(
                                    flex: 100 -
                                        (incomeShare * 100).round().clamp(1, 99),
                                    child: Container(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TotalItem extends StatelessWidget {
  const _TotalItem({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
