import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaya_desktop/core/widgets/cloud_status_icon.dart';
import 'package:kaya_desktop/core/widgets/error_alert_icon.dart';
import 'package:kaya_desktop/features/anga/models/anga.dart';
import 'package:kaya_desktop/features/anga/models/anga_type.dart';
import 'package:kaya_desktop/features/anga/services/anga_repository.dart';
import 'package:kaya_desktop/features/everything/screens/preview_screen.dart';
import 'package:kaya_desktop/features/search/services/search_service.dart';

/// Screen showing all saved angas in a grid.
class EverythingScreen extends ConsumerWidget {
  const EverythingScreen({super.key});

  static const routePath = '/everything';
  static const routeName = 'everything';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Everything'),
        actions: const [
          ErrorAlertIcon(),
          CloudStatusIcon(),
        ],
      ),
      body: const _EverythingBody(),
    );
  }
}

class _EverythingBody extends ConsumerWidget {
  const _EverythingBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = TextEditingController();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search...',
            ),
            onChanged: (query) {
              // Trigger rebuild via provider
              ref.read(_searchQueryProvider.notifier).state = query;
            },
          ),
        ),
        Expanded(child: _AngaGrid()),
      ],
    );
  }
}

final _searchQueryProvider = StateProvider<String>((ref) => '');

class _AngaGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(_searchQueryProvider);
    final angasAsync = query.isEmpty
        ? ref.watch(angaRepositoryProvider)
        : ref.watch(filteredAngasProvider(query));

    return angasAsync.when(
      data: (angas) {
        if (angas.isEmpty) {
          return const Center(
            child: Text('No items yet. Save something!'),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 800
                ? 4
                : constraints.maxWidth > 500
                    ? 3
                    : 2;

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: angas.length,
              itemBuilder: (context, index) => _AngaTile(anga: angas[index]),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _AngaTile extends ConsumerWidget {
  final Anga anga;

  const _AngaTile({required this.anga});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        onTap: () {
          context.push(
            PreviewScreen.routePath.replaceFirst(
              ':filename',
              Uri.encodeComponent(anga.filename),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _iconForType(anga.type),
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const Spacer(),
              Text(
                anga.displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(anga.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(AngaType type) {
    switch (type) {
      case AngaType.bookmark:
        return Icons.bookmark_outline;
      case AngaType.note:
        return Icons.note_outlined;
      case AngaType.file:
        if (anga.isImage) return Icons.image_outlined;
        if (anga.isPdf) return Icons.picture_as_pdf_outlined;
        if (anga.isVideo) return Icons.video_file_outlined;
        return Icons.insert_drive_file_outlined;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
