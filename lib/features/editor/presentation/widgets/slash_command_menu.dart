import 'package:flutter/material.dart';

class SlashCommandOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onSelected;

  SlashCommandOption({
    required this.title,
    required this.subtitle,
    required this.icon,
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
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 340,
        constraints: const BoxConstraints(maxHeight: 440),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
                          onTap: option.onSelected,
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
