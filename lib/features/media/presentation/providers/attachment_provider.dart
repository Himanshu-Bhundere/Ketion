import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/attachment.dart';
import '../../data/repositories/attachment_repository_impl.dart';

final attachmentProvider =
    FutureProvider.family<Attachment?, String>((ref, id) async {
  final repository = ref.watch(attachmentRepositoryProvider);
  return repository.getAttachment(id);
});

final attachmentPathProvider =
    FutureProvider.family<String?, Attachment>((ref, attachment) async {
  final repository = ref.watch(attachmentRepositoryProvider);
  return repository.resolveAttachmentPath(attachment);
});

/// Tracks real-time upload progress (0.0 to 1.0) for active attachments.
final attachmentUploadProgressProvider =
    StateProvider.family<double?, String>((ref, id) => null);
