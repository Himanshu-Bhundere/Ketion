import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:ketion/core/bootstrap/app_bootstrap.dart';
import 'package:ketion/core/theme/app_theme.dart';
import 'package:ketion/core/theme/app_colors.dart';
import 'package:ketion/core/router/app_router.dart';
import 'package:ketion/core/router/routes.dart';
import 'package:ketion/features/settings/presentation/providers/settings_providers.dart';
import 'package:ketion/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:ketion/core/bootstrap/notification_bootstrap.dart';
import 'package:ketion/features/assistive_ball/presentation/widgets/root_assistive_ball_overlay.dart';
import 'package:ketion/features/incoming_share/domain/models/incoming_share_item.dart';
import 'package:ketion/features/incoming_share/presentation/providers/incoming_share_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppBootstrap.initialize();
  } catch (error, stackTrace) {
    debugPrint('Ketion startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(
    const ProviderScope(
      child: KetionApp(),
    ),
  );
}

class KetionApp extends ConsumerStatefulWidget {
  const KetionApp({super.key});

  @override
  ConsumerState<KetionApp> createState() => _KetionAppState();
}

class _KetionAppState extends ConsumerState<KetionApp>
    with WidgetsBindingObserver {
  Timer? _reminderCleanupTimer;
  bool _isReminderCleanupRunning = false;
  StreamSubscription<List<IncomingShareItem>>? _shareSubscription;

  Future<void> _restoreReminderSchedules() async {
    if (kIsWeb) return;

    try {
      final reminders = await ref
          .read(reminderRepositoryProvider)
          .watchAllActiveReminders()
          .first;

      final scheduler = ref.read(reminderSchedulerProvider);

      for (final reminder in reminders) {
        if (reminder.completed || reminder.deleted) {
          continue;
        }

        final effectiveTime =
            reminder.snoozeUntil != null &&
                    reminder.snoozeUntil!.isAfter(DateTime.now())
                ? reminder.snoozeUntil!
                : reminder.reminderTime;

        if (!effectiveTime.isAfter(DateTime.now())) {
          continue;
        }

        final reminderToSchedule = reminder.copyWith(
          reminderTime: effectiveTime,
        );

        try {
          await scheduler.scheduleReminder(reminderToSchedule);
        } catch (error, stackTrace) {
          debugPrint(
            'Failed to restore reminder ${reminder.id}: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Reminder schedule restoration failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _cleanupExpiredReminders() async {
    if (_isReminderCleanupRunning) return;

    _isReminderCleanupRunning = true;

    try {
      await ref
          .read(reminderExpiryServiceProvider)
          .cleanupExpiredReminders();
    } catch (error, stackTrace) {
      debugPrint('Reminder expiry cleanup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isReminderCleanupRunning = false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _reminderCleanupTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _cleanupExpiredReminders(),
    );

    // Eagerly connect notification action dispatcher to Riverpod
    Future.microtask(() async {
      ref.read(notificationActionDispatcherProvider);

      await _restoreReminderSchedules();

      await _cleanupExpiredReminders();

      // Handle pending cold-start navigation
      final pending = NotificationBootstrap.pendingNavigation;
      if (pending != null && pending.type == 'alarm') {
        NotificationBootstrap.pendingNavigation = null;
        await appRouter.pushNamed(
          Routes.alarmRingingName,
          pathParameters: {'reminderId': pending.reminderId},
          extra: {'occurrenceTime': pending.occurrenceTime},
        );
      }
    });

    // Listen for incoming share intents (Android/iOS)
    final shareService = ref.read(incomingShareServiceProvider);
    _shareSubscription = shareService.onShareReceived.listen((items) {
      void dispatch(BuildContext ctx) {
        unawaited(
          ref
              .read(incomingShareCoordinatorProvider)
              .handleIncomingItems(ctx, items),
        );
      }

      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        dispatch(context);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = rootNavigatorKey.currentContext;
          if (ctx != null && ctx.mounted) {
            dispatch(ctx);
          }
        });
      }
    });

    // Check for pending cold-start shares
    Future.delayed(const Duration(milliseconds: 600), () async {
      final pendingShares = await shareService.getPendingShares();
      if (pendingShares.isNotEmpty) {
        final currentCtx = rootNavigatorKey.currentContext;
        if (currentCtx != null && currentCtx.mounted) {
          await shareService.clearPendingShares();
          if (currentCtx.mounted) {
            await ref
                .read(incomingShareCoordinatorProvider)
                .handleIncomingItems(currentCtx, pendingShares);
          }
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final delayedCtx = rootNavigatorKey.currentContext;
            if (delayedCtx != null && delayedCtx.mounted) {
              await shareService.clearPendingShares();
              if (delayedCtx.mounted) {
                await ref
                    .read(incomingShareCoordinatorProvider)
                    .handleIncomingItems(delayedCtx, pendingShares);
              }
            }
          });
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cleanupExpiredReminders();

      final shareService = ref.read(incomingShareServiceProvider);
      shareService.getPendingShares().then((pendingShares) async {
        if (pendingShares.isNotEmpty) {
          final context = rootNavigatorKey.currentContext;
          if (context != null && context.mounted) {
            await shareService.clearPendingShares();
            if (context.mounted) {
              await ref
                  .read(incomingShareCoordinatorProvider)
                  .handleIncomingItems(context, pendingShares);
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    _reminderCleanupTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        ThemeMode themeMode = ThemeMode.system;
        if (settings.themeMode == 'Light') {
          themeMode = ThemeMode.light;
        } else if (settings.themeMode == 'Dark') {
          themeMode = ThemeMode.dark;
        }

        return MaterialApp.router(
          title: 'Ketion',
          theme: AppTheme.getLightTheme(
            primaryColor: AppColors.getAccentColor(settings.accentColor.name),
            fontSizePreference: settings.fontSize,
            highContrast: settings.highContrast,
            reducedMotion: settings.reducedMotion,
          ),
          darkTheme: AppTheme.getDarkTheme(
            primaryColor: AppColors.getAccentColor(settings.accentColor.name),
            fontSizePreference: settings.fontSize,
            highContrast: settings.highContrast,
            reducedMotion: settings.reducedMotion,
          ),
          themeMode: themeMode,
          routerConfig: appRouter,
          builder: (context, child) {
            final isDragging = ref.watch(isDraggingFilesProvider);

            return DropTarget(
              onDragEntered: (_) {
                ref.read(isDraggingFilesProvider.notifier).state = true;
              },
              onDragExited: (_) {
                ref.read(isDraggingFilesProvider.notifier).state = false;
              },
              onDragDone: (detail) async {
                ref.read(isDraggingFilesProvider.notifier).state = false;
                if (detail.files.isEmpty) return;

                final items = <IncomingShareItem>[];
                for (final file in detail.files) {
                  final length = await file.length();
                  String? mimeType = file.mimeType;
                  if (mimeType == null || mimeType.isEmpty) {
                    final ext = file.name.split('.').last.toLowerCase();
                    if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'svg', 'heic'].contains(ext)) {
                      mimeType = ext == 'jpg' ? 'image/jpeg' : (ext == 'svg' ? 'image/svg+xml' : 'image/$ext');
                    } else if (['mp4', 'mov', 'avi', 'mkv', 'm4v', 'webm'].contains(ext)) {
                      mimeType = ext == 'mov' ? 'video/quicktime' : 'video/$ext';
                    } else if (['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'].contains(ext)) {
                      mimeType = ext == 'mp3' ? 'audio/mpeg' : (ext == 'm4a' ? 'audio/mp4' : 'audio/$ext');
                    } else if (ext == 'pdf') {
                      mimeType = 'application/pdf';
                    } else if (ext == 'md' || ext == 'markdown') {
                      mimeType = 'text/markdown';
                    } else if (ext == 'txt' || ext == 'log') {
                      mimeType = 'text/plain';
                    } else if (ext == 'json') {
                      mimeType = 'application/json';
                    } else {
                      mimeType = 'application/octet-stream';
                    }
                  }
                  items.add(
                    IncomingShareItem(
                      type: IncomingShareType.file,
                      name: file.name,
                      localPath: file.path,
                      mimeType: mimeType,
                      size: length,
                    ),
                  );
                }

                final targetContext =
                    rootNavigatorKey.currentContext ?? context;
                if (targetContext.mounted && items.isNotEmpty) {
                  await ref
                      .read(incomingShareCoordinatorProvider)
                      .handleIncomingItems(targetContext, items);
                }
              },
              child: Stack(
                children: [
                  RootAssistiveBallOverlay(
                    child: child ?? const SizedBox.shrink(),
                  ),
                  if (isDragging)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15),
                          child: Center(
                            child: Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.file_download_outlined,
                                      size: 48,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Drop files to attach to Ketion',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          Center(child: Text('Failed to load settings: $err')),
    );
  }
}
