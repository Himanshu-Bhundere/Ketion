import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/models/search_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/usecases/search_notes_usecase.dart';
import '../../../../core/utils/logger.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SearchRepositoryImpl(db, appLogger);
});

final searchNotesUseCaseProvider = Provider<SearchNotesUseCase>((ref) {
  final repo = ref.watch(searchRepositoryProvider);
  return SearchNotesUseCase(repo);
});

class SearchNotifier
    extends StateNotifier<AsyncValue<List<GroupedSearchResult>>> {
  final SearchNotesUseCase _searchNotes;
  Timer? _debounceTimer;
  int _currentRequestId = 0;

  SearchNotifier(this._searchNotes) : super(const AsyncValue.data([]));

  void search(
    String query, {
    String? typeFilter,
    String? tagFilter,
    String? collectionFilter,
  }) {
    final trimmedQuery = query.trim();
    final hasMetadataFilter = (tagFilter != null && tagFilter.isNotEmpty) ||
        (collectionFilter != null && collectionFilter.isNotEmpty) ||
        (typeFilter != null && typeFilter.isNotEmpty);

    if (trimmedQuery.isEmpty && !hasMetadataFilter) {
      _debounceTimer?.cancel();
      _currentRequestId++;
      state = const AsyncValue.data([]);
      return;
    }

    _debounceTimer?.cancel();
    state = const AsyncValue.loading();
    _currentRequestId++;
    final requestId = _currentRequestId;

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (requestId != _currentRequestId) return;

      final result = await _searchNotes(
        trimmedQuery,
        typeFilter: typeFilter,
        tagFilter: tagFilter,
        collectionFilter: collectionFilter,
      );

      if (requestId != _currentRequestId) return;

      result.fold(
        (results) {
          if (mounted && requestId == _currentRequestId) {
            state = AsyncValue.data(_groupResults(results));
          }
        },
        (failure) {
          if (mounted && requestId == _currentRequestId) {
            state = AsyncValue.error(failure.message, StackTrace.current);
          }
        },
      );
    });
  }

  List<GroupedSearchResult> _groupResults(List<SearchResult> results) {
    final Map<String, List<SearchResult>> groups = {};

    for (final result in results) {
      final groupId = (result.entityType == 'tag')
          ? result.entityId
          : (result.pageId ?? result.entityId);
      groups.putIfAbsent(groupId, () => []).add(result);
    }

    return groups.entries.map((entry) {
      final matches = entry.value;
      return GroupedSearchResult(
        groupId: entry.key,
        pageTitle: matches.first.pageTitle,
        strongestMatch: matches.first,
        matchCount: matches.length,
        allMatches: matches,
      );
    }).toList();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final searchNotifierProvider = StateNotifierProvider<SearchNotifier,
    AsyncValue<List<GroupedSearchResult>>>((ref) {
  final useCase = ref.watch(searchNotesUseCaseProvider);
  return SearchNotifier(useCase);
});
