import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class KetionInFramePlayer extends StatefulWidget {
  final String filePath;
  final String? caption;
  final VideoPlayerController? controller;
  final bool isFullscreen;

  const KetionInFramePlayer({
    super.key,
    required this.filePath,
    this.caption,
    this.controller,
    this.isFullscreen = false,
  });

  @override
  State<KetionInFramePlayer> createState() => _KetionInFramePlayerState();
}

class _KetionInFramePlayerState extends State<KetionInFramePlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  Timer? _controlsTimer;
  double _playbackSpeed = 1.0;
  String? _errorMessage;
  int _initToken = 0;
  bool _isInFullScreen = false;

  static const List<double> _availableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _initController(widget.filePath);
  }

  @override
  void didUpdateWidget(covariant KetionInFramePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _initController(widget.filePath);
    }
  }

  Future<void> _initController(String filePath) async {
    final token = ++_initToken;

    _controlsTimer?.cancel();
    final oldController = _controller;
    _controller = null;
    if (mounted) {
      setState(() {
        _isInitialized = false;
        _errorMessage = null;
        _isPlaying = false;
        _showControls = true;
      });
    }

    if (oldController != null) {
      oldController.removeListener(_onControllerUpdate);
      if (widget.controller == null) {
        await oldController.dispose();
      }
    }

    try {
      final controller = widget.controller ??
          (kIsWeb
              ? VideoPlayerController.networkUrl(Uri.parse(filePath))
              : VideoPlayerController.file(io.File(filePath)));

      if (!controller.value.isInitialized) {
        await controller.initialize();
      }

      if (!mounted || token != _initToken) {
        if (widget.controller == null) {
          await controller.dispose();
        }
        return;
      }

      if (_playbackSpeed != 1.0) {
        await controller.setPlaybackSpeed(_playbackSpeed);
      }
      controller.addListener(_onControllerUpdate);

      setState(() {
        _controller = controller;
        _isInitialized = true;
        _isPlaying = controller.value.isPlaying;
      });
    } catch (e, stackTrace) {
      debugPrint(
        'Video initialization failed on ${defaultTargetPlatform.name}: $e',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (mounted && token == _initToken) {
        setState(() {
          _errorMessage = 'Failed to load video: $e';
          _isInitialized = false;
        });
      }
    }
  }

  void _onControllerUpdate() {
    if (!mounted || _controller == null) return;
    final isPlaying = _controller!.value.isPlaying;
    if (isPlaying != _isPlaying) {
      setState(() {
        _isPlaying = isPlaying;
      });
      if (_isPlaying) {
        _startControlsTimeout();
      } else {
        _controlsTimer?.cancel();
        setState(() {
          _showControls = true;
        });
      }
    } else {
      setState(() {});
    }
  }

  void _startControlsTimeout() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls && _isPlaying) {
      _startControlsTimeout();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void _togglePlayback() {
    if (_controller == null || !_isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
      _startControlsTimeout();
    }
  }

  void _changeSpeed(double speed) {
    if (_controller == null || !_isInitialized) return;
    _controller!.setPlaybackSpeed(speed);
    setState(() {
      _playbackSpeed = speed;
    });
    if (_isPlaying) {
      _startControlsTimeout();
    }
  }

  Future<void> _toggleFullScreen() async {
    if (_controller == null || !_isInitialized) return;

    if (widget.isFullscreen) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isInFullScreen = true;
    });

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Center(
              child: KetionInFramePlayer(
                filePath: widget.filePath,
                caption: widget.caption,
                controller: _controller,
                isFullscreen: true,
              ),
            ),
          );
        },
      ),
    );

    if (mounted) {
      setState(() {
        _isInFullScreen = false;
      });
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    if (_controller != null) {
      _controller!.removeListener(_onControllerUpdate);
      if (widget.controller == null) {
        _controller!.dispose();
      }
      _controller = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget playerWidget;
    if (_isInFullScreen) {
      playerWidget = Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fullscreen,
                color: Colors.white70,
                size: 36,
              ),
              SizedBox(height: 8),
              Text(
                'Playing in fullscreen',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    } else if (_errorMessage != null) {
      playerWidget = Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else if (_controller == null || !_isInitialized) {
      playerWidget = Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    } else {
      final duration = _controller!.value.duration;
      final position = _controller!.value.position;
      final timeDisplay =
          '${_formatDuration(position)} / ${_formatDuration(duration)}';

      playerWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio > 0
              ? _controller!.value.aspectRatio
              : 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // 1. Video surface
              Positioned.fill(
                child: VideoPlayer(_controller!),
              ),

              // 2. Tap to toggle controls (behind interactive controls)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleControls,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),

              // 3. Center play/pause overlay
              if (!_isPlaying || _showControls)
                Center(
                  child: IgnorePointer(
                    ignoring: !_showControls && _isPlaying,
                    child: AnimatedOpacity(
                      opacity: (_showControls || !_isPlaying) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: GestureDetector(
                        onTap: _togglePlayback,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(14.0),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // 4. In-frame controls overlay (bottom gradient bar)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black87,
                            Colors.black45,
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 6.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VideoProgressIndicator(
                            _controller!,
                            allowScrubbing: true,
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            colors: VideoProgressColors(
                              playedColor: Theme.of(context).primaryColor,
                              bufferedColor: Colors.white38,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _togglePlayback,
                                child: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeDisplay,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const Spacer(),
                              PopupMenuButton<double>(
                                tooltip: 'Playback Speed',
                                initialValue: _playbackSpeed,
                                onSelected: _changeSpeed,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6.0,
                                    vertical: 2.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    '${_playbackSpeed == 1.0 ? '1' : _playbackSpeed}×',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                itemBuilder: (context) => _availableSpeeds
                                    .map(
                                      (speed) => PopupMenuItem<double>(
                                        value: speed,
                                        child: Text('$speed×'),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: _toggleFullScreen,
                                child: Icon(
                                  widget.isFullscreen
                                      ? Icons.fullscreen_exit
                                      : Icons.fullscreen,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget content = playerWidget;
    if (widget.caption != null && widget.caption!.isNotEmpty) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          playerWidget,
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              widget.caption!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    if (!widget.isFullscreen) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: content,
        ),
      );
    }

    return content;
  }
}
