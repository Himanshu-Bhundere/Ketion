import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../../media/presentation/providers/attachment_provider.dart';

class KetionVideoPlayerComponent extends ConsumerStatefulWidget {
  final String attachmentId;

  const KetionVideoPlayerComponent({
    super.key,
    required this.attachmentId,
  });

  @override
  ConsumerState<KetionVideoPlayerComponent> createState() => _KetionVideoPlayerComponentState();
}

class _KetionVideoPlayerComponentState extends ConsumerState<KetionVideoPlayerComponent> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialised = false;

  Future<void> _initController(String filePath) async {
    if (_controller != null) return;

    final controller = kIsWeb
        ? VideoPlayerController.networkUrl(Uri.parse(filePath))
        : VideoPlayerController.file(io.File(filePath));
    await controller.initialize();
    if (mounted) {
      setState(() {
        _controller = controller;
        _isInitialised = true;
      });
    }
  }

  void _togglePlayback() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      setState(() => _isPlaying = false);
    } else {
      _controller!.play();
      setState(() => _isPlaying = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachmentId.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('Invalid video block')),
      );
    }

    final attachmentAsync = ref.watch(attachmentProvider(widget.attachmentId));

    return attachmentAsync.when(
      data: (attachment) {
        if (attachment == null) {
          return const SizedBox(
            height: 100,
            child: Center(child: Text('Video not found in database')),
          );
        }

        final pathAsync = ref.watch(attachmentPathProvider(attachment));

        return pathAsync.when(
          data: (localPath) {
            if (localPath == null) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('Video file not available locally')),
              );
            }

            if (!_isInitialised) {
              _initController(localPath);
            }

            if (_controller == null || !_controller!.value.isInitialized) {
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_controller!),
                        AnimatedOpacity(
                          opacity: _isPlaying ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          child: GestureDetector(
                            onTap: _togglePlayback,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(16.0),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _togglePlayback,
                            behavior: HitTestBehavior.translucent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                VideoProgressIndicator(
                  _controller!,
                  allowScrubbing: true,
                  padding: const EdgeInsets.only(top: 4.0),
                ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => SizedBox(
            height: 100,
            child: Center(child: Text('Error loading video path: $e')),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => SizedBox(
        height: 100,
        child: Center(child: Text('Error loading video metadata: $e')),
      ),
    );
  }
}
