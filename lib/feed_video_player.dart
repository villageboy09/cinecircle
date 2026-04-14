import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final double? aspectRatio;

  const FeedVideoPlayer({super.key, required this.videoUrl, this.aspectRatio});

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      // Ensure the first frame is shown
      if (mounted) setState(() {});
    });

    _controller.addListener(() {
      if (_controller.value.isPlaying != _isPlaying) {
        if (mounted) setState(() => _isPlaying = _controller.value.isPlaying);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return GestureDetector(
            onTap: _togglePlay,
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller),
                  if (!_isPlaying)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
                    ),
                  if (_controller.value.isBuffering)
                    const CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
          );
        } else {
          // Placeholder with a subtle shimmer while initializing
          return AspectRatio(
            aspectRatio: 16 / 9, // Default fallback before init
            child: Container(
              color: Colors.grey.shade100,
              child: const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
            ),
          );
        }
      },
    );
  }
}
