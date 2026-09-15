import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/logger.dart';
import '../../data/repositories/block_repository_impl.dart';
import '../../domain/repositories/block_repository.dart';
import '../../domain/usecases/create_block_usecase.dart';
import '../../domain/usecases/delete_block_usecase.dart';
import '../../domain/usecases/get_block_usecase.dart';
import '../../domain/usecases/get_page_blocks_usecase.dart';
import '../../domain/usecases/update_block_usecase.dart';
import '../../../sync/presentation/providers/sync_providers.dart';

final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncQueue = ref.watch(syncQueueRepositoryProvider);
  return BlockRepositoryImpl(db, syncQueue, appLogger);
});

final createBlockUseCaseProvider = Provider<CreateBlockUseCase>((ref) {
  final repository = ref.watch(blockRepositoryProvider);
  return CreateBlockUseCase(repository);
});

final getBlockUseCaseProvider = Provider<GetBlockUseCase>((ref) {
  final repository = ref.watch(blockRepositoryProvider);
  return GetBlockUseCase(repository);
});

final getPageBlocksUseCaseProvider = Provider<GetPageBlocksUseCase>((ref) {
  final repository = ref.watch(blockRepositoryProvider);
  return GetPageBlocksUseCase(repository);
});

final updateBlockUseCaseProvider = Provider<UpdateBlockUseCase>((ref) {
  final repository = ref.watch(blockRepositoryProvider);
  return UpdateBlockUseCase(repository);
});

final deleteBlockUseCaseProvider = Provider<DeleteBlockUseCase>((ref) {
  final repository = ref.watch(blockRepositoryProvider);
  return DeleteBlockUseCase(repository);
});
