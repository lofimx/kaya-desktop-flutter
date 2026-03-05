import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaya_desktop/features/anga/models/anga.dart';
import 'package:kaya_desktop/features/anga/models/anga_type.dart';
import 'package:kaya_desktop/features/anga/services/file_storage_service.dart';
import 'package:kaya_desktop/features/meta/models/anga_meta.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen for viewing a single anga's content and metadata.
class PreviewScreen extends ConsumerWidget {
  final String filename;

  const PreviewScreen({super.key, required this.filename});

  static const routePath = '/preview/:filename';
  static const routeName = 'preview';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageAsync = ref.watch(fileStorageServiceProvider);

    return storageAsync.when(
      data: (storage) => _PreviewContent(
        filename: Uri.decodeComponent(filename),
        storage: storage,
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Preview')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _PreviewContent extends ConsumerWidget {
  final String filename;
  final FileStorageService storage;

  const _PreviewContent({
    required this.filename,
    required this.storage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Anga?>(
      future: storage.loadAnga(filename),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final anga = snapshot.data;
        if (anga == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(child: Text('File not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(anga.displayTitle),
            actions: [
              if (anga.type == AngaType.bookmark && anga.url != null)
                IconButton(
                  onPressed: () => _openUrl(anga.url!),
                  icon: const Icon(Icons.open_in_browser),
                  tooltip: 'Open in browser',
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ContentView(anga: anga),
                const SizedBox(height: 24),
                _MetadataView(filename: filename, storage: storage),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ContentView extends ConsumerWidget {
  final Anga anga;

  const _ContentView({required this.anga});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (anga.type) {
      case AngaType.bookmark:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (anga.url != null)
              SelectableText(
                anga.url!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            if (anga.content != null) ...[
              const SizedBox(height: 16),
              SelectableText(anga.content!),
            ],
          ],
        );
      case AngaType.note:
        return SelectableText(
          anga.content ?? '',
          style: Theme.of(context).textTheme.bodyLarge,
        );
      case AngaType.file:
        if (anga.isImage) {
          return Image.file(
            File(anga.path),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
          );
        }
        return Column(
          children: [
            const Icon(Icons.insert_drive_file, size: 64),
            const SizedBox(height: 8),
            Text(anga.displayTitle),
            if (anga.fileSize != null)
              Text(
                '${(anga.fileSize! / 1024).toStringAsFixed(1)} KB',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        );
    }
  }
}

class _MetadataView extends ConsumerWidget {
  final String filename;
  final FileStorageService storage;

  const _MetadataView({
    required this.filename,
    required this.storage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<AngaMeta?>(
      future: storage.loadMetaForAnga(filename),
      builder: (context, snapshot) {
        final meta = snapshot.data;
        if (meta == null) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            if (meta.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: meta.tags.map((tag) {
                  return Chip(label: Text(tag));
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
            if (meta.note != null && meta.note!.isNotEmpty)
              Text(
                meta.note!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
          ],
        );
      },
    );
  }
}
