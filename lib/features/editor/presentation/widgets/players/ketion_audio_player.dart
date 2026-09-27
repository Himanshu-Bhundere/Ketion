import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../media/presentation/providers/attachment_provider.dart';

class KetionAudioPlayerComponent extends ConsumerStatefulWidget {
  final String attachmentId;

  const KetionAudioPlayerComponent({
    super.key,
    required this.attachmentId,
  });

  @override
  ConsumerState<KetionAudioPlayerComponent> createState() => _KetionAudioPlayerComponentState();
}

class _KetionAudioPlayerComponentState extends ConsumerState<KetionAudioPlayerComponent> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isInitialised = false;

  Future<void> _initPlayer(String filePath) async {
    if (_player != null) return;

    final player = AudioPlayer();
    try {
      final duration = await player.setFilePath(filePath);
      if (mounted) {
        setState(() {
          _player = player;
          _duration = duration ?? Duration.zero;
          _isInitialised = true;
        });

        player.positionStream.listen((pos) {
          if (mounted) {
            setState(() => _position = pos);
          }
        });

        player.playerStateStream.listen((state) {
          if (mounted) {
            setState(() {
              _isPlaying = state.playing;
              if (state.processingState == ProcessingState.completed) {
                _isPlaying = false;
                _position = Duration.zero;
                player.seek(Duration.zero);
                player.pause();
              }
            });
          }
        });
      }
    } catch (e) {
      // Failed to initialise — leave uninitialised
    }
  }

  void _togglePlayback() {
    if (_player == null) return;
    if (_isPlaying) {
      _player!.pause();
    } else {
      _player!.play();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachmentId.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(child: Text('Invalid audio block')),
      );
    }

    final attachmentAsync = ref.watch(attachmentProvider(widget.attachmentId));

    return attachmentAsync.when(
      data: (attachment) {
        if (attachment == null) {
          return const SizedBox(
            height: 60,
            child: Center(child: Text('Audio not found in database')),
          );
        }

        final pathAsync = ref.watch(attachmentPathProvider(attachment));

        return pathAsync.when(
          data: (localPath) {
            if (localPath == null) {
              return const SizedBox(
                height: 60,
                child: Center(child: Text('Audio file not available locally')),
              );
            }

            if (!_isInitialised) {
              _initPlayer(localPath);
            }

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle : Icons.play_circle,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: _isInitialised ? _togglePlayback : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 2.0,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6.0,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12.0,
                              ),
                              activeTrackColor: Theme.of(context).colorScheme.primary,
                              inactiveTrackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            child: Slider(
                              value: _duration.inMilliseconds > 0
                                  ? _position.inMilliseconds / _duration.inMilliseconds
                                  : 0.0,
                              onChanged: _isInitialised
                                  ? (value) {
                                      final newPos = Duration(
                                        milliseconds: (value * _duration.inMilliseconds).round(),
                                      );
                                      _player?.seek(newPos);
                                    }
                                  : null,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_position),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                _formatDuration(_duration),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => SizedBox(
            height: 60,
            child: Center(child: Text('Error loading audio path: $e')),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => SizedBox(
        height: 60,
        child: Center(child: Text('Error loading audio metadata: $e')),
      ),
    );
  }
}
