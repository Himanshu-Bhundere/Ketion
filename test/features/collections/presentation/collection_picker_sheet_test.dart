import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/collections/domain/entities/collection.dart';
import 'package:ketion/features/collections/domain/repositories/collection_repository.dart';
import 'package:ketion/features/collections/presentation/providers/collection_providers.dart';
import 'package:ketion/features/collections/presentation/widgets/collection_picker_sheet.dart';

class FakeCollectionRepository implements CollectionRepository {
  final List<Collection> collections = [
    Collection(
      id: 'col-1',
      name: 'Projects',
      icon: '📁',
      color: '#4A90E2',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Collection(
      id: 'col-2',
      name: 'Reading List',
      icon: '📚',
      color: '#50E3C2',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  final Map<String, Set<String>> pageCollectionsMap = {
    'page-123': {'col-1'},
  };

  @override
  Future<Result<void>> createCollection(Collection collection) async {
    collections.add(collection);
    return const Success(null);
  }

  @override
  Future<Result<Collection>> getCollection(String id) async {
    final col = collections.firstWhere((c) => c.id == id);
    return Success(col);
  }

  @override
  Future<Result<void>> updateCollection(Collection collection) async =>
      const Success(null);

  @override
  Future<Result<void>> deleteCollection(String id) async {
    collections.removeWhere((c) => c.id == id);
    return const Success(null);
  }

  @override
  Future<Result<List<Collection>>> getAllCollections() async {
    return Success(List.unmodifiable(collections));
  }

  @override
  Future<Result<List<Collection>>> getCollectionsForPage(String pageId) async {
    final assignedIds = pageCollectionsMap[pageId] ?? {};
    final assignedCols =
        collections.where((c) => assignedIds.contains(c.id)).toList();
    return Success(assignedCols);
  }

  @override
  Future<Result<void>> assignCollectionToPage(
    String pageId,
    String collectionId,
  ) async {
    pageCollectionsMap.putIfAbsent(pageId, () => {}).add(collectionId);
    return const Success(null);
  }

  @override
  Future<Result<void>> removeCollectionFromPage(
    String pageId,
    String collectionId,
  ) async {
    pageCollectionsMap[pageId]?.remove(collectionId);
    return const Success(null);
  }

  @override
  Future<Result<void>> setPageCollections(
    String pageId,
    List<String> collectionIds,
  ) async {
    pageCollectionsMap[pageId] = collectionIds.toSet();
    return const Success(null);
  }
}

void main() {
  late FakeCollectionRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeCollectionRepository();
  });

  Widget buildSheet({String? pageId}) {
    return ProviderScope(
      overrides: [
        collectionRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: CollectionPickerSheet(pageId: pageId),
        ),
      ),
    );
  }

  testWidgets('renders existing collections and shows assigned checkmark',
      (tester) async {
    await tester.pumpWidget(buildSheet(pageId: 'page-123'));
    await tester.pumpAndSettle();

    expect(find.text('Page Collections'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Reading List'), findsOneWidget);

    // Col-1 (Projects) is assigned to page-123
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);

    // Filter by search
    await tester.enterText(find.byType(TextField).first, 'Read');
    await tester.pumpAndSettle();

    expect(find.text('Projects'), findsNothing);
    expect(find.text('Reading List'), findsOneWidget);
  });

  testWidgets('toggles collection assignment to page', (tester) async {
    await tester.pumpWidget(buildSheet(pageId: 'page-123'));
    await tester.pumpAndSettle();

    // Tap 'Reading List' to assign
    await tester.tap(find.text('Reading List'));
    await tester.pumpAndSettle();

    expect(fakeRepo.pageCollectionsMap['page-123']?.contains('col-2'), isTrue);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));

    // Tap 'Projects' to unassign
    await tester.tap(find.text('Projects'));
    await tester.pumpAndSettle();

    expect(fakeRepo.pageCollectionsMap['page-123']?.contains('col-1'), isFalse);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('creates collection with validation and assigns to page',
      (tester) async {
    await tester.pumpWidget(buildSheet(pageId: 'page-123'));
    await tester.pumpAndSettle();

    // Open create dialog
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    expect(find.text('Create Collection'), findsOneWidget);

    final createBtn = find.widgetWithText(ElevatedButton, 'Create');
    await tester.tap(createBtn);
    await tester.pumpAndSettle();

    expect(find.text('Collection name cannot be empty'), findsOneWidget);

    // Duplicate check
    final dialogField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogField, '  Projects  ');
    await tester.tap(createBtn);
    await tester.pumpAndSettle();

    expect(
      find.text('A collection with this name already exists'),
      findsOneWidget,
    );

    // Valid create
    await tester.enterText(dialogField, '  Finance  ');
    await tester.tap(createBtn);
    await tester.pumpAndSettle();

    expect(fakeRepo.collections.any((c) => c.name == 'Finance'), isTrue);
    final created = fakeRepo.collections.firstWhere((c) => c.name == 'Finance');
    expect(
      fakeRepo.pageCollectionsMap['page-123']?.contains(created.id),
      isTrue,
    );

    expect(find.text('Finance'), findsOneWidget);
  });
}
