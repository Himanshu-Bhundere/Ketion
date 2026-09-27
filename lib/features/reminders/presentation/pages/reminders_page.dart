import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:ketion/features/reminders/presentation/widgets/create_reminder_dialog.dart';
import 'package:ketion/features/reminders/presentation/utils/reminder_display_formatter.dart';
import 'package:ketion/features/reminders/domain/models/reminder_kind.dart';
import 'package:ketion/features/reminders/domain/usecases/resolve_reminder_usecase.dart';

enum ReminderFilter { all, reminders, alarms }

class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});

  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage> {
  ReminderFilter _filter = ReminderFilter.all;

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(allActiveRemindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders & Alarms'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filter == ReminderFilter.all,
                  onSelected: (selected) {
                    if (selected) setState(() => _filter = ReminderFilter.all);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Reminders'),
                  selected: _filter == ReminderFilter.reminders,
                  onSelected: (selected) {
                    if (selected) setState(() => _filter = ReminderFilter.reminders);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Alarms'),
                  selected: _filter == ReminderFilter.alarms,
                  onSelected: (selected) {
                    if (selected) setState(() => _filter = ReminderFilter.alarms);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: remindersAsync.when(
              data: (reminders) {
                final filtered = reminders.where((r) {
                  if (_filter == ReminderFilter.all) return true;
                  if (_filter == ReminderFilter.reminders) return r.kind == ReminderKind.reminder;
                  if (_filter == ReminderFilter.alarms) return r.kind == ReminderKind.alarm;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No items found.'),
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final reminder = filtered[index];
                    final isAlarm = reminder.kind == ReminderKind.alarm;
                    return ListTile(
                      leading: Icon(isAlarm ? Icons.alarm : Icons.notifications_active),
                      title: Text(reminder.title),
                      subtitle: Text(ReminderDisplayFormatter.formatDueLabel(context, reminder.reminderTime)),
                      trailing: isAlarm
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Delete alarm',
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Alarm'),
                                    content: const Text('Are you sure you want to delete this alarm?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  final deleteUseCase = ref.read(deleteReminderUseCaseProvider);
                                  await deleteUseCase.execute(reminder.id);
                                }
                              },
                            )
                          : IconButton(
                              icon: const Icon(Icons.check_circle_outline),
                              tooltip: 'Complete',
                              onPressed: () async {
                                final resolveUseCase = ref.read(resolveReminderUseCaseProvider);
                                await resolveUseCase.execute(
                                  reminderId: reminder.id,
                                  action: ReminderResolutionAction.complete,
                                  occurrenceTime: reminder.reminderTime,
                                );
                              },
                            ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (context) => const CreateReminderDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
