import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaya_desktop/features/anga/models/anga.dart';
import 'package:kaya_desktop/features/anga/services/anga_repository.dart';
import 'package:kaya_desktop/features/anga/services/file_storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_service.g.dart';

/// Search result with score.
class SearchResult {
  final Anga anga;
  final double score;

  SearchResult(this.anga, this.score);
}

/// Provider for searching angas.
@riverpod
Future<List<SearchResult>> searchResults(Ref ref, String query) async {
  if (query.trim().isEmpty) return [];

  final angasAsync = ref.watch(angaRepositoryProvider);
  final angas = angasAsync.valueOrNull ?? [];

  if (angas.isEmpty) return [];

  final storage = await ref.read(fileStorageServiceProvider.future);
  final results = <SearchResult>[];

  for (final anga in angas) {
    final score = await _scoreAnga(anga, query, storage);
    if (score > 0) {
      results.add(SearchResult(anga, score));
    }
  }

  results.sort((a, b) => b.score.compareTo(a.score));
  return results;
}

/// Scores an anga against a query using substring matching.
Future<double> _scoreAnga(
  Anga anga,
  String query,
  FileStorageService storage,
) async {
  double bestScore = 0;
  final lowerQuery = query.toLowerCase();

  // Check filename / display title
  final title = anga.displayTitle.toLowerCase();
  if (title.contains(lowerQuery)) {
    bestScore = 1.0;
  }

  // Check URL for bookmarks
  if (anga.url != null) {
    final url = anga.url!.toLowerCase();
    if (url.contains(lowerQuery)) {
      bestScore = 1.0;
    }
  }

  // Check content
  if (anga.content != null) {
    final content = anga.content!.toLowerCase();
    if (content.contains(lowerQuery)) {
      final contentScore = 0.9;
      if (contentScore > bestScore) bestScore = contentScore;
    }
  }

  // Check words (search index)
  final wordsText = await storage.getWordsText(anga.filename);
  if (wordsText != null) {
    final words = wordsText.toLowerCase();
    if (words.contains(lowerQuery)) {
      final wordsScore = 0.8;
      if (wordsScore > bestScore) bestScore = wordsScore;
    }
  }

  // Check metadata tags and notes
  final allMeta = await storage.loadAllMetaForAnga(anga.filename);
  for (final meta in allMeta) {
    for (final tag in meta.tags) {
      if (tag.toLowerCase().contains(lowerQuery)) {
        final tagScore = 0.95;
        if (tagScore > bestScore) bestScore = tagScore;
      }
    }
    if (meta.note != null && meta.note!.toLowerCase().contains(lowerQuery)) {
      final noteScore = 0.85;
      if (noteScore > bestScore) bestScore = noteScore;
    }
  }

  return bestScore;
}

/// Convenience provider that returns filtered angas for a query.
@riverpod
Future<List<Anga>> filteredAngas(Ref ref, String query) async {
  if (query.trim().isEmpty) {
    final angasAsync = ref.watch(angaRepositoryProvider);
    return angasAsync.valueOrNull ?? [];
  }

  final results = await ref.watch(searchResultsProvider(query).future);
  return results.map((r) => r.anga).toList();
}
