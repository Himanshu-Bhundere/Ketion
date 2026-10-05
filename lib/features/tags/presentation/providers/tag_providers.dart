import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart' hide Tag;
import '../../../../core/utils/logger.dart';
import '../../../sync/presentation/providers/sync_providers.dart';
import '../../data/repositories/tag_repository_impl.dart';
import '../../domain/repositories/tag_repository.dart';
import '../../domain/entities/tag.dart';
import '../../domain/usecases/create_tag_usecase.dart';
import '../../domain/usecases/delete_tag_usecase.dart';
import '../../domain/usecases/get_tag_usecase.dart';
import '../../domain/usecases/update_tag_usecase.dart';
import '../../domain/usecases/get_page_tags_usecase.dart';
import '../../domain/usecases/assign_tag_to_page_usecase.dart';
import '../../domain/usecases/remove_tag_from_page_usecase.dart';
import '../../domain/usecases/set_page_tags_usecase.dart';

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncQueue = ref.watch(syncQueueRepositoryProvider);
  return TagRepositoryImpl(db, syncQueue, appLogger);
});

final createTagUseCaseProvider = Provider<CreateTagUseCase>((ref) {
  final repository = ref.watch(tagRepositoryProvider);
  return CreateTagUseCase(repository);
});

final getTagUseCaseProvider = Provider<GetTagUseCase>((ref) {
  final repository = ref.watch(tagRepositoryProvider);
  return GetTagUseCase(repository);
});

final updateTagUseCaseProvider = Provider<UpdateTagUseCase>((ref) {
  final repository = ref.watch(tagRepositoryProvider);
  return UpdateTagUseCase(repository);
});

final deleteTagUseCaseProvider = Provider<DeleteTagUseCase>((ref) {
  final repository = ref.watch(tagRepositoryProvider);
  return DeleteTagUseCase(repository);
});

final getPageTagsUseCaseProvider = Provider<GetPageTagsUseCase>((ref) {
  final repository = ref.watch(tagRepositoryProvider);
  return GetPageTagsUseCase(repository);
});

final assignTagToPageUseCaseProvider = Provider<AssignTagToPageUseCase>((ref) {
  final repository = ref.watch(tagRepositoryProvider);
  return AssignTagToPageUseCase(repository);
});

final removeTagFromPageUseCaseProvider =
    Provider<RemoveTagFromPageUseCase>((ref) {
  final repository = ref.watch(tagRepositoryProvider);
  return RemoveTagFromPageUseCase(repository);
});

final setPageTagsUseCaseProvider = Provider<SetPageTagsUseCase>((ref) {
  final repository = ref.watch(tagRepositoryProvider);
  return SetPageTagsUseCase(repository);
});

final tagsFutureProvider = FutureProvider<List<Tag>>((ref) async {
  final repository = ref.watch(tagRepositoryProvider);
  final result = await repository.getAllTags();
  return result.fold<List<Tag>>(
    (tags) => tags,
    (failure) => throw Exception(failure.message),
  );
});

final pageTagsFutureProvider =
    FutureProvider.family<List<Tag>, String>((ref, pageId) async {
  final getPageTags = ref.watch(getPageTagsUseCaseProvider);
  final result = await getPageTags(pageId);
  return result.fold<List<Tag>>(
    (tags) => tags,
    (failure) => throw Exception(failure.message),
  );
});
