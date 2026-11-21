import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

const List<String> defaultToolbarSymbolOrder = [
  'bullet_list',
  'heading',
  'image',
  'file',
  'hide_keyboard',
];

class FloatingToolbar extends ConsumerStatefulWidget {
  final VoidCallback onAddImage;
  final VoidCallback onAddFile;
  final VoidCallback onAddList;
  final VoidCallback onAddHeading;
  final VoidCallback? onHideKeyboard;
  final List<String>? initialOrder;
  final ValueChanged<List<String>>? onOrderChanged;

  const FloatingToolbar({
    super.key,
    required this.onAddImage,
    required this.onAddFile,
    required this.onAddList,
    required this.onAddHeading,
    this.onHideKeyboard,
    this.initialOrder,
    this.onOrderChanged,
  });

  @override
  ConsumerState<FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends ConsumerState<FloatingToolbar> {
  List<String>? _localOrder;

  static List<String> normalizeOrder(List<String>? order) {
    if (order == null || order.isEmpty) {
      return List<String>.from(defaultToolbarSymbolOrder);
    }
    final valid =
        order.where(defaultToolbarSymbolOrder.contains).toSet().toList();
    for (final defaultItem in defaultToolbarSymbolOrder) {
      if (!valid.contains(defaultItem)) {
        valid.add(defaultItem);
      }
    }
    return valid;
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final current = _getActiveOrder();
    final updated = List<String>.from(current);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    setState(() {
      _localOrder = updated;
    });

    if (widget.onOrderChanged != null) {
      widget.onOrderChanged!(updated);
    } else {
      ref
          .read(appSettingsProvider.notifier)
          .updateToolbarSymbolOrder(updated);
    }
  }

  List<String> _getActiveOrder() {
    if (_localOrder != null) {
      return _localOrder!;
    }
    if (widget.initialOrder != null) {
      return normalizeOrder(widget.initialOrder);
    }
    final settingsOrder = ref.watch(
      appSettingsProvider.select((s) => s.value?.toolbarSymbolOrder),
    );
    return normalizeOrder(settingsOrder);
  }

  Widget _getIconButtonForSymbol(BuildContext context, String symbolId) {
    final platform = Theme.of(context).platform;
    final isDesktop = platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;

    switch (symbolId) {
      case 'bullet_list':
        return IconButton(
          key: const ValueKey('toolbar_bullet_list'),
          icon: const Icon(Icons.format_list_bulleted),
          tooltip: isDesktop ? 'Bullet List' : null,
          onPressed: widget.onAddList,
        );
      case 'heading':
        return IconButton(
          key: const ValueKey('toolbar_heading'),
          icon: const Icon(Icons.title),
          tooltip: isDesktop ? 'Heading' : null,
          onPressed: widget.onAddHeading,
        );
      case 'image':
        return IconButton(
          key: const ValueKey('toolbar_image'),
          icon: const Icon(Icons.image),
          tooltip: isDesktop ? 'Image' : null,
          onPressed: widget.onAddImage,
        );
      case 'file':
        return IconButton(
          key: const ValueKey('toolbar_file'),
          icon: const Icon(Icons.attach_file),
          tooltip: isDesktop ? 'File' : null,
          onPressed: widget.onAddFile,
        );
      case 'hide_keyboard':
        return IconButton(
          key: const ValueKey('toolbar_hide_keyboard'),
          icon: const Icon(Icons.keyboard_hide),
          tooltip: isDesktop ? 'Hide Keyboard' : null,
          onPressed: widget.onHideKeyboard ??
              () {
                FocusScope.of(context).unfocus();
              },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _getIconOnly(String symbolId) {
    switch (symbolId) {
      case 'bullet_list':
        return const Icon(Icons.format_list_bulleted);
      case 'heading':
        return const Icon(Icons.title);
      case 'image':
        return const Icon(Icons.image);
      case 'file':
        return const Icon(Icons.attach_file);
      case 'hide_keyboard':
        return const Icon(Icons.keyboard_hide);
      default:
        return const Icon(Icons.circle);
    }
  }

  Widget _buildToolbarItem(
    BuildContext context,
    String symbolId,
    int index,
    bool isDesktop,
  ) {
    final button = _getIconButtonForSymbol(context, symbolId);
    final feedback = Material(
      elevation: 6.0,
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _getIconOnly(symbolId),
      ),
    );

    final draggable = isDesktop
        ? Draggable<int>(
            data: index,
            feedback: feedback,
            childWhenDragging: Opacity(opacity: 0.3, child: button),
            child: button,
          )
        : LongPressDraggable<int>(
            data: index,
            feedback: feedback,
            hapticFeedbackOnStart: true,
            childWhenDragging: Opacity(opacity: 0.3, child: button),
            child: button,
          );

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) {
        _onReorder(details.data, index);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          decoration: isHovered
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2.0,
                    ),
                  ),
                )
              : null,
          child: draggable,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeOrder = _getActiveOrder();
    final platform = Theme.of(context).platform;
    final isDesktop = platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < activeOrder.length; i++)
              _buildToolbarItem(context, activeOrder[i], i, isDesktop),
          ],
        ),
      ),
    );
  }
}
