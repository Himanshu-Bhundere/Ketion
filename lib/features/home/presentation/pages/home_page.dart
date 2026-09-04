import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:ketion/core/router/routes.dart';
import 'package:ketion/core/theme/breakpoints.dart';
import 'package:ketion/features/editor/presentation/pages/editor_page.dart';
import 'package:uuid/uuid.dart';
import '../../../pages/domain/entities/page.dart' as entity;
import '../../../pages/presentation/providers/page_providers.dart';
import '../providers/home_providers.dart';
import 'package:ketion/features/import_export/presentation/providers/import_export_providers.dart';

class NewNoteIntent extends Intent {
  const NewNoteIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class CloseWindowIntent extends Intent {
  const CloseWindowIntent();
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isDragging = false;

  void _createNewNote(BuildContext context, bool isTemplate) async {
    final usecase = ref.read(createPageUseCaseProvider);
    final result = await usecase(
      title: isTemplate ? 'Untitled Template' : 'Untitled',
      isTemplate: isTemplate,
    );
    final newPage = result.valueOrNull;
    if (newPage == null) return;

    if (isTemplate) {
      ref.invalidate(templatePagesProvider);
    } else {
      ref.invalidate(recentPagesProvider);
    }

    _navigateToPage(context, newPage.id);
  }

  void _navigateToPage(BuildContext context, String pageId) {
    final width = MediaQuery.of(context).size.width;
    if (width >= AppBreakpoints.medium) {
      ref.read(activePageIdProvider.notifier).state = pageId;
    } else {
      context.push('/editor/$pageId');
    }
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    final importService = ref.read(importServiceProvider);
    bool imported = false;
    for (final file in details.files) {
      if (file.path.endsWith('.md') || file.path.endsWith('.txt')) {
        await importService.importMarkdownFromPath(file.path);
        imported = true;
      }
    }
    if (imported) {
      ref.invalidate(recentPagesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePageId = ref.watch(activePageIdProvider);
    
    // Add safe check for Platform to avoid web errors if you compile to web later, 
    // but assuming desktop/mobile for now.
    final bool isMacOS = !kIsWeb && Platform.isMacOS;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const NewNoteIntent(),
        LogicalKeySet(isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const SearchIntent(),
        LogicalKeySet(isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control, LogicalKeyboardKey.keyW): const CloseWindowIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          NewNoteIntent: CallbackAction<NewNoteIntent>(
            onInvoke: (Intent intent) => _createNewNote(context, false),
          ),
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (Intent intent) => context.push(Routes.search),
          ),
          CloseWindowIntent: CallbackAction<CloseWindowIntent>(
            onInvoke: (Intent intent) {
              if (activePageId != null) {
                ref.read(activePageIdProvider.notifier).state = null;
              }
              return null;
            },
          ),
        },
        child: DropTarget(
          onDragEntered: (details) => setState(() => _isDragging = true),
          onDragExited: (details) => setState(() => _isDragging = false),
          onDragDone: _handleDrop,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= AppBreakpoints.medium;
              
              final scaffold = _buildScaffold(context, isWide);

              if (isWide) {
                return Scaffold(
                  body: Row(
                    children: [
                      SizedBox(
                        width: 300,
                        child: scaffold,
                      ),
                      const VerticalDivider(width: 1, thickness: 1),
                      Expanded(
                        child: activePageId != null 
                          ? EditorPage(pageId: activePageId, key: ValueKey(activePageId)) 
                          : const Center(child: Text('Select or create a note')),
                      ),
                    ],
                  ),
                );
              }

              return scaffold;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, bool isWide) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ketion'),
          actions: [
            IconButton(
              icon: const Icon(Icons.file_upload),
              tooltip: 'Import Markdown',
              onPressed: () async {
                final importService = ref.read(importServiceProvider);
                await importService.importMarkdownFile();
                ref.invalidate(recentPagesProvider);
              },
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.push(Routes.search),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push(Routes.settings),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Recent'),
              Tab(text: 'Bookmarks'),
              Tab(text: 'Templates'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildPageList(ref.watch(recentPagesProvider)),
                _buildPageList(ref.watch(favoritePagesProvider)),
                _buildPageList(ref.watch(templatePagesProvider)),
              ],
            ),
            if (_isDragging)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Text(
                    'Drop to Import',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () {
                final tabController = DefaultTabController.of(context);
                _createNewNote(context, tabController.index == 2);
              },
            );
          }
        ),
      ),
    );
  }

  Widget _buildPageList(AsyncValue<List<entity.Page>> asyncPages) {
    return asyncPages.when(
      data: (pages) {
        if (pages.isEmpty) {
          return const Center(child: Text('No pages found.'));
        }
        return ListView.builder(
          itemCount: pages.length,
          itemBuilder: (context, index) {
            final page = pages[index];
            final activePageId = ref.watch(activePageIdProvider);
            final isSelected = page.id == activePageId;
            
            return ListTile(
              selected: isSelected,
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
              title: Text(page.title.isEmpty ? 'Untitled' : page.title),
              subtitle: Text(page.updatedAt.toString().substring(0, 16)),
              leading: Icon(page.isFavorite ? Icons.star : Icons.description),
              onTap: () => _navigateToPage(context, page.id),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
