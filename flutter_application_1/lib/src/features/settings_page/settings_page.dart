import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/features/categories/categories_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Gerenciamento',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Categorias'),
                subtitle: const Text('Organize despesas e receitas'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CategoriesPage(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
