import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:ketion/features/reminders/domain/models/reminder_kind.dart';

class ReminderPickerSheet extends ConsumerStatefulWidget {
  final String pageId;

  const ReminderPickerSheet({super.key, required this.pageId});

  @override
  ConsumerState<ReminderPickerSheet> createState() =>
      _ReminderPickerSheetState();
}

class _ReminderPickerSheetState extends ConsumerState<ReminderPickerSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _titleController = TextEditingController(text: 'Ketion Reminder');
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Set Reminder',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Reminder Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(
              _selectedDate == null
                  ? 'Select Date'
                  : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: _isLoading
                ? null
                : () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
          ),
          ListTile(
            title: Text(
              _selectedTime == null
                  ? 'Select Time'
                  : _selectedTime!.format(context),
            ),
            trailing: const Icon(Icons.access_time),
            onTap: _isLoading
                ? null
                : () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _selectedTime = time;
                      });
                    }
                  },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed:
                (_selectedDate != null && _selectedTime != null && !_isLoading)
                    ? () async {
                        setState(() {
                          _isLoading = true;
                        });
                        try {
                          final dateTime = DateTime(
                            _selectedDate!.year,
                            _selectedDate!.month,
                            _selectedDate!.day,
                            _selectedTime!.hour,
                            _selectedTime!.minute,
                          );

                          final createReminder =
                              ref.read(createReminderUseCaseProvider);
                          await createReminder.execute(
                            pageId: widget.pageId,
                            title: _titleController.text.isNotEmpty ? _titleController.text : 'Ketion Reminder',
                            reminderTime: dateTime,
                            kind: ReminderKind.reminder,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      }
                    : null,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),)
                : const Text('Save Reminder'),
          ),
        ],
      ),
    );
  }
}
