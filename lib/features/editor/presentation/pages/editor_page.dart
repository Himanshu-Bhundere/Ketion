import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../pages/presentation/providers/page_providers.dart';
import '../widgets/ketion_editor_host.dart';
import '../widgets/editor_top_bar.dart';

class EditorPage extends ConsumerWidget {
  final String pageId;
  final bool focusTitle;

  const EditorPage({
    super.key,
    required this.pageId,
    this.focusTitle = false,
  });

  Future<Result<void>> _updatePage(
    WidgetRef ref, {
    String? title,
    String? icon,
  }) async {
    final page = ref.read(pageProvider(pageId)).valueOrNull;
    if (page == null) {
      return const Error(StorageFailure('Page is unavailable'));
    }

    final updatedPage = page.copyWith(title: title ?? page.title, icon: icon ?? page.icon);
    final result = await ref.read(updatePageUseCaseProvider)(updatedPage);
    if (result is Success<void>) {
      ref.invalidate(pageProvider(pageId));
      ref.invalidate(recentPagesProvider);
      ref.invalidate(favoritePagesProvider);
    }
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: EditorTopBar(pageId: pageId),
      body: KetionEditorHost(
        pageId: pageId,
        focusTitle: focusTitle,
        onTitleChanged: (title) => _updatePage(ref, title: title),
        onIconChanged: (icon) => _updatePage(ref, icon: icon),
      ),
    );
  }
}
