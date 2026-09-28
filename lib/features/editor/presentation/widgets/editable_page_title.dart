import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../pages/domain/entities/page.dart' as entity;
import '../../../pages/presentation/providers/page_providers.dart';

class EditablePageTitle extends ConsumerStatefulWidget {
  final entity.Page page;
  final ValueChanged<String>? onTitleChanged;
  final bool autofocus;

  const EditablePageTitle({
    super.key,
    required this.page,
    this.onTitleChanged,
    this.autofocus = false,
  });

  @override
  ConsumerState<EditablePageTitle> createState() => _EditablePageTitleState();
}

class _EditablePageTitleState extends ConsumerState<EditablePageTitle> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _debounce;
  String _lastSavedTitle = '';

  @override
  void initState() {
    super.initState();
    _lastSavedTitle = widget.page.title;
    _controller = TextEditingController(text: _lastSavedTitle);
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _saveTitleIfChanged();
      }
    });
  }

  @override
  void didUpdateWidget(EditablePageTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.page.id != oldWidget.page.id) {
      _lastSavedTitle = widget.page.title;
      _controller.text = _lastSavedTitle;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _saveTitleIfChanged();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _saveTitleIfChanged();
    });
  }

  void _saveTitleIfChanged() {
    final newTitle = _controller.text;
    
    if (newTitle != _lastSavedTitle) {
      _lastSavedTitle = newTitle;
      
      final updatedPage = widget.page.copyWith(title: newTitle);
      ref.read(updatePageUseCaseProvider)(updatedPage);
      
      widget.onTitleChanged?.call(newTitle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
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
}
