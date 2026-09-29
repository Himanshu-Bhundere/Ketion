import 'package:flutter/material.dart';
import 'slash_command_menu.dart';

class SlashCommandPopup extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 300,
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        ),
        child: options.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No commands match'),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = index == selectedIndex;
                  final bool showHeader = index == 0 || options[index - 1].category != option.category;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showHeader)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            option.category.displayName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).hintColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ListTile(
                        tileColor: isSelected ? Theme.of(context).focusColor : null,
                        dense: true,
                        leading: Icon(option.icon, size: 20),
                        title: Text(option.title, style: const TextStyle(fontSize: 14)),
                        subtitle: Text(option.subtitle, style: const TextStyle(fontSize: 12)),
                        onTap: () => onOptionTapped(index),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
