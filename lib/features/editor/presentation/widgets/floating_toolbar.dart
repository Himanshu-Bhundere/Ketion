import 'package:flutter/material.dart';

class FloatingToolbar extends StatelessWidget {
  final VoidCallback onAddImage;
  final VoidCallback onAddFile;
  final VoidCallback onAddList;
  final VoidCallback onAddHeading;

  const FloatingToolbar({
    super.key,
    required this.onAddImage,
    required this.onAddFile,
    required this.onAddList,
    required this.onAddHeading,
  });

  @override
  Widget build(BuildContext context) {
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
            IconButton(
              icon: const Icon(Icons.format_list_bulleted),
              tooltip: 'Bullet List',
              onPressed: onAddList,
            ),
            IconButton(
              icon: const Icon(Icons.title),
              tooltip: 'Heading',
              onPressed: onAddHeading,
            ),
            IconButton(
              icon: const Icon(Icons.image),
              tooltip: 'Image',
              onPressed: onAddImage,
            ),
            IconButton(
              icon: const Icon(Icons.attach_file),
              tooltip: 'File',
              onPressed: onAddFile,
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_hide),
              tooltip: 'Hide Keyboard',
              onPressed: () {
                FocusScope.of(context).unfocus();
              },
            ),
          ],
        ),
      ),
    );
  }
}
