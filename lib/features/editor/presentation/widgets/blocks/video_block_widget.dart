import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../../blocks/domain/entities/block.dart';
import '../../../../media/presentation/providers/attachment_provider.dart';
import '../../../domain/models/block_data_models.dart';

class VideoBlockWidget extends ConsumerStatefulWidget {
  final Block block;
  final ValueChanged<Block> onUpdate;

  const VideoBlockWidget({
    super.key,
    required this.block,
    required this.onUpdate,
  });

  @override
  ConsumerState<VideoBlockWidget> createState() => _VideoBlockWidgetState();
}

class _VideoBlockWidgetState extends ConsumerState<VideoBlockWidget> {
  late VideoBlockData _blockData;
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialised = false;

  @override
  void initState() {
    super.initState();
    _parseData();
  }

  void _parseData() {
    try {
      final Map<String, dynamic> json =
          jsonDecode(widget.block.data) as Map<String, dynamic>;
      json['runtimeType'] = 'video';
      _blockData = BlockDataModel.fromJson(json) as VideoBlockData;
    } catch (e) {
      _blockData =
          const BlockDataModel.video(attachmentId: '') as VideoBlockData;
    }
  }

  @override
  void didUpdateWidget(covariant VideoBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.data != widget.block.data) {
      _parseData();
    }
  }

  Future<void> _initController(String filePath) async {
    if (_controller != null) return;

    final controller = VideoPlayerController.file(File(filePath));
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
    if (_blockData.attachmentId.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('Invalid video block')),
      );
    }

    final attachmentAsync =
        ref.watch(attachmentProvider(_blockData.attachmentId));

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

            // Initialise controller lazily
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
                // Seek bar
                VideoProgressIndicator(
                  _controller!,
                  allowScrubbing: true,
                  padding: const EdgeInsets.only(top: 4.0),
                ),
                if (_blockData.caption != null &&
                    _blockData.caption!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _blockData.caption!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                      textAlign: TextAlign.center,
                    ),
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
