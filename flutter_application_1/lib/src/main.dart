import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/features/app_view/app_view.dart';
import 'package:flutter_application_1/src/shared/theme/custom_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: customTheme(),
      debugShowCheckedModeBanner: false,
      home: const AppView(),
    );
  }
}
