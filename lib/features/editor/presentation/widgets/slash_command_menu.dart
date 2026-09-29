import 'package:flutter/material.dart';

typedef SlashCommandAction = void Function(String nodeId);

enum SlashCommandCategory {
  basic('Basic Blocks'),
  list('Lists'),
  media('Media');

  final String displayName;
  const SlashCommandCategory(this.displayName);
}

class SlashCommandOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final SlashCommandCategory category;
  final List<String> aliases;
  final SlashCommandAction onSelected;

  SlashCommandOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.category,
    this.aliases = const [],
    required this.onSelected,
  });
}

/// Searchable command palette used by text blocks. Keeping the filtering local
/// makes command discovery responsive without coupling the menu to persistence.
class SlashCommandMenu extends StatefulWidget {
  final List<SlashCommandOption> options;

  const SlashCommandMenu({super.key, required this.options});

  @override
  State<SlashCommandMenu> createState() => _SlashCommandMenuState();
}

class _SlashCommandMenuState extends State<SlashCommandMenu> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final options = widget.options.where((option) {
      return query.isEmpty ||
          option.title.toLowerCase().contains(query) ||
          option.subtitle.toLowerCase().contains(query);
    }).toList();

    return Material(
      color: Theme.of(context).cardColor,
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 340,
        constraints: const BoxConstraints(maxHeight: 440),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search commands',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: options.isEmpty
                  ? const Center(child: Text('No matching command'))
                  : ListView.builder(
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        return ListTile(
                          leading: Icon(option.icon),
                          title: Text(option.title),
                          subtitle: Text(option.subtitle, style: const TextStyle(fontSize: 12)),
                          onTap: () {
                            // SlashCommandMenu does not have context of nodeId.
                            // If this widget is used, it needs refactoring.
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
