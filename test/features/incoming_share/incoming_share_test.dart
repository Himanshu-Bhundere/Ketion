import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/features/incoming_share/domain/models/incoming_share_item.dart';
import 'package:ketion/features/incoming_share/presentation/providers/incoming_share_provider.dart';
import 'package:ketion/features/incoming_share/presentation/widgets/incoming_share_note_picker.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/features/pages/domain/entities/page.dart' as entity;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IncomingShareItem', () {
    test('serializes and deserializes correctly', () {
      const item = IncomingShareItem(
        type: IncomingShareType.file,
        name: 'document.pdf',
        localPath: '/tmp/document.pdf',
        mimeType: 'application/pdf',
        size: 1024,
      );

      final map = item.toMap();
      expect(map['type'], 'file');
      expect(map['name'], 'document.pdf');
      expect(map['localPath'], '/tmp/document.pdf');
      expect(map['mimeType'], 'application/pdf');
      expect(map['size'], 1024);

      final reconstructed = IncomingShareItem.fromMap(map);
      expect(reconstructed.type, IncomingShareType.file);
      expect(reconstructed.name, 'document.pdf');
      expect(reconstructed.localPath, '/tmp/document.pdf');
      expect(reconstructed.mimeType, 'application/pdf');
      expect(reconstructed.size, 1024);
    });

    test('supports link and text types', () {
      final linkItem = IncomingShareItem.fromMap({
        'type': 'link',
        'name': 'https://example.com',
        'url': 'https://example.com',
      });
      expect(linkItem.type, IncomingShareType.link);
      expect(linkItem.url, 'https://example.com');

      final textItem = IncomingShareItem.fromMap({
        'type': 'text',
        'name': 'Some notes',
        'text': 'Some notes from another app',
      });
      expect(textItem.type, IncomingShareType.text);
      expect(textItem.text, 'Some notes from another app');
    });
  });

  group('IncomingShareNotePicker Widget', () {
    testWidgets('renders item preview and note list', (tester) async {
      final now = DateTime.now();
      final dummyPages = [
        entity.Page(
          id: 'page-1',
          title: 'Project Roadmap',
          createdAt: now,
          updatedAt: now,
        ),
        entity.Page(
          id: 'page-2',
          title: 'Ideas & Sketches',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final items = [
        const IncomingShareItem(
          type: IncomingShareType.file,
          name: 'photo.jpg',
          mimeType: 'image/jpeg',
        ),
      ];

      List<String>? selected;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allPagesProvider.overrideWith((ref) => dummyPages),
          ],
          child: MaterialApp(
            home: IncomingShareNotePicker(
              items: items,
              onConfirm: (ids) async {
                selected = ids;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Attach to Note'), findsOneWidget);
      expect(find.text('photo.jpg'), findsOneWidget);
      expect(find.text('Project Roadmap'), findsOneWidget);
      expect(find.text('Ideas & Sketches'), findsOneWidget);

      // Select first note
      await tester.tap(find.text('Project Roadmap'));
      await tester.pumpAndSettle();

      // Tap Attach button
      await tester.tap(find.text('Attach (1)'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected, contains('page-1'));
    });
  });

  group('Context-sensitive direct attachment check', () {
    test('activeEditorPageIdProvider reflects currently focused editor note', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(activeEditorPageIdProvider), isNull);

      container.read(activeEditorPageIdProvider.notifier).state = 'note-123';
      expect(container.read(activeEditorPageIdProvider), 'note-123');

      container.read(activeEditorPageIdProvider.notifier).state = null;
      expect(container.read(activeEditorPageIdProvider), isNull);
    });
  });

  group('IncomingShareCoordinator regression', () {
    const channel = MethodChannel('com.example.ketion/share_target');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    testWidgets(
      'clears stale native active note and shows picker when no note is open',
      (tester) async {
        final recordedCalls = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
          recordedCalls.add(call);
          if (call.method == 'getLastOpenedNoteId') {
            return 'stale-last-note';
          }
          return null;
        });

        final now = DateTime.now().toUtc();
        final pages = [
          entity.Page(
            id: 'note-1',
            title: 'First Note',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        late BuildContext capturedContext;
        late WidgetRef capturedRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              allPagesProvider.overrideWith((ref) => pages),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    capturedContext = context;
                    capturedRef = ref;
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final coordinator = capturedRef.read(incomingShareCoordinatorProvider);
        await coordinator.handleIncomingItems(
          capturedContext,
          const [
            IncomingShareItem(
              type: IncomingShareType.file,
              name: 'clip.mp4',
              mimeType: 'video/mp4',
              localPath: '/tmp/clip.mp4',
            ),
          ],
        );
        await tester.pumpAndSettle();

        expect(
          recordedCalls
              .where((c) => c.method == 'setActiveNoteId')
              .map((c) => c.arguments)
              .toList(),
          equals([
            {'noteId': null},
          ]),
        );
        expect(find.byType(IncomingShareNotePicker), findsOneWidget);
        expect(find.text('clip.mp4'), findsOneWidget);
        expect(find.text('First Note'), findsOneWidget);
      },
    );

    testWidgets(
      'attaches directly when an editor note is open without showing picker',
      (tester) async {
        final attachedItems = <IncomingShareItem>[];

        late BuildContext capturedContext;
        late WidgetRef capturedRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeEditorPageIdProvider.overrideWith((ref) => 'active-note-1'),
              editorInsertItemCallbackProvider('active-note-1').overrideWith(
                (ref) => (item) async {
                  attachedItems.add(item);
                },
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    capturedContext = context;
                    capturedRef = ref;
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final coordinator = capturedRef.read(incomingShareCoordinatorProvider);
        await coordinator.handleIncomingItems(
          capturedContext,
          const [
            IncomingShareItem(
              type: IncomingShareType.file,
              name: 'photo.jpg',
              mimeType: 'image/jpeg',
              localPath: '/tmp/photo.jpg',
            ),
          ],
        );
        await tester.pumpAndSettle();

        expect(attachedItems.length, 1);
        expect(attachedItems.first.name, 'photo.jpg');
        expect(find.byType(IncomingShareNotePicker), findsNothing);
      },
    );
  });
}
