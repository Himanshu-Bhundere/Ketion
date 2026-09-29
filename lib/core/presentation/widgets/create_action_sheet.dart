import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/features/pages/domain/entities/page.dart' as entity;
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';

class CreateActionSheet extends ConsumerStatefulWidget {
  const CreateActionSheet({super.key});

  static Future<entity.Page?> show(BuildContext context) {
    return showModalBottomSheet<entity.Page>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const CreateActionSheet(),
    );
  }

  @override
  ConsumerState<CreateActionSheet> createState() => _CreateActionSheetState();
}

class _CreateActionSheetState extends ConsumerState<CreateActionSheet> {
  bool _isCreating = false;

  Future<void> _createNote(BuildContext context) async {
    if (_isCreating) return;
    setState(() => _isCreating = true);
    final messenger = ScaffoldMessenger.of(context);

    final result = await ref.read(createPageUseCaseProvider)(title: '');
    result.fold(
      (page) {
        ref.invalidate(recentPagesProvider);
        ref.invalidate(favoritePagesProvider);
        ref.invalidate(pageProvider(page.id));
        if (mounted) {
          Navigator.of(context).pop(page);
        }
      },
      (error) {
        if (mounted) {
          setState(() => _isCreating = false);
        }
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to create note: $error')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Create New',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('New Note'),
            enabled: !_isCreating,
            onTap: () => _createNote(context),
          ),
          ListTile(
            leading: const Icon(Icons.check_box),
            title: const Text('Checklist'),
            subtitle: const Text('Coming Soon', style: TextStyle(fontStyle: FontStyle.italic)),
            enabled: false,
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Import'),
            subtitle: const Text('Coming Soon', style: TextStyle(fontStyle: FontStyle.italic)),
            enabled: false,
            onTap: () {},
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
