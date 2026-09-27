import 'package:ketion/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:ketion/features/reminders/domain/usecases/resolve_reminder_usecase.dart';
import 'package:ketion/features/reminders/presentation/services/reminder_scheduler.dart';

/// Bridges notification action callbacks (which fire before Riverpod is
/// available) with the application's use-case layer.
///
/// Early actions received before [connect] is called are queued and
/// replayed once the dispatcher is connected.
class NotificationActionDispatcher {
  static NotificationActionDispatcher? instance;

  ResolveReminderUseCase? _resolveUseCase;
  ReminderRepository? _repository;
  ReminderScheduler? _scheduler;

  /// Queued actions received before [connect] was called.
  final List<_PendingAction> _pendingActions = [];

  /// Whether the dispatcher has been connected to the use-case layer.
  bool get isConnected => _resolveUseCase != null;

  /// Connect the dispatcher to the Riverpod-provided dependencies.
  /// Replays any actions that were queued before connection.
  void connect({
    required ResolveReminderUseCase resolveUseCase,
    required ReminderRepository repository,
    required ReminderScheduler scheduler,
  }) {
    _resolveUseCase = resolveUseCase;
    _repository = repository;
    _scheduler = scheduler;

    // Replay any actions that arrived before Riverpod was initialized.
    if (_pendingActions.isNotEmpty) {
      final pending = List<_PendingAction>.from(_pendingActions);
      _pendingActions.clear();
      for (final action in pending) {
        handleAction(actionId: action.actionId, payload: action.payload);
      }
    }
  }

  /// Called from [NotificationBootstrap]'s static callback.
  ///
  /// If the dispatcher is not yet connected to the use-case layer,
  /// the action is queued for replay after [connect] is called.
  Future<void> handleAction({
    String? actionId,
    String? payload,
    DateTime? occurrenceTime,
  }) async {
    if (payload == null || payload.isEmpty) return;

    if (!isConnected) {
      _pendingActions.add(_PendingAction(
        actionId: actionId,
        payload: payload,
        occurrenceTime: occurrenceTime,
      ),);
      return;
    }

    final reminderId = payload;

    if (actionId == 'complete') {
      await _resolveUseCase!.execute(
        reminderId: reminderId,
        action: ReminderResolutionAction.complete,
        occurrenceTime: occurrenceTime,
      );
    } else if (actionId == 'dismiss') {
      await _resolveUseCase!.execute(
        reminderId: reminderId,
        action: ReminderResolutionAction.dismiss,
        occurrenceTime: occurrenceTime,
      );
    } else if (actionId == 'snooze') {
      await _snoozeReminder(reminderId, occurrenceTime);
    }
  }

  /// Snooze the reminder by 10 minutes (documented default).
  ///
  /// Updates the `snoozeUntil` field on the entity (no schema change needed)
  /// and schedules a new notification at the snooze time.
  Future<void> _snoozeReminder(String reminderId, DateTime? occurrenceTime) async {
    final reminder = await _repository!.getReminder(reminderId);
    if (reminder == null) return;
    
    if (occurrenceTime != null && reminder.reminderTime != occurrenceTime) {
      // Stale event, ignore
      return;
    }

    final snoozeUntil = DateTime.now().add(const Duration(minutes: 10));
    final snoozed = reminder.copyWith(
      snoozeUntil: snoozeUntil,
      updatedAt: DateTime.now().toUtc(),
    );

    // Persist the snooze metadata
    await _repository!.updateReminder(snoozed);

    // Schedule a new notification at the snooze time.
    // We pass the snooze time as reminderTime for scheduling purposes
    // but the original reminderTime on the entity is preserved.
    await _scheduler!.scheduleReminder(
      snoozed.copyWith(reminderTime: snoozeUntil),
    );
  }
}

class _PendingAction {
  final String? actionId;
  final String? payload;
  final DateTime? occurrenceTime;

  _PendingAction({
    required this.actionId,
    required this.payload,
    this.occurrenceTime,
  });
}
