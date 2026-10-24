import 'package:flutter/material.dart';
import '../../../../core/utils/result.dart';
import '../../domain/models/editor_open_target.dart';
import 'block_editor_widget.dart';
import 'super_editor_host.dart';

class KetionEditorHost extends StatefulWidget {
  final String pageId;
  final bool focusTitle;
  final Future<Result<void>> Function(String) onTitleChanged;
  final Future<Result<void>> Function(String) onIconChanged;
  final EditorOpenTarget? openTarget;

  const KetionEditorHost({
    super.key,
    required this.pageId,
    required this.onTitleChanged,
    required this.onIconChanged,
    this.focusTitle = false,
    this.openTarget,
  });

  // Development-only migration switch.
  static const bool useSuperEditor = true;

  @override
  State<KetionEditorHost> createState() => KetionEditorHostState();
}

class KetionEditorHostState extends State<KetionEditorHost> {
  final GlobalKey<SuperEditorHostState> _superEditorKey = GlobalKey();

  Future<void> flush() async {
    await _superEditorKey.currentState?.flush();
  }

  @override
  Widget build(BuildContext context) {
    if (KetionEditorHost.useSuperEditor) {
      return SuperEditorHost(
        key: _superEditorKey,
        pageId: widget.pageId,
        focusTitle: widget.focusTitle,
        onTitleChanged: widget.onTitleChanged,
        onIconChanged: widget.onIconChanged,
        openTarget: widget.openTarget,
      );
    } else {
      return BlockEditorWidget(
        pageId: widget.pageId,
        focusTitle: widget.focusTitle,
        onTitleChanged: widget.onTitleChanged,
        onIconChanged: widget.onIconChanged,
      );
    }
  }
}
