import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:ketion/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:ketion/features/reminders/domain/usecases/resolve_reminder_usecase.dart';
import 'package:go_router/go_router.dart';

class AlarmRingingPage extends ConsumerStatefulWidget {
  final String reminderId;
  final DateTime? occurrenceTime;

  const AlarmRingingPage({
    super.key,
    required this.reminderId,
    this.occurrenceTime,
  });

  @override
  ConsumerState<AlarmRingingPage> createState() => _AlarmRingingPageState();
}

class _AlarmRingingPageState extends ConsumerState<AlarmRingingPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  @override
  void initState() {
    super.initState();
    _startAlarm();
  }

  Future<void> _startAlarm() async {
    try {
      await _audioPlayer.setAsset('assets/audio/alarm.mp3');
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing alarm audio: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleAction(ReminderResolutionAction action) async {
    await ref.read(resolveReminderUseCaseProvider).execute(
      reminderId: widget.reminderId,
      action: action,
      occurrenceTime: widget.occurrenceTime,
    );
    
    await _audioPlayer.stop();
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext buildContext) {
    // We try to watch the reminder to show details if we want
    final reminderAsyncValue = ref.watch(reminderFutureProvider(widget.reminderId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Icon(
              Icons.alarm,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            reminderAsyncValue.when(
              data: (reminder) {
                if (reminder == null) {
                  return const Text(
                    'Unknown Alarm',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  );
                }
                return Column(
                  children: [
                    Text(
                      reminder.title,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  ],
                );
              },
              loading: () => const CircularProgressIndicator(color: Colors.white),
              error: (_, __) => const Text(
                'Error loading alarm',
                style: TextStyle(color: Colors.red),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      iconSize: 64,
                      icon: const Icon(Icons.snooze),
                      color: Colors.orange,
                      onPressed: () async {
                        await ref.read(snoozeReminderUseCaseProvider).execute(
                          reminderId: widget.reminderId,
                          occurrenceTime: widget.occurrenceTime,
                        );
                        await _audioPlayer.stop();
                        if (mounted) {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        }
                      },
                    ),
                    const Text('Snooze', style: TextStyle(color: Colors.white)),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      iconSize: 64,
                      icon: const Icon(Icons.stop_circle),
                      color: Colors.red,
                      onPressed: () => _handleAction(ReminderResolutionAction.complete),
                    ),
                    const Text('Stop', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
