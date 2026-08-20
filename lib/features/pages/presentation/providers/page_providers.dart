import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/logger.dart';
import '../../data/repositories/page_repository_impl.dart';
import '../../domain/repositories/page_repository.dart';
import '../../domain/usecases/create_page_usecase.dart';
import '../../domain/usecases/delete_page_usecase.dart';
import '../../domain/usecases/get_page_usecase.dart';
import '../../domain/usecases/update_page_usecase.dart';

final pageRepositoryProvider = Provider<PageRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PageRepositoryImpl(db, appLogger);
});

final createPageUseCaseProvider = Provider<CreatePageUseCase>((ref) {
  final repository = ref.watch(pageRepositoryProvider);
  return CreatePageUseCase(repository);
});

final getPageUseCaseProvider = Provider<GetPageUseCase>((ref) {
  final repository = ref.watch(pageRepositoryProvider);
  return GetPageUseCase(repository);
});

final updatePageUseCaseProvider = Provider<UpdatePageUseCase>((ref) {
  final repository = ref.watch(pageRepositoryProvider);
  return UpdatePageUseCase(repository);
});

final deletePageUseCaseProvider = Provider<DeletePageUseCase>((ref) {
  final repository = ref.watch(pageRepositoryProvider);
  return DeletePageUseCase(repository);
});
