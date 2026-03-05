import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaya_desktop/core/widgets/cloud_status_icon.dart';
import 'package:kaya_desktop/core/widgets/error_alert_icon.dart';
import 'package:kaya_desktop/features/account/screens/account_screen.dart';
import 'package:kaya_desktop/features/anga/services/anga_repository.dart';
import 'package:kaya_desktop/features/anga/services/file_storage_service.dart';
import 'package:kaya_desktop/features/everything/screens/everything_screen.dart';
import 'package:kaya_desktop/features/meta/models/anga_meta.dart';
import 'package:kaya_desktop/features/sync/services/sync_service.dart';

/// Main screen for saving bookmarks, notes, and files.
class SaveScreen extends ConsumerWidget {
  const SaveScreen({super.key});

  static const routePath = '/';
  static const routeName = 'save';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Button'),
        actions: [
          IconButton(
            onPressed: () => context.push(EverythingScreen.routePath),
            icon: const Icon(Icons.list),
            tooltip: 'Browse all',
          ),
          const ErrorAlertIcon(),
          const CloudStatusIcon(),
          IconButton(
            onPressed: () => context.push(AccountScreen.routePath),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: const _SaveScreenBody(),
    );
  }
}

class _SaveScreenBody extends ConsumerWidget {
  const _SaveScreenBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: _SaveForm(),
        ),
      ),
    );
  }
}

class _SaveForm extends ConsumerWidget {
  const _SaveForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final angaController = TextEditingController();
    final noteController = TextEditingController();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: angaController,
          decoration: const InputDecoration(
            labelText: 'Bookmark URL or note text',
            hintText: 'https://example.com or a short note...',
          ),
          autofocus: true,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            hintText: 'Tags, context, reminders...',
          ),
          maxLines: 3,
          minLines: 2,
        ),
        const SizedBox(height: 16),
        _SaveButton(
          angaController: angaController,
          noteController: noteController,
        ),
        const SizedBox(height: 24),
        _DropZone(),
      ],
    );
  }
}

class _SaveButton extends ConsumerWidget {
  final TextEditingController angaController;
  final TextEditingController noteController;

  const _SaveButton({
    required this.angaController,
    required this.noteController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => _save(context, ref),
      child: const Text('Save'),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final text = angaController.text.trim();
    if (text.isEmpty) return;

    try {
      final storage = await ref.read(fileStorageServiceProvider.future);

      final isUrl = text.startsWith('http://') || text.startsWith('https://');
      final anga =
          isUrl ? await storage.saveBookmark(text) : await storage.saveNote(text);

      // Save metadata if note is provided
      final note = noteController.text.trim();
      if (note.isNotEmpty) {
        await storage.saveMeta(anga.filename, tags: [], note: note);
      }

      // Refresh the anga list
      ref.read(angaRepositoryProvider.notifier).refresh();

      // Trigger immediate sync
      ref.read(syncControllerProvider.notifier).forceSync();

      angaController.clear();
      noteController.clear();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUrl ? 'Bookmark saved' : 'Note saved',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _DropZone extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropTarget(
      onDragDone: (details) => _handleDrop(context, ref, details),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.file_upload_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 8),
              Text(
                'Drop files here',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDrop(
    BuildContext context,
    WidgetRef ref,
    DropDoneDetails details,
  ) async {
    final storage = await ref.read(fileStorageServiceProvider.future);

    for (final file in details.files) {
      try {
        final name = file.name;
        final path = file.path;
        await storage.saveFile(path, name);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving ${file.name}: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }

    ref.read(angaRepositoryProvider.notifier).refresh();
    ref.read(syncControllerProvider.notifier).forceSync();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${details.files.length} file(s) saved'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
