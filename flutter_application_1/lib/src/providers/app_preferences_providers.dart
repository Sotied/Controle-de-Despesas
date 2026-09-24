import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/src/database/app_database.dart';
import 'package:flutter_application_1/src/providers/repositories_providers.dart';

final appPreferencesProvider = StreamProvider<AppPreference>((ref) {
  return ref.watch(appPreferencesRepositoryProvider).watch();
});
