import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ketion/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:ketion/features/reminders/domain/models/reminder_recurrence.dart';
import 'package:ketion/features/reminders/domain/models/reminder_kind.dart';

class AlarmPickerSheet extends ConsumerStatefulWidget {
  final String pageId;

  const AlarmPickerSheet({super.key, required this.pageId});

  @override
  ConsumerState<AlarmPickerSheet> createState() => _AlarmPickerSheetState();
}

class _AlarmPickerSheetState extends ConsumerState<AlarmPickerSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _titleController = TextEditingController(text: 'Ketion Alarm');
  ReminderRecurrence? _selectedRecurrence;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set Alarm',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Alarm Name',
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
            ListTile(
              title: const Text('Repeat'),
              trailing: DropdownButton<ReminderRecurrence?>(
                value: _selectedRecurrence,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Never')),
                  DropdownMenuItem(value: ReminderRecurrence.daily, child: Text('Daily')),
                  DropdownMenuItem(value: ReminderRecurrence.weekly, child: Text('Weekly')),
                  DropdownMenuItem(value: ReminderRecurrence.monthly, child: Text('Monthly')),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedRecurrence = value;
                        });
                      },
              ),
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
                            
                            if (Platform.isAndroid) {
                              final plugin = FlutterLocalNotificationsPlugin();
                              final androidPlugin = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
                              if (androidPlugin != null) {
                                try {
                                  final granted = await androidPlugin.requestFullScreenIntentPermission();
                                  if (granted == false) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Full-screen intent permission is required for alarms.')),
                                      );
                                    }
                                    return; // Abort saving the alarm
                                  }
                                } catch (_) {
                                  // Ignore for older Android versions
                                }
                              }
                            }
  
                            final createReminder =
                                ref.read(createReminderUseCaseProvider);
                            await createReminder.execute(
                              pageId: widget.pageId,
                              title: _titleController.text.isNotEmpty ? _titleController.text : 'Ketion Alarm',
                              reminderTime: dateTime,
                              recurrenceRule: serializeRecurrenceRule(_selectedRecurrence),
                              kind: ReminderKind.alarm,
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
                  : const Text('Save Alarm'),
            ),
          ],
        ),
      ),
    );
  }
}
