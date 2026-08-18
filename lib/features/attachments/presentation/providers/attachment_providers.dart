import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../data/repositories/attachment_repository_impl.dart';
import '../../domain/repositories/attachment_repository.dart';
import '../../domain/usecases/save_attachment_usecase.dart';

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return AttachmentRepositoryImpl(database);
});

final saveAttachmentUseCaseProvider = Provider<SaveAttachmentUseCase>((ref) {
  final repository = ref.watch(attachmentRepositoryProvider);
  return SaveAttachmentUseCase(repository);
});
