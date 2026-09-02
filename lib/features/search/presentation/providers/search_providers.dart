import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/models/search_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/usecases/search_notes_usecase.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SearchRepositoryImpl(db);
});

final searchNotesUseCaseProvider = Provider<SearchNotesUseCase>((ref) {
  final repo = ref.watch(searchRepositoryProvider);
  return SearchNotesUseCase(repo);
});

class SearchNotifier extends StateNotifier<AsyncValue<List<SearchResult>>> {
  final SearchNotesUseCase _searchNotes;
  Timer? _debounceTimer;

  SearchNotifier(this._searchNotes) : super(const AsyncValue.data([]));

  void search(String query, {String? typeFilter}) {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    _debounceTimer?.cancel();
    state = const AsyncValue.loading();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final result = await _searchNotes(query, typeFilter: typeFilter);
      result.fold(
        (results) {
          if (mounted) {
            state = AsyncValue.data(results);
          }
        },
        (failure) {
          if (mounted) {
            state = AsyncValue.error(failure.message, StackTrace.current);
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, AsyncValue<List<SearchResult>>>(
        (ref) {
  final useCase = ref.watch(searchNotesUseCaseProvider);
  return SearchNotifier(useCase);
});
