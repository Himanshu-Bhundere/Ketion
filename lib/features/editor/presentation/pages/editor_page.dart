import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/result.dart';
import '../../../pages/domain/entities/page.dart' as entity;
import '../../../pages/presentation/providers/page_providers.dart';
import '../widgets/ketion_editor_host.dart';
import '../widgets/editor_top_bar.dart';
import '../../domain/models/editor_open_target.dart';

class EditorPage extends ConsumerWidget {
  final String pageId;
  final bool focusTitle;
  final EditorOpenTarget? openTarget;

  const EditorPage({
    super.key,
    required this.pageId,
    this.focusTitle = false,
    this.openTarget,
  });

  static final Map<String, Future<Result<void>>> _pageUpdateChains = {};

  Future<Result<void>> _updatePage(
    WidgetRef ref, {
    String? title,
    String? icon,
  }) {
    final previousChain =
        _pageUpdateChains[pageId] ?? Future.value(const Success<void>(null));
    final currentUpdate = previousChain.then((_) async {
      final pageRepo = ref.read(pageRepositoryProvider);
      final pageResult = await pageRepo.getPage(pageId);
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
        ref.invalidate(pageProvider(pageId));
        ref.invalidate(recentPagesProvider);
        ref.invalidate(favoritePagesProvider);
      }
      return updateResult;
    });

    _pageUpdateChains[pageId] = currentUpdate;
    return currentUpdate;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go(Routes.home);
        }
      },
      child: Scaffold(
        appBar: EditorTopBar(pageId: pageId),
        body: KetionEditorHost(
          pageId: pageId,
          focusTitle: focusTitle,
          openTarget: openTarget,
          onTitleChanged: (title) => _updatePage(ref, title: title),
          onIconChanged: (icon) => _updatePage(ref, icon: icon),
        ),
      ),
    );
  }
}
