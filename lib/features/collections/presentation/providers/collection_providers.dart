import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart' hide Collection;
import '../../../../core/utils/logger.dart';
import '../../../sync/presentation/providers/sync_providers.dart';
import '../../data/repositories/collection_repository_impl.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/entities/collection.dart';
import '../../domain/usecases/create_collection_usecase.dart';
import '../../domain/usecases/delete_collection_usecase.dart';
import '../../domain/usecases/get_collection_usecase.dart';
import '../../domain/usecases/update_collection_usecase.dart';
import '../../domain/usecases/get_page_collections_usecase.dart';
import '../../domain/usecases/assign_collection_to_page_usecase.dart';
import '../../domain/usecases/remove_collection_from_page_usecase.dart';
import '../../domain/usecases/set_page_collections_usecase.dart';

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncQueue = ref.watch(syncQueueRepositoryProvider);
  return CollectionRepositoryImpl(db, syncQueue, appLogger);
});

final createCollectionUseCaseProvider =
    Provider<CreateCollectionUseCase>((ref) {
  final repository = ref.watch(collectionRepositoryProvider);
  return CreateCollectionUseCase(repository);
});

final getCollectionUseCaseProvider = Provider<GetCollectionUseCase>((ref) {
  final repository = ref.watch(collectionRepositoryProvider);
  return GetCollectionUseCase(repository);
});

final updateCollectionUseCaseProvider =
    Provider<UpdateCollectionUseCase>((ref) {
  final repository = ref.watch(collectionRepositoryProvider);
  return UpdateCollectionUseCase(repository);
});

final deleteCollectionUseCaseProvider =
    Provider<DeleteCollectionUseCase>((ref) {
  final repository = ref.watch(collectionRepositoryProvider);
  return DeleteCollectionUseCase(repository);
});

final getPageCollectionsUseCaseProvider =
    Provider<GetPageCollectionsUseCase>((ref) {
  final repository = ref.watch(collectionRepositoryProvider);
  return GetPageCollectionsUseCase(repository);
});

final assignCollectionToPageUseCaseProvider =
    Provider<AssignCollectionToPageUseCase>((ref) {
  final repository = ref.watch(collectionRepositoryProvider);
  return AssignCollectionToPageUseCase(repository);
});

final removeCollectionFromPageUseCaseProvider =
    Provider<RemoveCollectionFromPageUseCase>((ref) {
  final repository = ref.watch(collectionRepositoryProvider);
  return RemoveCollectionFromPageUseCase(repository);
});

final setPageCollectionsUseCaseProvider =
    Provider<SetPageCollectionsUseCase>((ref) {
  final repository = ref.watch(collectionRepositoryProvider);
  return SetPageCollectionsUseCase(repository);
});

final collectionsFutureProvider = FutureProvider<List<Collection>>((ref) async {
  final repository = ref.watch(collectionRepositoryProvider);
  final result = await repository.getAllCollections();
  return result.fold<List<Collection>>(
    (collections) => collections,
    (failure) => throw Exception(failure.message),
  );
});

final pageCollectionsFutureProvider =
    FutureProvider.family<List<Collection>, String>((ref, pageId) async {
  final getPageCollections = ref.watch(getPageCollectionsUseCaseProvider);
  final result = await getPageCollections(pageId);
  return result.fold<List<Collection>>(
    (collections) => collections,
    (failure) => throw Exception(failure.message),
  );
});
