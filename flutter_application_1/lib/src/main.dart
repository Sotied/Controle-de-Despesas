import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/features/home_page/home_page.dart';
import 'package:flutter_application_1/src/shared/theme/custom_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: customTheme(),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.whiteBase,
      bottomNavigationBar: NavigationBar(
        backgroundColor: CustomColors.whiteBase,
        indicatorColor: CustomColors.primaryBase,
        shadowColor: CustomColors.blackBase,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home), label: "Home"),
          const NavigationDestination(
            icon: Icon(Icons.settings),
            label: "Configurações",
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16.0), child: HomePage()),
      ),
    );
  }
}
