import 'package:kaya_desktop/features/anga/models/anga.dart';
import 'package:kaya_desktop/features/anga/services/file_storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'anga_repository.g.dart';

/// Notifier for managing the list of angas in memory.
@Riverpod(keepAlive: true)
class AngaRepository extends _$AngaRepository {
  @override
  Future<List<Anga>> build() async {
    final storage = await ref.watch(fileStorageServiceProvider.future);
    return await storage.loadAllAngas();
  }

  /// Refreshes the anga list from disk.
  Future<void> refresh() async {
    final storage = await ref.read(fileStorageServiceProvider.future);
    state = AsyncValue.data(await storage.loadAllAngas());
  }
}
