import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/features/reminders/domain/models/reminder_kind.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:ketion/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:ketion/features/reminders/domain/usecases/create_reminder_usecase.dart';
import 'package:ketion/features/reminders/domain/usecases/delete_reminder_usecase.dart';
import 'package:ketion/features/reminders/domain/usecases/get_reminders_usecase.dart';
import 'package:ketion/features/reminders/domain/usecases/update_reminder_usecase.dart';
import 'package:ketion/features/reminders/domain/usecases/resolve_reminder_usecase.dart';
import 'package:ketion/features/reminders/domain/usecases/snooze_reminder_usecase.dart';
import 'package:ketion/features/reminders/presentation/services/local_notification_scheduler.dart';
import 'package:ketion/features/reminders/presentation/services/reminder_scheduler.dart';
import 'package:ketion/features/reminders/domain/services/reminder_snooze_reconciler.dart';
import 'package:ketion/features/reminders/domain/entities/reminder.dart';
import 'package:ketion/features/sync/presentation/providers/sync_providers.dart';
import 'package:ketion/features/reminders/presentation/services/notification_action_dispatcher.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';
import 'package:ketion/features/reminders/domain/services/recurrence_calculator.dart';
import 'package:uuid/uuid.dart';

import 'package:ketion/core/bootstrap/notification_bootstrap.dart';

// Provides the FlutterLocalNotificationsPlugin instance
final flutterLocalNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
  return NotificationBootstrap.plugin;
});

// Provides the ReminderSnoozeReconciler
final reminderSnoozeReconcilerProvider = Provider<ReminderSnoozeReconciler>((ref) {
  return ReminderSnoozeReconciler(ref.read(reminderRepositoryProvider));
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
  final pageRepository = ref.read(pageRepositoryProvider);
  return CreateReminderUseCase(repository, scheduler, pageRepository, uuid: const Uuid());
});

// Provides the GetRemindersUseCase
final getRemindersUseCaseProvider = Provider<GetRemindersUseCase>((ref) {
  final repository = ref.read(reminderRepositoryProvider);
  return GetRemindersUseCase(repository);
});

// Provides a Future for a specific reminder
final reminderFutureProvider = FutureProvider.family<ReminderEntity?, String>((ref, id) {
  final usecase = ref.watch(getRemindersUseCaseProvider);
  return usecase.getReminder(id);
});

// Provides the RecurrenceCalculator
final recurrenceCalculatorProvider = Provider<RecurrenceCalculator>((ref) {
  return RecurrenceCalculator();
});

// Provides the UpdateReminderUseCase
final updateReminderUseCaseProvider = Provider<UpdateReminderUseCase>((ref) {
  final repository = ref.read(reminderRepositoryProvider);
  final scheduler = ref.read(reminderSchedulerProvider);
  final pageRepository = ref.read(pageRepositoryProvider);
  final calculator = ref.read(recurrenceCalculatorProvider);
  return UpdateReminderUseCase(repository, scheduler, pageRepository, calculator);
});

// Provides the DeleteReminderUseCase
final deleteReminderUseCaseProvider = Provider<DeleteReminderUseCase>((ref) {
  final repository = ref.read(reminderRepositoryProvider);
  final scheduler = ref.read(reminderSchedulerProvider);
  return DeleteReminderUseCase(repository, scheduler);
});

// Provides the ResolveReminderUseCase
final resolveReminderUseCaseProvider = Provider<ResolveReminderUseCase>((ref) {
  final repository = ref.read(reminderRepositoryProvider);
  final scheduler = ref.read(reminderSchedulerProvider);
  final calculator = ref.read(recurrenceCalculatorProvider);
  final updateUseCase = ref.read(updateReminderUseCaseProvider);
  final deleteUseCase = ref.read(deleteReminderUseCaseProvider);
  return ResolveReminderUseCase(
    repository: repository,
    scheduler: scheduler,
    recurrenceCalculator: calculator,
    updateUseCase: updateUseCase,
    deleteUseCase: deleteUseCase,
  );
});

// Provides the SnoozeReminderUseCase
final snoozeReminderUseCaseProvider = Provider<SnoozeReminderUseCase>((ref) {
  final repository = ref.read(reminderRepositoryProvider);
  final scheduler = ref.read(reminderSchedulerProvider);
  return SnoozeReminderUseCase(
    repository: repository,
    scheduler: scheduler,
  );
});

final allActiveRemindersProvider = StreamProvider<List<ReminderEntity>>((ref) {
  final usecase = ref.watch(getRemindersUseCaseProvider);
  final reconciler = ref.watch(reminderSnoozeReconcilerProvider);
  return usecase.watchAllActive().asyncMap((reminders) async {
    return await reconciler.reconcileExpiredSnoozes(reminders);
  });
});

final activeRemindersByKindProvider = Provider.family<AsyncValue<List<ReminderEntity>>, ReminderKind>((ref, kind) {
  final allRemindersAsync = ref.watch(allActiveRemindersProvider);
  return allRemindersAsync.whenData((reminders) => reminders.where((r) => r.kind == kind).toList());
});

final todayRemindersProvider = StreamProvider<List<ReminderEntity>>((ref) {
  final usecase = ref.watch(getRemindersUseCaseProvider);
  final reconciler = ref.watch(reminderSnoozeReconcilerProvider);
  return usecase.watchAllActive().asyncMap((reminders) async {
    final reconciled = await reconciler.reconcileExpiredSnoozes(reminders);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return reconciled.where((r) {
      final rTime = r.reminderTime.toLocal();
      final rDay = DateTime(rTime.year, rTime.month, rTime.day);
      return rDay.isAtSameMomentAs(today) && !r.completed;
    }).toList();
  });
});

// Provides the NotificationActionDispatcher
final notificationActionDispatcherProvider =
    Provider<NotificationActionDispatcher>((ref) {
  final dispatcher = NotificationActionDispatcher();
  dispatcher.connect(
    resolveUseCase: ref.read(resolveReminderUseCaseProvider),
    repository: ref.read(reminderRepositoryProvider),
    scheduler: ref.read(reminderSchedulerProvider),
  );
  NotificationActionDispatcher.instance = dispatcher;
  return dispatcher;
});
