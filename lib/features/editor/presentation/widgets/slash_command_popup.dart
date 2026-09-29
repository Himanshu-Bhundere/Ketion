import 'package:flutter/material.dart';
import 'slash_command_menu.dart';

class SlashCommandPopup extends StatefulWidget {
  final List<SlashCommandOption> options;
  final int selectedIndex;
  final void Function(int index) onOptionTapped;
  
  const SlashCommandPopup({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onOptionTapped,
  });

  @override
  State<SlashCommandPopup> createState() => _SlashCommandPopupState();
}

class _SlashCommandPopupState extends State<SlashCommandPopup> {
  late List<GlobalKey> _itemKeys;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _itemKeys = List.generate(widget.options.length, (_) => GlobalKey());
    _scrollToSelected();
  }

  @override
  void didUpdateWidget(SlashCommandPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.options.length != oldWidget.options.length) {
      _itemKeys = List.generate(widget.options.length, (_) => GlobalKey());
    } else if (widget.selectedIndex != oldWidget.selectedIndex) {
      _scrollToSelected();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.selectedIndex >= 0 && widget.selectedIndex < _itemKeys.length) {
        final key = _itemKeys[widget.selectedIndex];
        final context = key.currentContext;
        if (context != null) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final RenderBox list = _scrollController.position.context.storageContext.findRenderObject() as RenderBox;
          final position = box.localToGlobal(Offset.zero, ancestor: list);
          
          final double offset = _scrollController.offset + position.dy;
          final double viewportHeight = _scrollController.position.viewportDimension;
          
          if (position.dy < 0) {
            _scrollController.animateTo(
              offset - 8,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
            );
          } else if (position.dy + box.size.height > viewportHeight) {
            _scrollController.animateTo(
              offset + box.size.height - viewportHeight + 8,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 340),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
        ),
        child: widget.options.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No commands match'),
              )
            : SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.options.length, (index) {
                    final option = widget.options[index];
                    final isSelected = index == widget.selectedIndex;
                    final bool showHeader = index == 0 || widget.options[index - 1].category != option.category;

                    return Column(
                      key: _itemKeys[index],
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showHeader)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                            child: Text(
                              option.category.displayName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).hintColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        Opacity(
                          opacity: option.isSupported ? 1.0 : 0.5,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: ListTile(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              tileColor: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              leading: Icon(
                                option.icon,
                                size: 20,
                                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).iconTheme.color,
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      option.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!option.isSupported) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'COMING SOON',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                option.subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.7) : Theme.of(context).hintColor,
                                ),
                              ),
                              onTap: option.isSupported ? () => widget.onOptionTapped(index) : null,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
      ),
    );
  }
}
