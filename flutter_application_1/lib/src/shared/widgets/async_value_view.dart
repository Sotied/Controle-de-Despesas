import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncValueView<T> extends ConsumerWidget {
  const AsyncValueView({
    super.key,
    required this.asyncValue,
    required this.dataBuilder,
    this.loadingMessage = 'Carregando…',
    this.errorMessage = 'Não foi possível carregar os dados.',
    this.emptyMessage,
    this.onRetry,
  });

  final AsyncValue<T> asyncValue;
  final Widget Function(BuildContext context, T data) dataBuilder;
  final String loadingMessage;
  final String errorMessage;
  final String? emptyMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncValue.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      data: (data) {
        if (emptyMessage != null && data is List && data.isEmpty) {
          return Center(
            child: Text(
              emptyMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return dataBuilder(context, data);
      },
      loading: () => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            const CircularProgressIndicator(),
            Text(
              loadingMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (onRetry != null)
                FilledButton.tonal(
                  onPressed: onRetry,
                  child: const Text('Tentar novamente'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
