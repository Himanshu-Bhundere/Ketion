import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../pages/presentation/providers/page_providers.dart';
import '../../domain/models/incoming_share_item.dart';

class IncomingShareNotePicker extends ConsumerStatefulWidget {
  final List<IncomingShareItem> items;
  final Future<void> Function(List<String> selectedPageIds) onConfirm;
  final Future<String?> Function()? onCreateNewNote;

  const IncomingShareNotePicker({
    super.key,
    required this.items,
    required this.onConfirm,
    this.onCreateNewNote,
  });

  static Future<void> show(
    BuildContext context, {
    required List<IncomingShareItem> items,
    required Future<void> Function(List<String> selectedPageIds) onConfirm,
    Future<String?> Function()? onCreateNewNote,
  }) async {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    if (isDesktop) {
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
            child: IncomingShareNotePicker(
              items: items,
              onConfirm: onConfirm,
              onCreateNewNote: onCreateNewNote,
            ),
          ),
        ),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.85,
          child: IncomingShareNotePicker(
            items: items,
            onConfirm: onConfirm,
            onCreateNewNote: onCreateNewNote,
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<IncomingShareNotePicker> createState() =>
      _IncomingShareNotePickerState();
}

class _IncomingShareNotePickerState
    extends ConsumerState<IncomingShareNotePicker> {
  final Set<String> _selectedPageIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAttaching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pagesAsync = ref.watch(allPagesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.share_outlined,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attach to Note',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.items.length} item(s) to attach',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Cancel',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Quick Search & New Note
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim().toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search notes...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    if (widget.onCreateNewNote != null) ...[
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: _isAttaching ? null : _handleCreateNewNote,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Note'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Items preview strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.items.map((item) {
                  IconData itemIcon;
                  switch (item.type) {
                    case IncomingShareType.link:
                      itemIcon = Icons.link;
                      break;
                    case IncomingShareType.text:
                      itemIcon = Icons.text_snippet_outlined;
                      break;
                    case IncomingShareType.file:
                      itemIcon = _getFileIcon(item.mimeType, item.name);
                      break;
                  }

                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(itemIcon, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            item.name,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Page list
          Expanded(
            child: pagesAsync.when(
              data: (pages) {
                final filtered = pages.where((p) {
                  if (p.deleted || p.isArchived) return false;
                  if (_searchQuery.isEmpty) return true;
                  return p.title.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No notes yet'
                              : 'No matching notes found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final page = filtered[index];
                    final isSelected = _selectedPageIds.contains(page.id);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedPageIds.add(page.id);
                          } else {
                            _selectedPageIds.remove(page.id);
                          }
                        });
                      },
                      dense: true,
                      title: Text(
                        page.title.isEmpty ? 'Untitled Note' : page.title,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      secondary: Text(
                        page.icon ?? '📝',
                        style: const TextStyle(fontSize: 20),
                      ),
                      controlAffinity: ListTileControlAffinity.trailing,
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
              error: (err, _) => Center(
                child: Text('Failed to load notes: $err'),
              ),
            ),
          ),

          // Action buttons footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isAttaching ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _selectedPageIds.isEmpty || _isAttaching
                      ? null
                      : _handleConfirm,
                  icon: _isAttaching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(
                    _isAttaching
                        ? 'Attaching...'
                        : 'Attach (${_selectedPageIds.length})',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirm() async {
    setState(() {
      _isAttaching = true;
    });

    try {
      await widget.onConfirm(_selectedPageIds.toList());
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to attach items: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAttaching = false;
        });
      }
    }
  }

  Future<void> _handleCreateNewNote() async {
    if (widget.onCreateNewNote == null) return;
    setState(() {
      _isAttaching = true;
    });

    try {
      final newPageId = await widget.onCreateNewNote!();
      if (newPageId != null) {
        _selectedPageIds.add(newPageId);
        await widget.onConfirm([newPageId]);
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create new note: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAttaching = false;
        });
      }
    }
  }

  IconData _getFileIcon(String? mimeType, String fileName) {
    if (mimeType != null) {
      if (mimeType.startsWith('image/')) return Icons.image_outlined;
      if (mimeType.startsWith('video/')) return Icons.movie_outlined;
      if (mimeType.startsWith('audio/')) return Icons.audiotrack_outlined;
      if (mimeType == 'application/pdf') return Icons.picture_as_pdf_outlined;
    }
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
      return Icons.image_outlined;
    }
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
      return Icons.movie_outlined;
    }
    if (['mp3', 'wav', 'm4a', 'flac'].contains(ext)) {
      return Icons.audiotrack_outlined;
    }
    if (ext == 'pdf') return Icons.picture_as_pdf_outlined;
    return Icons.insert_drive_file_outlined;
  }
}
