import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:ketion/features/reminders/presentation/widgets/create_reminder_dialog.dart';

class RemindersPage extends ConsumerWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(allActiveRemindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
      ),
      body: remindersAsync.when(
        data: (reminders) {
          if (reminders.isEmpty) {
            return const Center(
              child: Text('No reminders yet.'),
            );
          }
          return ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return ListTile(
                leading: Checkbox(
                  value: reminder.completed,
                  onChanged: (val) async {
                    if (val != null) {
                      final updateUseCase = ref.read(updateReminderUseCaseProvider);
                      await updateUseCase.execute(reminder.copyWith(completed: val));
                    }
                  },
                ),
                title: Text(reminder.title),
                subtitle: Text('Due: ${reminder.reminderTime.toLocal()}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final deleteUseCase = ref.read(deleteReminderUseCaseProvider);
                    await deleteUseCase.execute(reminder.id);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (context) => const CreateReminderDialog(pageId: 'global'),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
