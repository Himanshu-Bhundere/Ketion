import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/result.dart';
import '../../../pages/domain/entities/page.dart' as entity;
import '../../../pages/presentation/providers/page_providers.dart';
import '../../../widgets/presentation/providers/widget_providers.dart';
import '../widgets/ketion_editor_host.dart';
import '../widgets/editor_top_bar.dart';
import '../../domain/models/editor_open_target.dart';

class EditorPage extends ConsumerStatefulWidget {
  final String pageId;
  final bool focusTitle;
  final EditorOpenTarget? openTarget;

  const EditorPage({
    super.key,
    required this.pageId,
    this.focusTitle = false,
    this.openTarget,
  });

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  final GlobalKey<KetionEditorHostState> _editorHostKey = GlobalKey();
  static final Map<String, Future<Result<void>>> _pageUpdateChains = {};
  bool _isExiting = false;

  Future<Result<void>> _updatePage({
    String? title,
    String? icon,
  }) {
    final previousChain =
        _pageUpdateChains[widget.pageId] ?? Future.value(const Success<void>(null));
    final currentUpdate = previousChain.then((_) async {
      final pageRepo = ref.read(pageRepositoryProvider);
      final pageResult = await pageRepo.getPage(widget.pageId);
      if (pageResult is Error) {
        return pageResult as Result<void>;
      }

      final page = (pageResult as Success<entity.Page>).value;
      final updatedPage = page.copyWith(
        title: title ?? page.title,
        icon: icon ?? page.icon,
      );

      final updateResult =
          await ref.read(updatePageUseCaseProvider)(updatedPage);
      if (updateResult is Success<void>) {
        ref.invalidate(pageProvider(widget.pageId));
        ref.invalidate(recentPagesProvider);
        ref.invalidate(favoritePagesProvider);
      }
      return updateResult;
    });

    _pageUpdateChains[widget.pageId] = currentUpdate;
    return currentUpdate;
  }

  Future<void> _handleBack(BuildContext context) async {
    if (_isExiting) return;
    _isExiting = true;

    try {
      final inFlightTitleUpdate = _pageUpdateChains[widget.pageId];
      if (inFlightTitleUpdate != null) {
        await inFlightTitleUpdate;
      }
      await _editorHostKey.currentState?.flush();
      await ref.read(updateWidgetsUseCaseProvider)();
    } catch (e) {
      debugPrint('Error during editor exit flush: $e');
    }

    if (!context.mounted) return;

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        appBar: EditorTopBar(
          pageId: widget.pageId,
          onBackPressed: () => _handleBack(context),
        ),
        body: KetionEditorHost(
          key: _editorHostKey,
          pageId: widget.pageId,
          focusTitle: widget.focusTitle,
          openTarget: widget.openTarget,
          onTitleChanged: (title) => _updatePage(title: title),
          onIconChanged: (icon) => _updatePage(icon: icon),
        ),
      ),
    );
  }
}
