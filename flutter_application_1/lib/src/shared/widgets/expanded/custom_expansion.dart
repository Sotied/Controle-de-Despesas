import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/shared/theme/custom_theme.dart';

class CustomExpansion extends StatelessWidget {
  const CustomExpansion({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpansionTile(
          title: Text(
            "Novembro/2025",
            style: CustomTypography.subtitle.copyWith(
              color: CustomColors.blackLighten1,
            ),
          ),
          backgroundColor: CustomColors.whiteDarken1,
          dense: true,
          collapsedBackgroundColor: CustomColors.whiteDarken1,
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(16),
          ),
          children: [Card(child: SizedBox(height: 150, width: 330))],
        ),
      ],
    );
  }
}
