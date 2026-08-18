import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/attachment.dart';
import 'attachment_providers.dart';

final attachmentFutureProvider = FutureProvider.family<Attachment?, String>((ref, id) async {
  final repository = ref.watch(attachmentRepositoryProvider);
  final result = await repository.getAttachmentById(id);
  return result.fold(
    (attachment) => attachment,
    (failure) => throw Exception(failure.message),
  );
});
