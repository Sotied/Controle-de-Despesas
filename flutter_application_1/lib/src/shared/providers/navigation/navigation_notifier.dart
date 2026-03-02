import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/legacy.dart';

part 'navigation_state.dart';

class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(const NavigationState());

  void pageChanged(int page) => state = NavigationState(page: page);
}

final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>(
      (ref) => NavigationNotifier(),
    );
