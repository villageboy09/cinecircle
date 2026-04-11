import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;

  const FullScreenVideoPlayer({super.key, required this.videoUrl, required this.title});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      }).catchError((e) {
        setState(() => _isError = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _isError 
                ? const Text('Failed to load video', style: TextStyle(color: Colors.white, fontFamily: 'Google Sans'))
                : _controller.value.isInitialized
                  ? Hero(
                      tag: widget.videoUrl,
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),
            // Play/Pause Overlay
            if (_controller.value.isInitialized)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.value.isPlaying ? _controller.pause() : _controller.play();
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 60),
                    ),
                  ),
                ),
              ),
            // Close Button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // Title
            Positioned(
              top: 24,
              left: 16,
              right: 60,
              child: Text(
                widget.title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Google Sans'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Timeline
            if (_controller.value.isInitialized)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.white,
                    bufferedColor: Colors.white54,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
