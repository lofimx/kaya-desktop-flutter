import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaya_desktop/features/account/services/account_repository.dart';
import 'package:kaya_desktop/features/sync/services/sync_service.dart';

/// Account settings screen for server sync configuration.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  static const routePath = '/account';
  static const routeName = 'account';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: const _AccountForm(),
          ),
        ),
      ),
    );
  }
}

class _AccountForm extends ConsumerWidget {
  const _AccountForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(accountSettingsNotifierProvider);

    return settingsAsync.when(
      data: (settings) => _AccountFormContent(settings: settings),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _AccountFormContent extends ConsumerWidget {
  final dynamic settings;

  const _AccountFormContent({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Server', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _ServerUrlField(initialValue: settings.serverUrl),
        const SizedBox(height: 24),
        Text('Account', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _EmailField(initialValue: settings.email ?? ''),
        const SizedBox(height: 12),
        _PasswordField(initialValue: settings.password ?? ''),
        const SizedBox(height: 24),
        Text('Sync', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _SyncStatusSection(),
        const SizedBox(height: 16),
        Row(
          children: [
            _TestConnectionButton(),
            const SizedBox(width: 12),
            _ForceSyncButton(),
          ],
        ),
      ],
    );
  }
}

class _ServerUrlField extends ConsumerWidget {
  final String initialValue;

  const _ServerUrlField({required this.initialValue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextFormField(
      initialValue: initialValue,
      decoration: const InputDecoration(
        labelText: 'Server URL',
        hintText: 'https://savebutton.com',
      ),
      onChanged: (value) {
        ref
            .read(accountSettingsNotifierProvider.notifier)
            .updateServerUrl(value.trim());
      },
    );
  }
}

class _EmailField extends ConsumerWidget {
  final String initialValue;

  const _EmailField({required this.initialValue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextFormField(
      initialValue: initialValue,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'your@email.com',
      ),
      keyboardType: TextInputType.emailAddress,
      onChanged: (value) {
        ref
            .read(accountSettingsNotifierProvider.notifier)
            .updateEmail(value.trim());
      },
    );
  }
}

class _PasswordField extends ConsumerWidget {
  final String initialValue;

  const _PasswordField({required this.initialValue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextFormField(
      initialValue: initialValue,
      decoration: const InputDecoration(
        labelText: 'Password',
      ),
      obscureText: true,
      onChanged: (value) {
        ref
            .read(accountSettingsNotifierProvider.notifier)
            .updatePassword(value);
      },
    );
  }
}

class _SyncStatusSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(syncConnectionStatusProvider);
    final syncStatus = ref.watch(syncControllerProvider);

    String statusText;
    Color statusColor;

    switch (connectionStatus) {
      case SyncConnectionStatus.notConfigured:
        statusText = 'Not configured';
        statusColor = Theme.of(context).colorScheme.outline;
      case SyncConnectionStatus.connected:
        statusText = syncStatus == SyncStatus.syncing
            ? 'Syncing...'
            : 'Connected';
        statusColor = Theme.of(context).colorScheme.primary;
      case SyncConnectionStatus.disconnected:
        statusText = 'Disconnected';
        statusColor = Theme.of(context).colorScheme.error;
    }

    return Row(
      children: [
        Icon(Icons.circle, size: 12, color: statusColor),
        const SizedBox(width: 8),
        Text(statusText),
      ],
    );
  }
}

class _TestConnectionButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton(
      onPressed: () async {
        final success =
            await ref.read(syncControllerProvider.notifier).testConnection();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success ? 'Connection successful' : 'Connection failed',
              ),
            ),
          );
        }
      },
      child: const Text('Test Connection'),
    );
  }
}

class _ForceSyncButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncControllerProvider);

    return ElevatedButton(
      onPressed: syncStatus == SyncStatus.syncing
          ? null
          : () async {
              final result =
                  await ref.read(syncControllerProvider.notifier).forceSync();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.hasChanges
                          ? 'Sync complete: ${result.angaDownloaded + result.metaDownloaded} downloaded, ${result.angaUploaded + result.metaUploaded} uploaded'
                          : result.hasErrors
                              ? 'Sync errors: ${result.errors.first}'
                              : 'Everything up to date',
                    ),
                  ),
                );
              }
            },
      child: Text(
        syncStatus == SyncStatus.syncing ? 'Syncing...' : 'Force Sync',
      ),
    );
  }
}
