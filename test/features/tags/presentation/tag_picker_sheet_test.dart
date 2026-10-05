import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/tags/domain/entities/tag.dart';
import 'package:ketion/features/tags/domain/repositories/tag_repository.dart';
import 'package:ketion/features/tags/presentation/providers/tag_providers.dart';
import 'package:ketion/features/tags/presentation/widgets/tag_picker_sheet.dart';

class FakeTagRepository implements TagRepository {
  final List<Tag> tags = [
    Tag(
      id: 'tag-1',
      name: 'Work',
      color: '#4A90E2',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Tag(
      id: 'tag-2',
      name: 'Personal',
      color: '#50E3C2',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  final Map<String, Set<String>> pageTagsMap = {
    'page-123': {'tag-1'},
  };

  @override
  Future<Result<void>> createTag(Tag tag) async {
    tags.add(tag);
    return const Success(null);
  }

  @override
  Future<Result<Tag>> getTag(String id) async {
    final tag = tags.firstWhere((t) => t.id == id);
    return Success(tag);
  }

  @override
  Future<Result<void>> updateTag(Tag tag) async => const Success(null);

  @override
  Future<Result<void>> deleteTag(String id) async {
    tags.removeWhere((t) => t.id == id);
    return const Success(null);
  }

  @override
  Future<Result<List<Tag>>> getAllTags() async {
    return Success(List.unmodifiable(tags));
  }

  @override
  Future<Result<List<Tag>>> getTagsForPage(String pageId) async {
    final assignedIds = pageTagsMap[pageId] ?? {};
    final assignedTags = tags.where((t) => assignedIds.contains(t.id)).toList();
    return Success(assignedTags);
  }

  @override
  Future<Result<void>> assignTagToPage(String pageId, String tagId) async {
    pageTagsMap.putIfAbsent(pageId, () => {}).add(tagId);
    return const Success(null);
  }

  @override
  Future<Result<void>> removeTagFromPage(String pageId, String tagId) async {
    pageTagsMap[pageId]?.remove(tagId);
    return const Success(null);
  }

  @override
  Future<Result<void>> setPageTags(String pageId, List<String> tagIds) async {
    pageTagsMap[pageId] = tagIds.toSet();
    return const Success(null);
  }
}

void main() {
  late FakeTagRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeTagRepository();
  });

  Widget buildSheet({String? pageId}) {
    return ProviderScope(
      overrides: [
        tagRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: TagPickerSheet(pageId: pageId),
        ),
      ),
    );
  }

  testWidgets('renders existing tags with search and shows assigned checkmark',
      (tester) async {
    await tester.pumpWidget(buildSheet(pageId: 'page-123'));
    await tester.pumpAndSettle();

    expect(find.text('Page Tags'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);

    // Tag-1 (Work) is assigned to page-123
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);

    // Filter by search
    await tester.enterText(find.byType(TextField).first, 'Pers');
    await tester.pumpAndSettle();

    expect(find.text('Work'), findsNothing);
    expect(find.text('Personal'), findsOneWidget);
  });

  testWidgets('toggles assignment to page', (tester) async {
    await tester.pumpWidget(buildSheet(pageId: 'page-123'));
    await tester.pumpAndSettle();

    // Tap 'Personal' to assign it
    await tester.tap(find.text('Personal'));
    await tester.pumpAndSettle();

    expect(fakeRepo.pageTagsMap['page-123']?.contains('tag-2'), isTrue);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));

    // Tap 'Work' to unassign it
    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();

    expect(fakeRepo.pageTagsMap['page-123']?.contains('tag-1'), isFalse);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets(
      'creates new tag with validation and automatically assigns to page',
      (tester) async {
    await tester.pumpWidget(buildSheet(pageId: 'page-123'));
    await tester.pumpAndSettle();

    // Click '+' button to create tag
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    expect(find.text('Create Tag'), findsOneWidget);

    // Try submitting empty trimmed name
    final createBtn = find.widgetWithText(ElevatedButton, 'Create');
    await tester.tap(createBtn);
    await tester.pumpAndSettle();

    expect(find.text('Tag name cannot be empty'), findsOneWidget);

    // Try submitting duplicate name (case-insensitive)
    final dialogField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogField, '  work  ');
    await tester.tap(createBtn);
    await tester.pumpAndSettle();

    expect(find.text('A tag with this name already exists'), findsOneWidget);

    // Valid new name
    await tester.enterText(dialogField, '  Urgent  ');
    await tester.tap(createBtn);
    await tester.pumpAndSettle();

    // Dialog closed, tag added to repo and assigned to page
    expect(fakeRepo.tags.any((t) => t.name == 'Urgent'), isTrue);
    final createdTag = fakeRepo.tags.firstWhere((t) => t.name == 'Urgent');
    expect(fakeRepo.pageTagsMap['page-123']?.contains(createdTag.id), isTrue);

    // UI updated immediately
    expect(find.text('Urgent'), findsOneWidget);
  });

  testWidgets('empty search state offers create action', (tester) async {
    await tester.pumpWidget(buildSheet(pageId: 'page-123'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Nonexistent');
    await tester.pumpAndSettle();

    expect(find.text('No tags found.'), findsOneWidget);
    expect(find.text('Create "Nonexistent"'), findsOneWidget);

    await tester.tap(find.text('Create "Nonexistent"'));
    await tester.pumpAndSettle();

    expect(find.text('Create Tag'), findsOneWidget);
    // Dialog field pre-populated with search query
    expect(find.text('Nonexistent'), findsWidgets);
  });
}
