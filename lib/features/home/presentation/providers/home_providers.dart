import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/features/pages/domain/entities/page.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';

final recentPagesProvider = FutureProvider<List<Page>>((ref) async {
  final repository = ref.watch(pageRepositoryProvider);
  final result = await repository.getRecentPages();
  return result.fold(
    (pages) => pages,
    (error) => [],
  );
});

final favoritePagesProvider = FutureProvider<List<Page>>((ref) async {
  final repository = ref.watch(pageRepositoryProvider);
  final result = await repository.getFavoritePages();
  return result.fold(
    (pages) => pages,
    (error) => [],
  );
});

final activePageIdProvider = StateProvider<String?>((ref) => null);
