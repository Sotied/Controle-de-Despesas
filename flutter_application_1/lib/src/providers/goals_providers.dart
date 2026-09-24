import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';
import 'package:flutter_application_1/src/repositories/goals_repository.dart';

final goalsProvider = StreamProvider<List<GoalProgress>>((ref) {
  return ref.watch(goalsRepositoryProvider).watchAll();
});
