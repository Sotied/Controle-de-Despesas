import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_application_1/src/features/app_view/app_view.dart';
import 'package:flutter_application_1/src/shared/theme/custom_theme.dart';

class ExpenseControlApp extends StatelessWidget {
  const ExpenseControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Despesas',
      theme: customTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      locale: const Locale('pt', 'BR'),
      debugShowCheckedModeBanner: false,
      home: const AppView(),
    );
  }
}
