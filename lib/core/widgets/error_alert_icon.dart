import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaya_desktop/features/errors/screens/errors_list_screen.dart';
import 'package:kaya_desktop/features/errors/services/error_service.dart';

/// Shows an error badge in the app bar when there are active errors.
class ErrorAlertIcon extends ConsumerWidget {
  const ErrorAlertIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasErrors = ref.watch(hasErrorsProvider);
    final count = ref.watch(errorCountProvider);

    if (!hasErrors) return const SizedBox.shrink();

    return IconButton(
      onPressed: () => context.push(ErrorsListScreen.routePath),
      icon: Badge(
        label: Text('$count'),
        child: Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          semanticLabel: '$count errors',
        ),
      ),
    );
  }
}
