import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaya_desktop/features/errors/models/app_error.dart';
import 'package:kaya_desktop/features/errors/services/error_service.dart';

/// Screen listing all active errors and warnings.
class ErrorsListScreen extends ConsumerWidget {
  const ErrorsListScreen({super.key});

  static const routePath = '/errors';
  static const routeName = 'errors';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errors = ref.watch(errorServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Errors'),
        actions: [
          if (errors.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(errorServiceProvider.notifier).clearAll();
              },
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: errors.isEmpty
          ? const Center(child: Text('No errors'))
          : ListView.builder(
              itemCount: errors.length,
              itemBuilder: (context, index) {
                final error = errors[index];
                return _ErrorTile(error: error);
              },
            ),
    );
  }
}

class _ErrorTile extends ConsumerWidget {
  final AppError error;

  const _ErrorTile({required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(error.id),
      onDismissed: (_) {
        ref.read(errorServiceProvider.notifier).removeError(error.id);
      },
      child: ListTile(
        leading: Icon(
          error.severity == ErrorSeverity.error
              ? Icons.error_outline
              : Icons.warning_amber_outlined,
          color: error.severity == ErrorSeverity.error
              ? Theme.of(context).colorScheme.error
              : Colors.orange,
        ),
        title: Text(error.message),
        subtitle: error.details != null ? Text(error.details!) : null,
        trailing: Text(
          '${error.timestamp.hour}:${error.timestamp.minute.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: error.details != null
            ? () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error Details'),
                    content: SelectableText(error.details!),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              }
            : null,
      ),
    );
  }
}
