import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/result.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/routes.dart';
import '../../../blocks/domain/entities/block.dart' as entity_block;
import '../../../blocks/presentation/providers/block_providers.dart';
import '../../../editor/domain/models/block_data_models.dart';
import '../../../editor/presentation/providers/editor_state_provider.dart';
import '../../../media/presentation/providers/media_picker_provider.dart';
import '../../../pages/presentation/providers/page_providers.dart';
import '../../data/services/incoming_share_service.dart';
import '../../domain/models/incoming_share_item.dart';
import '../widgets/incoming_share_note_picker.dart';

final incomingShareServiceProvider = Provider<IncomingShareService>((ref) {
  final service = IncomingShareService();
  ref.onDispose(() => service.dispose());
  return service;
});

final activeEditorPageIdProvider = StateProvider<String?>((ref) => null);

final isDraggingFilesProvider = StateProvider<bool>((ref) => false);

final editorInsertItemCallbackProvider =
    StateProvider.family<Future<void> Function(IncomingShareItem)?, String>(
  (ref, pageId) => null,
);

final incomingShareCoordinatorProvider =
    Provider<IncomingShareCoordinator>((ref) {
  return IncomingShareCoordinator(ref);
});

class IncomingShareCoordinator {
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  IncomingShareCoordinator(this._ref);

  String? getActiveEditorPageId() {
    final activeFromProvider = _ref.read(activeEditorPageIdProvider);
    if (activeFromProvider != null && activeFromProvider.isNotEmpty) {
      return activeFromProvider;
    }
    try {
      final uri = appRouter.routeInformationProvider.value.uri;
      final segments = uri.pathSegments;
      final editorIndex = segments.indexOf('editor');
      if (editorIndex != -1 && segments.length > editorIndex + 1) {
        return segments[editorIndex + 1];
      }
    } catch (_) {}
    return null;
  }

  Future<void> handleIncomingItems(
    BuildContext context,
    List<IncomingShareItem> items,
  ) async {
    if (items.isEmpty) return;

    final navContext = rootNavigatorKey.currentContext ?? context;
    final activePageId = getActiveEditorPageId();

    // Context-sensitive check: If an active note editor is open, attach directly!
    if (activePageId != null) {
      final messenger = ScaffoldMessenger.maybeOf(navContext);
      try {
        await importItemsToPages(
          items: items,
          pageIds: [activePageId],
        );
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              'Attached ${items.length} item(s) to current note',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (e) {
        messenger?.showSnackBar(
          SnackBar(
            content: Text('Failed to attach items to current note: $e'),
          ),
        );
      }
      return;
    }

    // Otherwise route to the notes list and show the multi-note picker
    if (!navContext.mounted) return;

    // Route to the notes list page as required when no note is open
    appRouter.go(Routes.notes);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentNavContext = rootNavigatorKey.currentContext ?? navContext;
      if (!currentNavContext.mounted) return;

      await IncomingShareNotePicker.show(
        currentNavContext,
        items: items,
        onConfirm: (selectedPageIds) async {
          await importItemsToPages(
            items: items,
            pageIds: selectedPageIds,
          );
          if (currentNavContext.mounted) {
            ScaffoldMessenger.maybeOf(currentNavContext)?.showSnackBar(
              SnackBar(
                content: Text(
                  'Attached ${items.length} item(s) to ${selectedPageIds.length} note(s)',
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        onCreateNewNote: () async {
          final firstItem = items.first;
          final noteTitle = firstItem.name.isNotEmpty
              ? 'Shared: ${firstItem.name}'
              : 'Shared Note';

          final createPageUseCase = _ref.read(createPageUseCaseProvider);
          final result = await createPageUseCase(
            title: noteTitle,
            icon: '📥',
          );

          if (result is Success) {
            final newPage = (result as Success).value;
            _ref.invalidate(allPagesProvider);
            _ref.invalidate(recentPagesProvider);
            return newPage.id as String;
          }
          return null;
        },
      );
    });
  }

  Future<void> importItemsToPages({
    required List<IncomingShareItem> items,
    required List<String> pageIds,
  }) async {
    final activePageId = getActiveEditorPageId();
    for (final pageId in pageIds) {
      final insertCallback = activePageId == pageId
          ? _ref.read(editorInsertItemCallbackProvider(pageId))
          : null;
      if (insertCallback != null) {
        for (final item in items) {
          await insertCallback(item);
        }
        continue;
      }

      final mediaPicker = _ref.read(mediaPickerProvider);
      final blockRepository = _ref.read(blockRepositoryProvider);
      final existingBlocks =
          await _ref.read(pageBlocksProvider(pageId).future);
      double nextPosition = existingBlocks.isEmpty
          ? 1000.0
          : (existingBlocks.last.position + 1000.0);

      for (final item in items) {
        final now = DateTime.now().toUtc();
        final blockId = _uuid.v4();

        if (item.type == IncomingShareType.file) {
          if (item.localPath == null) continue;

          final platformFile = PlatformFile(
            name: item.name,
            path: item.localPath,
            size: item.size ?? 0,
          );

          final attachment = await mediaPicker.importExternalFile(
            pageId: pageId,
            blockId: blockId,
            file: platformFile,
            mimeType: item.mimeType,
          );

          if (attachment == null) {
            debugPrint('[IncomingShareCoordinator] Failed to save attachment for: ${item.name}');
            continue;
          }

          final mimeType = attachment.mimeType.toLowerCase();
          String blockType = 'file';
          BlockDataModel dataModel = BlockDataModel.file(
            attachmentId: attachment.id,
            caption: item.name,
          );

          if (mimeType.startsWith('image/')) {
            blockType = 'image';
            dataModel = BlockDataModel.image(
              attachmentId: attachment.id,
              caption: item.name,
            );
          } else if (mimeType.startsWith('video/')) {
            blockType = 'video';
            dataModel = BlockDataModel.video(
              attachmentId: attachment.id,
              caption: item.name,
            );
          } else if (mimeType.startsWith('audio/')) {
            blockType = 'audio';
            dataModel = BlockDataModel.audio(
              attachmentId: attachment.id,
              caption: item.name,
            );
          } else if (mimeType == 'application/pdf') {
            blockType = 'pdf';
            dataModel = BlockDataModel.pdf(
              attachmentId: attachment.id,
              caption: item.name,
            );
          }

          final block = entity_block.Block(
            id: blockId,
            pageId: pageId,
            type: blockType,
            position: nextPosition,
            data: jsonEncode(dataModel.toJson()),
            version: 1,
            deleted: false,
            createdAt: now,
            updatedAt: now,
          );

          await blockRepository.createBlock(block);
          nextPosition += 1000.0;
        } else if (item.type == IncomingShareType.link) {
          final url = item.url ?? item.name;
          final dataModel = BlockDataModel.webLink(url: url);
          final block = entity_block.Block(
            id: blockId,
            pageId: pageId,
            type: 'web_link',
            position: nextPosition,
            data: jsonEncode(dataModel.toJson()),
            version: 1,
            deleted: false,
            createdAt: now,
            updatedAt: now,
          );

          await blockRepository.createBlock(block);
          nextPosition += 1000.0;
        } else if (item.type == IncomingShareType.text) {
          final text = item.text ?? item.name;
          final dataModel = BlockDataModel.text(
            spans: [TextSpanData(text: text)],
          );
          final block = entity_block.Block(
            id: blockId,
            pageId: pageId,
            type: 'text',
            position: nextPosition,
            data: jsonEncode(dataModel.toJson()),
            version: 1,
            deleted: false,
            createdAt: now,
            updatedAt: now,
          );

          await blockRepository.createBlock(block);
          nextPosition += 1000.0;
        }
      }

      // Refresh providers for this page
      _ref.invalidate(pageBlocksProvider(pageId));
      _ref.invalidate(editorStateProvider(pageId));
      _ref.invalidate(pageProvider(pageId));
      _ref.invalidate(recentPagesProvider);
      _ref.invalidate(allPagesProvider);
    }
  }
}
