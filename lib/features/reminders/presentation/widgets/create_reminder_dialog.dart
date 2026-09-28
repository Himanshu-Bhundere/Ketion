import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';

class CreateReminderDialog extends ConsumerStatefulWidget {
  const CreateReminderDialog({super.key});

  @override
  ConsumerState<CreateReminderDialog> createState() => _CreateReminderDialogState();
}

class _CreateReminderDialogState extends ConsumerState<CreateReminderDialog> {
  final _titleController = TextEditingController();
  DateTime? _selectedTime;
  String? _selectedPageId;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _pickTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedTime == null || _selectedPageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title, select a page, and choose a time')),
      );
      return;
    }

    final createUseCase = ref.read(createReminderUseCaseProvider);
    await createUseCase.execute(
      pageId: _selectedPageId!,
      title: title,
      reminderTime: _selectedTime!,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(recentPagesProvider);

    return AlertDialog(
      title: const Text('New Reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 16),
          pagesAsync.when(
            data: (pages) {
              if (pages.isEmpty) {
                return const Text('Create a note first to attach reminders.');
              }
              // Initialize if null and we have pages
              if (_selectedPageId == null && pages.isNotEmpty) {
                _selectedPageId = pages.first.id;
              }
              return DropdownButtonFormField<String>(
                initialValue: _selectedPageId,
                items: pages.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text(p.title.isEmpty ? 'Untitled' : p.title),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedPageId = val;
                  });
                },
                decoration: const InputDecoration(labelText: 'Attach to Note'),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Error loading pages'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                _selectedTime != null
                    ? 'Time: ${_selectedTime!.toLocal().toString().substring(0, 16)}'
                    : 'No time selected',
              ),
              const Spacer(),
              TextButton(
                onPressed: _pickTime,
                child: const Text('Pick Time'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
