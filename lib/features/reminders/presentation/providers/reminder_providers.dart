import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:ketion/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:ketion/features/reminders/domain/usecases/create_reminder_usecase.dart';
import 'package:ketion/features/reminders/domain/usecases/delete_reminder_usecase.dart';
import 'package:ketion/features/reminders/domain/usecases/get_reminders_usecase.dart';
import 'package:ketion/features/reminders/domain/usecases/update_reminder_usecase.dart';
import 'package:ketion/features/reminders/presentation/services/local_notification_scheduler.dart';
import 'package:ketion/features/reminders/presentation/services/reminder_scheduler.dart';
import 'package:ketion/features/reminders/domain/entities/reminder.dart';
import 'package:ketion/features/sync/presentation/providers/sync_providers.dart';
import 'package:uuid/uuid.dart';

// Provides the FlutterLocalNotificationsPlugin instance
final flutterLocalNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
  return FlutterLocalNotificationsPlugin();
});

// Provides the ReminderScheduler
final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  return LocalNotificationScheduler(
    ref.read(flutterLocalNotificationsPluginProvider),
  );
});

// Provides the ReminderRepository
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncQueue = ref.watch(syncQueueRepositoryProvider);
  return ReminderRepositoryImpl(db, syncQueue);
});

// Provides the CreateReminderUseCase
final createReminderUseCaseProvider = Provider<CreateReminderUseCase>((ref) {
  final repository = ref.read(reminderRepositoryProvider);
  final scheduler = ref.read(reminderSchedulerProvider);
  return CreateReminderUseCase(repository, scheduler, uuid: const Uuid());
});

// Provides the GetRemindersUseCase
final getRemindersUseCaseProvider = Provider<GetRemindersUseCase>((ref) {
  final repository = ref.read(reminderRepositoryProvider);
  return GetRemindersUseCase(repository);
});

// Provides the UpdateReminderUseCase
final updateReminderUseCaseProvider = Provider<UpdateReminderUseCase>((ref) {
  final repository = ref.read(reminderRepositoryProvider);
  final scheduler = ref.read(reminderSchedulerProvider);
  return UpdateReminderUseCase(repository, scheduler);
});

// Provides the DeleteReminderUseCase
final deleteReminderUseCaseProvider = Provider<DeleteReminderUseCase>((ref) {
  final repository = ref.read(reminderRepositoryProvider);
  final scheduler = ref.read(reminderSchedulerProvider);
  return DeleteReminderUseCase(repository, scheduler);
});

final allActiveRemindersProvider = StreamProvider<List<ReminderEntity>>((ref) {
  final usecase = ref.watch(getRemindersUseCaseProvider);
  return usecase.watchAllActive();
});

final todayRemindersProvider = StreamProvider<List<ReminderEntity>>((ref) {
  final usecase = ref.watch(getRemindersUseCaseProvider);
  return usecase.watchAllActive().map((reminders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return reminders.where((r) {
      final rTime = r.reminderTime.toLocal();
      final rDay = DateTime(rTime.year, rTime.month, rTime.day);
      return rDay.isAtSameMomentAs(today) && !r.completed;
    }).toList();
  });
});
