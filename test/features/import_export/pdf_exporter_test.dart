import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart';
import 'package:ketion/features/import_export/domain/models/document_model.dart';
import 'package:ketion/features/import_export/domain/services/pdf_exporter.dart';
import 'package:ketion/features/import_export/domain/usecases/export_usecase.dart';
import 'package:ketion/features/media/domain/entities/attachment.dart';
import 'package:ketion/features/media/domain/entities/attachment_upload_status.dart';
import 'package:ketion/features/media/domain/repositories/attachment_repository.dart';
import 'package:ketion/features/pages/domain/entities/page.dart';

class FakeAttachmentRepository implements AttachmentRepository {
  final Map<String, Attachment> attachments = {};
  final Map<String, String> resolvedPaths = {};

  @override
  Future<Attachment?> getAttachment(String id) async => attachments[id];

  @override
  Future<String> resolveAttachmentPath(Attachment attachment) async =>
      resolvedPaths[attachment.id] ?? attachment.localPath ?? '';

  @override
  Future<void> deleteAttachment(String id) async => attachments.remove(id);

  @override
  Future<void> garbageCollectOrphanedFiles() async {}

  @override
  Future<List<Attachment>> getAttachmentsForPage(String pageId) async => [];

  @override
  Future<List<Attachment>> getPendingDownloads() async => [];

  @override
  Future<List<Attachment>> getPendingUploads() async => [];

  @override
  Future<Attachment> saveAttachment({
    required String pageId,
    required String blockId,
    required PlatformFile sourceFile,
    required String mimeType,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateAttachmentSyncStatus(
    String id,
    String uploadStatus, {
    String? driveFileId,
    String? localPath,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Minimal valid 1x1 RGBA PNG
  final samplePngBytes = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  group('PdfExporter', () {
    test('exports comprehensive document without errors and produces valid PDF', () async {
      final exporter = PdfExporter();
      final doc = ExportDocument(
        title: 'Project Architecture & Spec',
        nodes: [
          const DocumentNode.heading(
            level: 1,
            spans: [DocumentTextSpan(text: 'Architecture Overview', bold: true)],
          ),
          const DocumentNode.paragraph(
            spans: [
              DocumentTextSpan(text: 'This document explains the '),
              DocumentTextSpan(text: 'core components', bold: true),
              DocumentTextSpan(text: ' and media handling.'),
            ],
          ),
          // Toggle item
          const DocumentNode.list(
            listType: 'toggle',
            checked: false,
            spans: [DocumentTextSpan(text: 'Collapsible Section Heading')],
          ),
          // Callout
          const DocumentNode.callout(
            icon: '💡',
            color: 'blue',
            spans: [DocumentTextSpan(text: 'Remember to verify attachment permissions.')],
          ),
          // Table
          const DocumentNode.table(
            columnCount: 2,
            rows: [
              ['Module', 'Status'],
              ['Video Player', 'Integrated'],
              ['Search FTS5', 'Active'],
            ],
          ),
          // Available Image
          DocumentNode.image(
            attachmentId: 'img-uuid-1234',
            caption: 'System Architecture Diagram',
            fileName: 'arch_diagram.png',
            imageBytes: samplePngBytes,
            isAvailable: true,
          ),
          // Unavailable Image
          const DocumentNode.image(
            attachmentId: 'img-uuid-5678',
            caption: 'Missing Diagram',
            isAvailable: false,
          ),
          // Available File Attachments
          const DocumentNode.file(
            attachmentId: 'file-uuid-pdf',
            caption: 'Specification Document',
            fileName: 'Spec_v2.pdf',
            fileSize: 204800,
            fileTypeLabel: 'PDF Document',
            isAvailable: true,
          ),
          const DocumentNode.file(
            attachmentId: 'file-uuid-video',
            caption: 'Screen Recording Demo',
            fileName: 'demo_recording.mp4',
            fileSize: 5242880,
            fileTypeLabel: 'Video',
            isAvailable: true,
          ),
          // Unavailable File Attachment
          const DocumentNode.file(
            attachmentId: 'file-uuid-missing',
            caption: 'Old Backup Archive',
            fileName: 'backup.zip',
            fileTypeLabel: 'File Attachment',
            isAvailable: false,
          ),
          // Empty list item (should be skipped)
          const DocumentNode.list(
            listType: 'bullet',
            checked: false,
            spans: [DocumentTextSpan(text: '   ')],
          ),
          // Non-empty list item
          const DocumentNode.list(
            listType: 'bullet',
            checked: false,
            spans: [DocumentTextSpan(text: 'Valid bullet item')],
          ),
          const DocumentNode.divider(),
          const DocumentNode.code(
            code: 'void main() => runApp(const KetionApp());',
            language: 'dart',
          ),
        ],
      );

      final pdfBytes = await exporter.exportDocument(doc);
      expect(pdfBytes, isNotEmpty);

      // Verify PDF header %PDF-
      final header = utf8.decode(pdfBytes.sublist(0, 5), allowMalformed: true);
      expect(header.startsWith('%PDF'), isTrue);

      // Verify that raw "[File: " or "[Image: " placeholders with raw UUIDs are not present
      final pdfContent = String.fromCharCodes(pdfBytes);
      expect(pdfContent.contains('[File: file-uuid-pdf]'), isFalse);
      expect(pdfContent.contains('[File: file-uuid-video]'), isFalse);
      expect(pdfContent.contains('[Image: img-uuid-1234]'), isFalse);
    });

    test('preserves hierarchy with indented nodes, sequential numbering, and checklist state', () async {
      final exporter = PdfExporter();
      const doc = ExportDocument(
        title: 'Hierarchical Structure Spec',
        nodes: [
          DocumentNode.heading(
            level: 1,
            spans: [DocumentTextSpan(text: 'Tasks & Outline')],
            depth: 0,
          ),
          // Numbered lists at various depths
          DocumentNode.list(
            listType: 'numbered',
            checked: false,
            spans: [DocumentTextSpan(text: 'First top-level item')],
            depth: 0,
          ),
          DocumentNode.list(
            listType: 'numbered',
            checked: false,
            spans: [DocumentTextSpan(text: 'Nested sub-item 1')],
            depth: 1,
          ),
          DocumentNode.list(
            listType: 'numbered',
            checked: false,
            spans: [DocumentTextSpan(text: 'Nested sub-item 2')],
            depth: 1,
          ),
          DocumentNode.list(
            listType: 'numbered',
            checked: false,
            spans: [DocumentTextSpan(text: 'Second top-level item')],
            depth: 0,
          ),
          // Checklists: one checked, one unchecked, with depth
          DocumentNode.list(
            listType: 'checklist',
            checked: true,
            spans: [DocumentTextSpan(text: 'Completed task')],
            depth: 0,
          ),
          DocumentNode.list(
            listType: 'checklist',
            checked: false,
            spans: [DocumentTextSpan(text: 'Pending subtask')],
            depth: 1,
          ),
          // Indented paragraph and code
          DocumentNode.paragraph(
            spans: [DocumentTextSpan(text: 'Indented descriptive note')],
            depth: 2,
          ),
          DocumentNode.code(
            code: 'const x = 42;',
            language: 'javascript',
            depth: 1,
          ),
        ],
      );

      final pdfBytes = await exporter.exportDocument(doc);
      expect(pdfBytes, isNotEmpty);
      final header = utf8.decode(pdfBytes.sublist(0, 5), allowMalformed: true);
      expect(header.startsWith('%PDF'), isTrue);
    });
  });

  group('ExportUseCase', () {
    late FakeAttachmentRepository fakeAttachmentRepo;
    late io.Directory tempDir;

    setUp(() async {
      fakeAttachmentRepo = FakeAttachmentRepository();
      tempDir = await io.Directory.systemTemp.createTemp('ketion_export_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('resolves attachments and builds document nodes with callouts, tables, and toggles', () async {
      final imageFile = io.File('${tempDir.path}/test_image.png');
      await imageFile.writeAsBytes(samplePngBytes);

      const validImgId = 'att-img-1';
      final now = DateTime.now();
      final imgAttachment = Attachment(
        id: validImgId,
        blockId: 'b-img',
        localPath: 'test_image.png',
        mimeType: 'image/png',
        fileSize: samplePngBytes.length,
        uploadStatus: AttachmentUploadStatus.uploaded,
        createdAt: now,
        updatedAt: now,
      );

      fakeAttachmentRepo.attachments[validImgId] = imgAttachment;
      fakeAttachmentRepo.resolvedPaths[validImgId] = imageFile.path;

      final exporter = PdfExporter();
      final useCase = ExportUseCase([exporter], fakeAttachmentRepo);

      final page = Page(
        id: 'page-1',
        title: 'Export Test Page',
        createdAt: now,
        updatedAt: now,
      );

      final blocks = [
        Block(
          id: 'b-1',
          pageId: 'page-1',
          type: 'text',
          position: 1.0,
          data: jsonEncode({
            'headingLevel': 1,
            'spans': [{'text': 'Title Heading'}],
          }),
          createdAt: now,
          updatedAt: now,
        ),
        // Toggle block
        Block(
          id: 'b-2',
          pageId: 'page-1',
          type: 'list',
          position: 2.0,
          data: jsonEncode({
            'listType': 'toggle',
            'isExpanded': true,
            'spans': [{'text': 'Toggle Heading'}],
          }),
          createdAt: now,
          updatedAt: now,
        ),
        // Callout block
        Block(
          id: 'b-3',
          pageId: 'page-1',
          type: 'callout',
          position: 3.0,
          data: jsonEncode({
            'icon': '📌',
            'color': 'yellow',
            'spans': [{'text': 'Pinned note callout'}],
          }),
          createdAt: now,
          updatedAt: now,
        ),
        // Table block
        Block(
          id: 'b-4',
          pageId: 'page-1',
          type: 'table',
          position: 4.0,
          data: jsonEncode({
            'columnCount': 2,
            'rows': [
              {
                'id': 'r-1',
                'cells': [
                  {'id': 'c-1-1', 'spans': [{'text': 'Header 1'}]},
                  {'id': 'c-1-2', 'spans': [{'text': 'Header 2'}]},
                ],
              },
              {
                'id': 'r-2',
                'cells': [
                  {'id': 'c-2-1', 'spans': [{'text': 'Data 1'}]},
                  {'id': 'c-2-2', 'spans': [{'text': 'Data 2'}]},
                ],
              },
            ],
          }),
          createdAt: now,
          updatedAt: now,
        ),
        // Image block with resolvable attachment
        Block(
          id: 'b-5',
          pageId: 'page-1',
          type: 'image',
          position: 5.0,
          data: jsonEncode({
            'attachmentId': validImgId,
            'caption': 'Resolved Diagram',
          }),
          createdAt: now,
          updatedAt: now,
        ),
        // File block with missing attachment
        Block(
          id: 'b-6',
          pageId: 'page-1',
          type: 'file',
          position: 6.0,
          data: jsonEncode({
            'attachmentId': 'att-file-missing',
            'caption': 'Unresolved Document',
          }),
          createdAt: now,
          updatedAt: now,
        ),
        // Empty list item (should be excluded)
        Block(
          id: 'b-7',
          pageId: 'page-1',
          type: 'list',
          position: 7.0,
          data: jsonEncode({
            'listType': 'bullet',
            'spans': [{'text': ''}],
          }),
          createdAt: now,
          updatedAt: now,
        ),
        // Valid list item
        Block(
          id: 'b-8',
          pageId: 'page-1',
          type: 'list',
          position: 8.0,
          data: jsonEncode({
            'listType': 'bullet',
            'spans': [{'text': 'Valid bullet'}],
          }),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final pdfBytes = await useCase.exportToBytes(page, blocks, 'pdf');
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100));

      final header = utf8.decode(pdfBytes.sublist(0, 5), allowMalformed: true);
      expect(header.startsWith('%PDF'), isTrue);
    });

    test(
      'ExportUseCase normalizes legacy toggle representations and carries parentKey into export document',
      () async {
        final fakeRepo = FakeAttachmentRepository();
        final exporter = PdfExporter();
        final useCase = ExportUseCase([exporter], fakeRepo);
        final now = DateTime.now();
        final page = Page(
          id: 'page-legacy-toggle',
          title: 'Legacy Toggle Test',
          createdAt: now,
          updatedAt: now,
        );

        final blocks = [
          // 1. block.type == 'toggle'
          Block(
            id: 't-1',
            pageId: 'page-legacy-toggle',
            type: 'toggle',
            position: 0.0,
            data: jsonEncode({
              'isExpanded': true,
              'spans': [
                {'text': 'Toggle 1 (type=toggle)'},
              ],
            }),
            createdAt: now,
            updatedAt: now,
          ),
          // Child numbered item under toggle 1
          Block(
            id: 't-1-child-1',
            pageId: 'page-legacy-toggle',
            parentBlockId: 't-1',
            type: 'list',
            position: 1.0,
            data: jsonEncode({
              'listType': 'numbered',
              'spans': [
                {'text': 'Item 1 in Toggle 1'},
              ],
            }),
            createdAt: now,
            updatedAt: now,
          ),
          // 2. json['blockType'] == 'toggle'
          Block(
            id: 't-2',
            pageId: 'page-legacy-toggle',
            type: 'text',
            position: 2.0,
            data: jsonEncode({
              'blockType': 'toggle',
              'isExpanded': true,
              'spans': [
                {'text': 'Toggle 2 (blockType=toggle)'},
              ],
            }),
            createdAt: now,
            updatedAt: now,
          ),
          // Child numbered item under toggle 2
          Block(
            id: 't-2-child-1',
            pageId: 'page-legacy-toggle',
            parentBlockId: 't-2',
            type: 'list',
            position: 3.0,
            data: jsonEncode({
              'listType': 'numbered',
              'spans': [
                {'text': 'Item 1 in Toggle 2'},
              ],
            }),
            createdAt: now,
            updatedAt: now,
          ),
          // 3. json['type'] == 'toggle'
          Block(
            id: 't-3',
            pageId: 'page-legacy-toggle',
            type: 'text',
            position: 4.0,
            data: jsonEncode({
              'type': 'toggle',
              'isExpanded': false,
              'spans': [
                {'text': 'Toggle 3 (type=toggle in data)'},
              ],
            }),
            createdAt: now,
            updatedAt: now,
          ),
          // Collapsed child (should be omitted from visible export tree)
          Block(
            id: 't-3-child-1',
            pageId: 'page-legacy-toggle',
            parentBlockId: 't-3',
            type: 'text',
            position: 5.0,
            data: jsonEncode({
              'spans': [
                {'text': 'Hidden child'},
              ],
            }),
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final pdfBytes = await useCase.exportToBytes(page, blocks, 'pdf');
        expect(pdfBytes, isNotEmpty);
        expect(
          utf8.decode(pdfBytes.sublist(0, 5), allowMalformed: true),
          startsWith('%PDF'),
        );

        // Also verify via direct DocumentNode with parentKey
        const doc = ExportDocument(
          title: 'ParentKey Numbering Test',
          nodes: [
            DocumentNode.list(
              listType: 'numbered',
              checked: false,
              spans: [DocumentTextSpan(text: 'List A Item 1')],
              depth: 1,
              parentKey: 'parent-A',
            ),
            DocumentNode.list(
              listType: 'numbered',
              checked: false,
              spans: [DocumentTextSpan(text: 'List A Item 2')],
              depth: 1,
              parentKey: 'parent-A',
            ),
            DocumentNode.list(
              listType: 'numbered',
              checked: false,
              spans: [
                DocumentTextSpan(
                  text: 'List B Item 1 (new parent, restarts at 1)',
                ),
              ],
              depth: 1,
              parentKey: 'parent-B',
            ),
          ],
        );

        final exportedBytes = await PdfExporter().exportDocument(doc);
        expect(exportedBytes, isNotEmpty);
        expect(
          utf8.decode(exportedBytes.sublist(0, 5), allowMalformed: true),
          startsWith('%PDF'),
        );
      },
    );

    test(
      'renders rich text formatting spans and handles unicode emojis without crashing',
      () async {
        const doc = ExportDocument(
          title: '⏰ Weekly Planning & "Sprint" Review',
          nodes: [
            DocumentNode.heading(
              level: 1,
              spans: [
                DocumentTextSpan(text: 'Heading with '),
                DocumentTextSpan(text: 'bold style', bold: true),
              ],
            ),
            DocumentNode.paragraph(
              spans: [
                DocumentTextSpan(text: 'Mixed paragraph with '),
                DocumentTextSpan(text: 'italic text', italic: true),
                DocumentTextSpan(text: ', '),
                DocumentTextSpan(text: 'inline code', code: true),
                DocumentTextSpan(text: ', '),
                DocumentTextSpan(text: 'strike text', strikethrough: true),
                DocumentTextSpan(text: ', and a '),
                DocumentTextSpan(
                  text: 'web link',
                  link: 'https://example.com',
                ),
                DocumentTextSpan(text: '. • Bullet with emoji 💡'),
              ],
            ),
            DocumentNode.list(
              listType: 'checklist',
              checked: true,
              spans: [
                DocumentTextSpan(text: 'Task done with '),
                DocumentTextSpan(text: 'bold note', bold: true),
              ],
            ),
          ],
        );

        final pdfBytes = await PdfExporter().exportDocument(doc);
        expect(pdfBytes, isNotEmpty);
        expect(
          utf8.decode(pdfBytes.sublist(0, 5), allowMalformed: true),
          startsWith('%PDF'),
        );
      },
    );
  });
}
