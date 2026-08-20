import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/logger.dart';
import '../../data/repositories/collection_repository_impl.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/usecases/create_collection_usecase.dart';
import '../../domain/usecases/delete_collection_usecase.dart';
import '../../domain/usecases/get_collection_usecase.dart';
import '../../domain/usecases/update_collection_usecase.dart';

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CollectionRepositoryImpl(db, appLogger);
});

final createCollectionUseCaseProvider = Provider<CreateCollectionUseCase>((ref) {
  final repository = ref.watch(collectionRepositoryProvider);
  return CreateCollectionUseCase(repository);
});

final getCollectionUseCaseProvider = Provider<GetCollectionUseCase>((ref) {
  final repository = ref.watch(collectionRepositoryProvider);
  return GetCollectionUseCase(repository);
});

final updateCollectionUseCaseProvider = Provider<UpdateCollectionUseCase>((ref) {
  final repository = ref.watch(collectionRepositoryProvider);
  return UpdateCollectionUseCase(repository);
});

final deleteCollectionUseCaseProvider = Provider<DeleteCollectionUseCase>((ref) {
  final repository = ref.watch(collectionRepositoryProvider);
  return DeleteCollectionUseCase(repository);
});
