import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/features/reminders/presentation/providers/reminder_providers.dart';

class CreateReminderDialog extends ConsumerStatefulWidget {
  final String pageId;
  const CreateReminderDialog({super.key, required this.pageId});

  @override
  ConsumerState<CreateReminderDialog> createState() => _CreateReminderDialogState();
}

class _CreateReminderDialogState extends ConsumerState<CreateReminderDialog> {
  final _titleController = TextEditingController();
  DateTime? _selectedTime;

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
    if (title.isEmpty || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and select a time')),
      );
      return;
    }

    final createUseCase = ref.read(createReminderUseCaseProvider);
    await createUseCase.execute(
      pageId: widget.pageId,
      title: title,
      reminderTime: _selectedTime!,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
