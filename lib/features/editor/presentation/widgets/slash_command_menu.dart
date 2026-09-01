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

class SlashCommandMenu extends StatelessWidget {
  final List<SlashCommandOption> options;

  const SlashCommandMenu({
    super.key,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: 300,
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            return ListTile(
              leading: Icon(option.icon),
              title: Text(option.title),
              subtitle:
                  Text(option.subtitle, style: const TextStyle(fontSize: 12)),
              onTap: option.onSelected,
            );
          },
        ),
      ),
    );
  }
}
