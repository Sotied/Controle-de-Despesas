import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final randomJokeProvider = Provider((ref) {
  // Using the fetchRandomJoke function to get a random joke
  return "ewqeq";
});

class CustomExpansion extends StatelessWidget {
  const CustomExpansion({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpansionTile(
          title: Consumer(
            builder: (context, ref, child) {
              final randomJoke = ref.watch(randomJokeProvider);
              return Text(
                // "Novembro/2025",
                randomJoke,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              );
            },
          ),

          backgroundColor: Theme.of(context).colorScheme.surface,
          dense: true,
          collapsedBackgroundColor: Theme.of(context).colorScheme.surface,
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
