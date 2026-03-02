import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/features/home_page/home_page.dart';
import 'package:flutter_application_1/src/features/settings_page/settings_page.dart';
import 'package:flutter_application_1/src/shared/providers/navigation/navigation_notifier.dart';
import 'package:flutter_application_1/src/shared/theme/custom_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppView extends ConsumerStatefulWidget {
  const AppView({super.key});

  @override
  ConsumerState<AppView> createState() => _AppViewState();
}

class _AppViewState extends ConsumerState<AppView> {
  final _pageController = PageController();

  Future<void> _animateTo(int page) async {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        var state = ref.watch(navigationProvider);
        return Scaffold(
          backgroundColor: CustomColors.whiteBase,
          appBar: AppBar(
            title: Text(
              state.page == 0 ? "Home" : "Configurações",
              style: CustomTypography.body1.copyWith(
                color: CustomColors.blackLighten1,
              ),
            ),
          ),
          bottomNavigationBar: NavigationBar(
            backgroundColor: CustomColors.whiteBase,
            indicatorColor: CustomColors.primaryBase,
            shadowColor: CustomColors.blackBase,
            onDestinationSelected: (value) {
              ref.read(navigationProvider.notifier).pageChanged(value);
              _animateTo(value);
            },
            selectedIndex: state.page,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home),
                label: "Home",
              ),
              const NavigationDestination(
                icon: Icon(Icons.settings),
                label: "Configurações",
              ),
            ],
          ),
          body: SafeArea(
            child: PageView(
              onPageChanged: (value) {
                ref.read(navigationProvider.notifier).pageChanged(value);
              },
              controller: _pageController,
              children: [const HomePage(), const SettingsPage()],
            ),
          ),
        );
      },
    );
  }
}
