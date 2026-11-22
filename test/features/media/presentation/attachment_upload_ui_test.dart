import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_image_component.dart';
import 'package:ketion/features/editor/presentation/widgets/players/ketion_video_player.dart';
import 'package:ketion/features/media/domain/entities/attachment.dart';
import 'package:ketion/features/media/domain/entities/attachment_upload_status.dart';
import 'package:ketion/features/media/domain/services/attachment_sync_service.dart';
import 'package:ketion/features/media/data/services/attachment_sync_service_impl.dart';
import 'package:ketion/features/media/presentation/providers/attachment_provider.dart';

class _FakeAttachmentSyncService implements AttachmentSyncService {
  Attachment? retriedAttachment;

  @override
  Future<void> uploadAttachment(Attachment attachment) async {
    retriedAttachment = attachment;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int textureId) async {}

  @override
  Future<int?> create(DataSource dataSource) async => 1;

  @override
  Future<void> setLooping(int textureId, bool looping) async {}

  @override
  Future<void> play(int textureId) async {}

  @override
  Future<void> pause(int textureId) async {}

  @override
  Future<void> setVolume(int textureId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {}

  @override
  Future<void> seekTo(int textureId, Duration position) async {}

  @override
  Future<Duration> getPosition(int textureId) async => Duration.zero;

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) => Stream.value(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 10),
          size: const Size(640, 480),
        ),
      );

  @override
  Widget buildView(int textureId) => const SizedBox();
}

void main() {
  group('Image and Video Upload Progress & Retry UI Tests', () {
    late _FakeAttachmentSyncService fakeSyncService;
    late io.Directory tempDir;
    late io.File testImageFile;
    late io.File testVideoFile;

    setUp(() async {
      VideoPlayerPlatform.instance = _FakeVideoPlayerPlatform();
      fakeSyncService = _FakeAttachmentSyncService();
      tempDir = await io.Directory.systemTemp.createTemp('upload_ui_test_');
      testImageFile = io.File('${tempDir.path}/test.png');
      await testImageFile.writeAsBytes(const [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ]);
      testVideoFile = io.File('${tempDir.path}/test.mp4');
      await testVideoFile.writeAsString('dummy video');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('Image displays live upload progress and cancel button', (tester) async {
      final testImageAttachment = Attachment(
        id: 'img-1',
        blockId: 'b-1',
        localPath: testImageFile.path,
        mimeType: 'image/png',
        checksumSha256: 'hash-1',
        fileSize: 2048,
        uploadStatus: AttachmentUploadStatus.uploading,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        deleted: false,
        isPinnedOffline: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attachmentProvider('img-1').overrideWith((ref) => Future.value(testImageAttachment)),
            attachmentPathProvider(testImageAttachment).overrideWith((ref) => Future.value(testImageFile.path)),
            attachmentUploadProgressProvider('img-1').overrideWith((ref) => 0.45),
            attachmentSyncServiceProvider.overrideWithValue(fakeSyncService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: KetionImageComponent(
                viewModel: KetionImageComponentViewModel(
                  nodeId: 'node-img',
                  imageUrl: 'img-1',
                  padding: EdgeInsets.zero,
                  createdAt: DateTime.now(),
                  selectionColor: Colors.transparent,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Uploading... 45%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byTooltip('Cancel upload'), findsOneWidget);
    });

    testWidgets('Image displays retry button on failed upload', (tester) async {
      final failedAttachment = Attachment(
        id: 'img-1',
        blockId: 'b-1',
        localPath: testImageFile.path,
        mimeType: 'image/png',
        checksumSha256: 'hash-1',
        fileSize: 2048,
        uploadStatus: AttachmentUploadStatus.failed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        deleted: false,
        isPinnedOffline: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attachmentProvider('img-1').overrideWith((ref) => Future.value(failedAttachment)),
            attachmentPathProvider(failedAttachment).overrideWith((ref) => Future.value(testImageFile.path)),
            attachmentUploadProgressProvider('img-1').overrideWith((ref) => null),
            attachmentSyncServiceProvider.overrideWithValue(fakeSyncService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: KetionImageComponent(
                viewModel: KetionImageComponentViewModel(
                  nodeId: 'node-img',
                  imageUrl: 'img-1',
                  padding: EdgeInsets.zero,
                  createdAt: DateTime.now(),
                  selectionColor: Colors.transparent,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Upload failed or cancelled'), findsOneWidget);
      final retryBtn = find.widgetWithText(TextButton, 'Retry');
      expect(retryBtn, findsOneWidget);

      await tester.tap(retryBtn);
      await tester.pump();

      expect(fakeSyncService.retriedAttachment?.id, 'img-1');
    });

    testWidgets('Video displays live upload progress and cancel button', (tester) async {
      final testVideoAttachment = Attachment(
        id: 'vid-1',
        blockId: 'b-2',
        localPath: testVideoFile.path,
        mimeType: 'video/mp4',
        checksumSha256: 'hash-2',
        fileSize: 4096,
        uploadStatus: AttachmentUploadStatus.uploading,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        deleted: false,
        isPinnedOffline: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attachmentProvider('vid-1').overrideWith((ref) => Future.value(testVideoAttachment)),
            attachmentPathProvider(testVideoAttachment).overrideWith((ref) => Future.value(testVideoFile.path)),
            attachmentUploadProgressProvider('vid-1').overrideWith((ref) => 0.72),
            attachmentSyncServiceProvider.overrideWithValue(fakeSyncService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: KetionVideoPlayerComponent(
                attachmentId: 'vid-1',
                nodeId: 'node-vid',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Uploading video... 72%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byTooltip('Cancel upload'), findsOneWidget);
    });

    testWidgets('Video displays retry button on failed or cancelled upload', (tester) async {
      final cancelledVideo = Attachment(
        id: 'vid-2',
        blockId: 'b-2',
        localPath: testVideoFile.path,
        mimeType: 'video/mp4',
        checksumSha256: 'hash-2',
        fileSize: 4096,
        uploadStatus: AttachmentUploadStatus.cancelled,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        deleted: false,
        isPinnedOffline: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attachmentProvider('vid-2').overrideWith((ref) => Future.value(cancelledVideo)),
            attachmentPathProvider(cancelledVideo).overrideWith((ref) => Future.value(testVideoFile.path)),
            attachmentUploadProgressProvider('vid-2').overrideWith((ref) => null),
            attachmentSyncServiceProvider.overrideWithValue(fakeSyncService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: KetionVideoPlayerComponent(
                attachmentId: 'vid-2',
                nodeId: 'node-vid',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Video upload failed or cancelled'), findsOneWidget);
      final retryBtn = find.widgetWithText(TextButton, 'Retry');
      expect(retryBtn, findsOneWidget);

      await tester.tap(retryBtn);
      await tester.pump();
      expect(fakeSyncService.retriedAttachment?.id, 'vid-2');
    });
  });
}
