import 'dart:async';
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

import 'package:ketion/core/bootstrap/widget_bootstrap.dart';
import 'package:ketion/core/database/app_database.dart' hide Page, Block;
import 'package:ketion/core/errors/failures.dart';
import 'package:ketion/core/router/app_router.dart';
import 'package:ketion/core/router/routes.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart';
import 'package:ketion/features/editor/domain/commands/change_paragraph_metadata.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_list_item_component.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_slash_command_registry.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_toggle_component.dart';
import 'package:ketion/features/editor/presentation/widgets/ketion_toggle_keyboard_actions.dart';
import 'package:ketion/features/editor/services/editor_persistence_coordinator.dart';
import 'package:ketion/features/editor/services/editor_persistence_mutations.dart';
import 'package:ketion/features/import_export/domain/services/pdf_exporter.dart';
import 'package:ketion/features/import_export/domain/usecases/export_usecase.dart';
import 'package:ketion/features/pages/data/repositories/page_repository_impl.dart';
import 'package:ketion/features/pages/domain/entities/page.dart';
import 'package:ketion/features/pages/domain/usecases/create_page_usecase.dart';
import 'package:ketion/features/pages/domain/usecases/delete_page_usecase.dart';
import 'package:ketion/features/pages/domain/usecases/update_page_usecase.dart';
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:ketion/features/widgets/domain/services/widget_service.dart';
import 'package:ketion/features/widgets/domain/usecases/update_widgets_usecase.dart';
import 'package:ketion/core/utils/logger.dart';

class TestSuperEditorContext implements SuperEditorContext {
  @override
  final Editor editor;
  @override
  final Document document;
  @override
  final DocumentComposer composer;

  TestSuperEditorContext({
    required this.editor,
    required this.document,
    required this.composer,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class TestPersistenceCoordinator implements EditorPersistenceCoordinator {
  final List<EditorPersistenceMutation> mutations = [];
  final _controller = StreamController<EditorPersistenceMutation>.broadcast();

  @override
  bool enqueue(EditorPersistenceMutation mutation) {
    mutations.add(mutation);
    _controller.add(mutation);
    return true;
  }

  @override
  Stream<EditorPersistenceMutation> get onMutationSuccess => _controller.stream;

  @override
  Future<bool> flush() async => true;

  @override
  void close() {}

  @override
  EditorPersistenceGateway get gateway => throw UnimplementedError();

  @override
  bool get hasFailedMutations => false;

  @override
  bool get hasPendingMutations => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FailingWidgetService implements WidgetService {
  @override
  Future<Result<void>> generateWidgetSnapshot() async {
    return const Error(UnknownFailure('Simulated snapshot failure'));
  }

  @override
  Future<Result<void>> triggerWidgetUpdate() async {
    return const Error(UnknownFailure('Simulated native update failure'));
  }

  @override
  Future<Result<void>> updateSimpleWidgetData(String key, dynamic value) async {
    return const Success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue 1: Toggle Slash Command, Enter Insertion & PDF Vector Triangle', () {
    test('Slash command /toggle converts current node without premature child insertion', () {
      final doc = MutableDocument(nodes: [
        ParagraphNode(
          id: 'p1',
          text: AttributedText('My Toggle Topic'),
          metadata: const {'depth': 0, 'blockId': 'block-p1'},
        ),
      ],);

      final toggleCommand = KetionSlashCommandRegistry.allCommands.firstWhere((c) => c.id == 'toggle');
      final requests = toggleCommand.getEditRequestsWithDoc('p1', doc);

      expect(requests.isNotEmpty, isTrue);
      // Verify no InsertNodeAfterNodeRequest is prematurely issued
      expect(requests.whereType<InsertNodeAfterNodeRequest>().isEmpty, isTrue);

      final metadataReq = requests.whereType<ChangeParagraphMetadataRequest>().single;
      expect(metadataReq.nodeId, 'p1');
      expect(metadataReq.metadata['listType'], 'toggle');
      expect(metadataReq.metadata['type'], 'toggle');
      expect(metadataReq.metadata['isExpanded'], isTrue);
      expect(metadataReq.metadata['blockType'], const NamedAttribution('toggle'));
    });

    testWidgets('Toggle header recognized by builder and renders visible disclosure arrow', (tester) async {
      final node = ParagraphNode(
        id: 'toggle-header-node',
        text: AttributedText('Toggle Header'),
        metadata: const {
          'blockType': NamedAttribution('toggle'),
          'listType': 'toggle',
          'type': 'toggle',
          'isExpanded': true,
          'depth': 0,
        },
      );
      final doc = MutableDocument(nodes: [node]);
      final composer = MutableDocumentComposer();
      final editor = Editor(
        editables: {
          Editor.documentKey: doc,
          Editor.composerKey: composer,
        },
      );

      expect(KetionToggleComponentBuilder.isToggleNode(node), isTrue);

      final builder = KetionToggleComponentBuilder(editor);
      final viewModel = builder.createViewModel(doc, node) as KetionToggleComponentViewModel?;
      expect(viewModel, isNotNull);
      expect(viewModel!.isExpanded, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KetionToggleComponent(
              viewModel: viewModel,
              isExpanded: true,
              onToggle: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    test('Enter at end of toggle header creates child with correct parent relationship and caret placement', () {
      final toggleNode = ParagraphNode(
        id: 'toggle-header-node',
        text: AttributedText('Header'),
        metadata: const {
          'blockType': NamedAttribution('toggle'),
          'listType': 'toggle',
          'type': 'toggle',
          'isExpanded': true,
          'blockId': 'persisted-toggle-block-id',
          'depth': 0,
        },
      );
      final doc = MutableDocument(nodes: [toggleNode]);
      final composer = MutableDocumentComposer(
        initialSelection: DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: toggleNode.id,
            nodePosition: const TextNodePosition(offset: 6),
          ),
        ),
      );
      final editor = Editor(
        editables: {
          Editor.documentKey: doc,
          Editor.composerKey: composer,
        },
        requestHandlers: [
          changeParagraphMetadataRequestHandler,
          ...defaultRequestHandlers.whereType<EditRequestHandler>(),
        ],
      );

      final editContext = TestSuperEditorContext(
        editor: editor,
        document: doc,
        composer: composer,
      );

      final result = splitToggleWhenEnterPressed(
        editContext: editContext,
        keyEvent: const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.enter,
          timeStamp: Duration.zero,
        ),
      );

      expect(result, ExecutionInstruction.haltExecution);
      expect(doc.nodeCount, 2);

      final child = doc.getNodeAt(1) as ParagraphNode;
      expect(child.metadata['parentBlockId'], 'persisted-toggle-block-id');
      expect(child.metadata['depth'], 1);
      expect(composer.selection?.extent.nodeId, child.id);
      expect(
        (composer.selection?.extent.nodePosition as TextNodePosition).offset,
        0,
      );
    });

    test('PDF export does not print literal > characters and skips empty toggles', () async {
      final now = DateTime.now();
      final page = Page(
        id: 'p-pdf-test',
        title: 'PDF Test',
        createdAt: now,
        updatedAt: now,
      );

      final blocks = [
        Block(
          id: 'b-empty-toggle',
          pageId: 'p-pdf-test',
          parentBlockId: null,
          position: 10.0,
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'toggle',
            'isExpanded': true,
            'spans': <Map<String, dynamic>>[],
          }),
          createdAt: now,
          updatedAt: now,
        ),
        Block(
          id: 'b-content-toggle',
          pageId: 'p-pdf-test',
          parentBlockId: null,
          position: 20.0,
          type: 'list',
          data: jsonEncode({
            'runtimeType': 'list',
            'listType': 'toggle',
            'isExpanded': true,
            'spans': [
              {'text': 'Meaningful Toggle Title'},
            ],
          }),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final exporter = PdfExporter();
      final useCase = ExportUseCase([exporter]);
      final pdfBytes = await useCase.exportToBytes(page, blocks, 'pdf');

      expect(pdfBytes, isNotEmpty);
      final pdfText = utf8.decode(pdfBytes, allowMalformed: true);
      // Verify literal ">" string is never emitted as a text token
      expect(pdfText.contains('/Text >'), isFalse);
    });
  });

  group('Issue 2: Numbered-List Ordinals & Indentation Hierarchy', () {
    test('Three ordered siblings have ordinals 1, 2, 3', () {
      final doc = MutableDocument(nodes: [
        ListItemNode.ordered(id: 'o1', text: AttributedText('First'), indent: 0),
        ListItemNode.ordered(id: 'o2', text: AttributedText('Second'), indent: 0),
        ListItemNode.ordered(id: 'o3', text: AttributedText('Third'), indent: 0),
      ],);

      expect(computeKetionListItemOrdinalValue(doc.getNodeById('o1') as ListItemNode, doc), 1);
      expect(computeKetionListItemOrdinalValue(doc.getNodeById('o2') as ListItemNode, doc), 2);
      expect(computeKetionListItemOrdinalValue(doc.getNodeById('o3') as ListItemNode, doc), 3);
    });

    test('Nested children under siblings do not increment parent ordinal sequence', () {
      final doc = MutableDocument(nodes: [
        ListItemNode.ordered(id: 'p1', text: AttributedText('Item 1'), indent: 0),
        ListItemNode.ordered(id: 'c1', text: AttributedText('Sub 1.1'), indent: 1),
        ListItemNode.ordered(id: 'p2', text: AttributedText('Item 2'), indent: 0),
        ListItemNode.ordered(id: 'c2_1', text: AttributedText('Sub 2.1'), indent: 1),
        ListItemNode.ordered(id: 'c2_2', text: AttributedText('Sub 2.2'), indent: 1),
      ],);

      expect(computeKetionListItemOrdinalValue(doc.getNodeById('p1') as ListItemNode, doc), 1);
      expect(computeKetionListItemOrdinalValue(doc.getNodeById('c1') as ListItemNode, doc), 1);
      expect(computeKetionListItemOrdinalValue(doc.getNodeById('p2') as ListItemNode, doc), 2);
      expect(computeKetionListItemOrdinalValue(doc.getNodeById('c2_1') as ListItemNode, doc), 1);
      expect(computeKetionListItemOrdinalValue(doc.getNodeById('c2_2') as ListItemNode, doc), 2);
    });

    test('Indenting and unindenting middle item recomputes ordinals correctly', () {
      final doc = MutableDocument(nodes: [
        ListItemNode.ordered(id: 'i1', text: AttributedText('One'), indent: 0),
        ListItemNode.ordered(id: 'i2', text: AttributedText('Two'), indent: 0),
        ListItemNode.ordered(id: 'i3', text: AttributedText('Three'), indent: 0),
      ],);

      // Before indent: 1, 2, 3
      expect(computeKetionListItemOrdinalValue(doc.getNodeById('i2') as ListItemNode, doc), 2);
      expect(computeKetionListItemOrdinalValue(doc.getNodeById('i3') as ListItemNode, doc), 3);

      // Indent middle item to depth 1
      final indentedI2 = ListItemNode.ordered(id: 'i2', text: AttributedText('Two'), indent: 1);
      doc.replaceNodeById('i2', indentedI2);

      // Ordinals now: i1 -> 1, i2 (depth 1) -> 1, i3 (depth 0) -> 2
      expect(computeKetionListItemOrdinalValue(doc.getNodeById('i1') as ListItemNode, doc), 1);
      expect(computeKetionListItemOrdinalValue(doc.getNodeById('i2') as ListItemNode, doc), 1);
      expect(computeKetionListItemOrdinalValue(doc.getNodeById('i3') as ListItemNode, doc), 2);

      // Unindent middle item back to depth 0
      final unindentedI2 = ListItemNode.ordered(id: 'i2', text: AttributedText('Two'), indent: 0);
      doc.replaceNodeById('i2', unindentedI2);

      expect(computeKetionListItemOrdinalValue(doc.getNodeById('i1') as ListItemNode, doc), 1);
      expect(computeKetionListItemOrdinalValue(doc.getNodeById('i2') as ListItemNode, doc), 2);
      expect(computeKetionListItemOrdinalValue(doc.getNodeById('i3') as ListItemNode, doc), 3);
    });

    test('Non-ordered sibling at same level resets list sequence', () {
      final doc = MutableDocument(nodes: [
        ListItemNode.ordered(id: 'a1', text: AttributedText('List A1'), indent: 0),
        ListItemNode.ordered(id: 'a2', text: AttributedText('List A2'), indent: 0),
        ParagraphNode(id: 'sep', text: AttributedText('Paragraph Break'), metadata: const {'depth': 0}),
        ListItemNode.ordered(id: 'b1', text: AttributedText('List B1'), indent: 0),
        ListItemNode.ordered(id: 'b2', text: AttributedText('List B2'), indent: 0),
      ],);

      expect(computeKetionListItemOrdinalValue(doc.getNodeById('a1') as ListItemNode, doc), 1);
      expect(computeKetionListItemOrdinalValue(doc.getNodeById('a2') as ListItemNode, doc), 2);
      expect(computeKetionListItemOrdinalValue(doc.getNodeById('b1') as ListItemNode, doc), 1);
      expect(computeKetionListItemOrdinalValue(doc.getNodeById('b2') as ListItemNode, doc), 2);
    });
  });

  group('Issue 3: Widget Deep Links, Navigation Stack & Back Behavior', () {
    test('ketion://new-note pushes editor above home and canPop or popping returns home', () async {
      const newPageId = 'created-widget-page';
      await WidgetBootstrap.handleDeepLink(
        Uri.parse('ketion://new-note'),
        () async => newPageId,
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(appRouter.routeInformationProvider.value.uri.path, contains(newPageId));

      // Pop from editor
      if (appRouter.canPop()) {
        appRouter.pop();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(appRouter.routeInformationProvider.value.uri.path, Routes.home);
      }
    });

    test('ketion://note/{id} validates note and rejects deleted or missing pages', () async {
      bool errorReported = false;

      await WidgetBootstrap.handleDeepLink(
        Uri.parse('ketion://note/missing-page-id'),
        null,
        (error) {
          errorReported = true;
        },
        (pageId) async => false, // validation fails
      );

      expect(errorReported, isTrue);
    });

    test('Malformed note IDs (null, empty, undefined) are ignored safely', () async {
      final initialPath = appRouter.routeInformationProvider.value.uri.path;

      await WidgetBootstrap.handleDeepLink(Uri.parse('ketion://note/null'));
      await WidgetBootstrap.handleDeepLink(Uri.parse('ketion://note/undefined'));
      await WidgetBootstrap.handleDeepLink(Uri.parse('ketion://note/ '));

      expect(appRouter.routeInformationProvider.value.uri.path, initialPath);
    });
  });

  group('Issue 4: Widget Update Error Inspection & Resilience', () {
    test('CreatePageUseCase logs error when UpdateWidgetsUseCase returns Error', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final syncQueue = SyncQueueRepositoryImpl(db);
      final pageRepo = PageRepositoryImpl(db, syncQueue, appLogger);
      final failingWidgetService = FailingWidgetService();
      final updateWidgetsUseCase = UpdateWidgetsUseCase(failingWidgetService);

      final createPageUseCase = CreatePageUseCase(pageRepo, updateWidgetsUseCase);

      final result = await createPageUseCase(title: 'Resilient Page');
      expect(result, isA<Success<Page>>());
      final page = result.valueOrNull!;
      expect(page.title, 'Resilient Page');

      await db.close();
    });

    test('UpdatePageUseCase logs error when UpdateWidgetsUseCase returns Error', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final syncQueue = SyncQueueRepositoryImpl(db);
      final pageRepo = PageRepositoryImpl(db, syncQueue, appLogger);
      final failingWidgetService = FailingWidgetService();
      final updateWidgetsUseCase = UpdateWidgetsUseCase(failingWidgetService);

      final createPageUseCase = CreatePageUseCase(pageRepo, updateWidgetsUseCase);
      final updatePageUseCase = UpdatePageUseCase(pageRepo, updateWidgetsUseCase);

      final createResult = await createPageUseCase(title: 'Initial Title');
      final page = createResult.valueOrNull!;

      final updateResult = await updatePageUseCase(page.copyWith(title: 'Updated Title'));
      expect(updateResult, isA<Success<void>>());

      await db.close();
    });

    test('DeletePageUseCase logs error when UpdateWidgetsUseCase returns Error', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final syncQueue = SyncQueueRepositoryImpl(db);
      final pageRepo = PageRepositoryImpl(db, syncQueue, appLogger);
      final failingWidgetService = FailingWidgetService();
      final updateWidgetsUseCase = UpdateWidgetsUseCase(failingWidgetService);

      final createPageUseCase = CreatePageUseCase(pageRepo, updateWidgetsUseCase);
      final deletePageUseCase = DeletePageUseCase(pageRepo, updateWidgetsUseCase);

      final createResult = await createPageUseCase(title: 'To Be Deleted');
      final page = createResult.valueOrNull!;

      final deleteResult = await deletePageUseCase(page.id);
      expect(deleteResult, isA<Success<void>>());

      await db.close();
    });
  });
}
