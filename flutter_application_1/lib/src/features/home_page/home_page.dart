import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/shared/widgets/expanded/custom_expansion.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [CustomExpansion()],
    );
  }
}
