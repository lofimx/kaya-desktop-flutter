// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anga_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$angaRepositoryHash() => r'ebfe8d6e89b7a67e77cfcdc59cfe299e4faf10c3';

/// Notifier for managing the list of angas in memory.
///
/// Copied from [AngaRepository].
@ProviderFor(AngaRepository)
final angaRepositoryProvider =
    AsyncNotifierProvider<AngaRepository, List<Anga>>.internal(
      AngaRepository.new,
      name: r'angaRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$angaRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AngaRepository = AsyncNotifier<List<Anga>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
