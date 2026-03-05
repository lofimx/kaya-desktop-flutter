import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaya_desktop/features/sync/services/sync_service.dart';

/// Shows sync connection status in the app bar.
class CloudStatusIcon extends ConsumerWidget {
  const CloudStatusIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(syncConnectionStatusProvider);
    final syncStatus = ref.watch(syncControllerProvider);

    switch (connectionStatus) {
      case SyncConnectionStatus.notConfigured:
        return const SizedBox.shrink();
      case SyncConnectionStatus.connected:
        if (syncStatus == SyncStatus.syncing) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return Icon(
          Icons.cloud_done_outlined,
          color: Theme.of(context).colorScheme.primary,
          semanticLabel: 'Connected to server',
        );
      case SyncConnectionStatus.disconnected:
        return Icon(
          Icons.cloud_off_outlined,
          color: Theme.of(context).colorScheme.outline,
          semanticLabel: 'Disconnected from server',
        );
    }
  }
}
