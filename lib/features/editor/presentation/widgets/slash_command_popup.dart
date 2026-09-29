import 'package:flutter/material.dart';
import 'slash_command_menu.dart';

class SlashCommandPopup extends StatelessWidget {
  final List<SlashCommandOption> options;
  final int selectedIndex;
  
  const SlashCommandPopup({
    super.key,
    required this.options,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 300,
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
                  return Container(
                    color: isSelected ? Theme.of(context).focusColor : null,
                    child: ListTile(
                      dense: true,
                      leading: Icon(option.icon, size: 20),
                      title: Text(option.title, style: const TextStyle(fontSize: 14)),
                      subtitle: Text(option.subtitle, style: const TextStyle(fontSize: 12)),
                      onTap: option.onSelected,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
