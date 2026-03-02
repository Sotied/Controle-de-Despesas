part of 'navigation_notifier.dart';

class NavigationState extends Equatable {
  final int page;

  const NavigationState({this.page = 0});

  @override
  List<Object> get props => [page];
}
