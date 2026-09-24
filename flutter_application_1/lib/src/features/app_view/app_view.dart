import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/features/accounts/accounts_page.dart';
import 'package:flutter_application_1/src/features/entries/entries_page.dart';
import 'package:flutter_application_1/src/features/home_page/home_page.dart';
import 'package:flutter_application_1/src/features/planning/planning_page.dart';
import 'package:flutter_application_1/src/features/reports/reports_page.dart';
import 'package:flutter_application_1/src/features/settings_page/settings_page.dart';
import 'package:flutter_application_1/src/shared/providers/navigation/navigation_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppView extends ConsumerWidget {
  const AppView({super.key});

  static const _pageTitles = [
    'Home',
    'Lançamentos',
    'Contas',
    'Planejamento',
    'Relatórios',
    'Configurações',
  ];

  static const _destinations = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
    (
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Lançamentos',
    ),
    (
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      label: 'Contas',
    ),
    (
      icon: Icons.savings_outlined,
      selectedIcon: Icons.savings,
      label: 'Planejamento',
    ),
    (
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      label: 'Relatórios',
    ),
    (
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Configurações',
    ),
  ];

  static const _pages = [
    HomePage(),
    EntriesPage(),
    AccountsPage(),
    PlanningPage(),
    ReportsPage(),
    SettingsPage(),
  ];

  static const _pagesWithOwnAppBar = {1, 2};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPage = ref.watch(navigationProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    void selectDestination(int index) {
      ref.read(navigationProvider.notifier).pageChanged(index);
    }

    return Scaffold(
      appBar: _pagesWithOwnAppBar.contains(selectedPage)
          ? null
          : AppBar(
              title: Text(
                _pageTitles[selectedPage],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (isWide) ...[
              NavigationRail(
                selectedIndex: selectedPage,
                onDestinationSelected: selectDestination,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final destination in _destinations)
                    NavigationRailDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: Text(destination.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
            ],
            Expanded(
              child: IndexedStack(index: selectedPage, children: _pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              onDestinationSelected: selectDestination,
              selectedIndex: selectedPage,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              destinations: [
                for (final destination in _destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                    tooltip: destination.label,
                  ),
              ],
            ),
    );
  }
}
