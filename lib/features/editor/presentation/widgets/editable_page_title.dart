import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/result.dart';
import '../../../pages/domain/entities/page.dart' as entity;

class EditablePageTitle extends StatefulWidget {
  final entity.Page page;
  final Future<Result<void>> Function(String title) onTitleChanged;
  final bool autofocus;

  const EditablePageTitle({
    super.key,
    required this.page,
    required this.onTitleChanged,
    this.autofocus = false,
  });

  @override
  State<EditablePageTitle> createState() => _EditablePageTitleState();
}

class _EditablePageTitleState extends State<EditablePageTitle> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;
  late String _lastPersistedTitle;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _lastPersistedTitle = widget.page.title;
    _controller = TextEditingController(text: _lastPersistedTitle);
    _focusNode = FocusNode()
      ..addListener(() {
        if (!_focusNode.hasFocus) unawaited(_flushTitle());
      });
  }

  @override
  void didUpdateWidget(EditablePageTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pageChanged = widget.page.id != oldWidget.page.id;
    final receivedExternalTitle = widget.page.title != oldWidget.page.title;
    final hasLocalEdit = _controller.text != _lastPersistedTitle || _isSaving;
    if (pageChanged || (receivedExternalTitle && !_focusNode.hasFocus && !hasLocalEdit)) {
      _lastPersistedTitle = widget.page.title;
      _controller.value = TextEditingValue(
        text: _lastPersistedTitle,
        selection: TextSelection.collapsed(offset: _lastPersistedTitle.length),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_flushTitle());
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => unawaited(_flushTitle()));
  }

  Future<void> _flushTitle() async {
    _debounce?.cancel();
    if (_isSaving || _controller.text == _lastPersistedTitle) return;
    _isSaving = true;
    try {
      while (_controller.text != _lastPersistedTitle) {
        final titleToPersist = _controller.text;
        final result = await widget.onTitleChanged(titleToPersist);
        if (result is Error<void>) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not save title. Your edit will be retried.')),
            );
            _debounce = Timer(
              const Duration(seconds: 2),
              () => unawaited(_flushTitle()),
            );
          }
          return;
        }
        _lastPersistedTitle = titleToPersist;
      }
    } finally {
      _isSaving = false;
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Page Title',
        textField: true,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          style: AppTypography.pageTitle,
          decoration: const InputDecoration(
            hintText: 'Untitled',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: _onChanged,
          maxLines: null,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
        ),
      );
}
