import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';

class StoryViewerScreen extends StatefulWidget {
  final Map<String, dynamic> userStories;
  final String? currentUserId;

  const StoryViewerScreen({super.key, required this.userStories, this.currentUserId});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  late AnimationController _animationController;
  VideoPlayerController? _videoController;
  
  late List<dynamic> _stories;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _stories = widget.userStories['stories'] ?? [];
    _pageController = PageController();
    _animationController = AnimationController(vsync: this);

    _loadStory(index: 0, animateToPage: false);
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });
  }

  void _nextStory() {
    _animationController.stop();
    _animationController.reset();
    setState(() {
      if (_currentIndex + 1 < _stories.length) {
        _currentIndex++;
        _loadStory(index: _currentIndex);
      } else {
        Navigator.pop(context);
      }
    });
  }

  void _previousStory() {
    if (_currentIndex - 1 >= 0) {
      setState(() {
        _currentIndex--;
        _loadStory(index: _currentIndex);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _loadStory({required int index, bool animateToPage = true}) async {
    _animationController.stop();
    _animationController.reset();
    _videoController?.dispose();
    _videoController = null;

    final story = _stories[index];
    if (story['media_type'] == 'video') {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(story['media_url']));
      try {
        await _videoController!.initialize();
        if (mounted) {
          setState(() {});
          _videoController!.play();
          _animationController.duration = _videoController!.value.duration;
        }
      } catch (e) {
        debugPrint('Video init error: $e');
        _animationController.duration = const Duration(seconds: 5);
      }
    } else {
      _animationController.duration = const Duration(seconds: 5);
    }
    
    if (!_isPaused) _animationController.forward();

    if (animateToPage) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    
    _markAsViewed(_stories[index]['id']);
  }

  Future<void> _markAsViewed(String storyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      
      await http.post(
        Uri.parse('https://team.cropsync.in/cine_circle/stories_api.php'),
        body: {
          'action': 'mark_story_viewed',
          'mobile_number': mobile,
          'story_id': storyId,
        },
      );
    } catch (e) {
      debugPrint('Error marking story as viewed: $e');
    }
  }

  Future<void> _sendReaction(String emoji) async {
    final storyId = _stories[_currentIndex]['id'];
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      
      await http.post(
        Uri.parse('https://team.cropsync.in/cine_circle/stories_api.php'),
        body: {
          'action': 'react_to_story',
          'mobile_number': mobile,
          'story_id': storyId,
          'emoji': emoji,
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sent $emoji'), duration: const Duration(seconds: 1)),
        );
      }
    } catch (e) {
      debugPrint('Reaction error: $e');
    }
  }

  void _showViewerList() {
    final storyId = _stories[_currentIndex]['id'];
    _animationController.stop();
    setState(() => _isPaused = true);
    _videoController?.pause();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _ViewerListSheet(storyId: storyId),
    ).then((_) {
      if (mounted) {
        setState(() => _isPaused = false);
        _animationController.forward();
        _videoController?.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMyStory = widget.userStories['user_id']?.toString().toLowerCase() == widget.currentUserId?.toString().toLowerCase();

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) {
          setState(() => _isPaused = true);
          _animationController.stop();
          _videoController?.pause();
        },
        onLongPressEnd: (_) {
          setState(() => _isPaused = false);
          _animationController.forward();
          _videoController?.play();
        },
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final dx = details.globalPosition.dx;
          if (dx < screenWidth / 3) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          children: [
            // PageView for Stories
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stories.length,
              itemBuilder: (context, index) {
                final s = _stories[index];
                if (s['media_type'] == 'video' && index == _currentIndex && _videoController != null && _videoController!.value.isInitialized) {
                  return Center(
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  );
                }
                return Center(
                  child: CachedNetworkImage(
                    imageUrl: s['media_url'],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                  ),
                );
              },
            ),

            // Top Progress Bars
            Positioned(
              top: 40,
              left: 10,
              right: 10,
              child: Row(
                children: _stories.asMap().entries.map((entry) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: entry.key == _currentIndex 
                              ? _animationController.value 
                              : (entry.key < _currentIndex ? 1.0 : 0.0),
                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                            minHeight: 2,
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // User Info
            Positioned(
              top: 55,
              left: 15,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: CachedNetworkImageProvider(widget.userStories['profile_image_url'] ?? ''),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.userStories['full_name'] ?? '',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Close Button
            Positioned(
              top: 55,
              right: 15,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Bottom Actions
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: isMyStory 
                ? _buildMyStoryBottomBar()
                : _buildReactionBottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyStoryBottomBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _showViewerList,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text('Viewers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReactionBottomBar() {
    final emojis = ['❤️', '😂', '😮', '😢', '🔥', '👏'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: emojis.map((e) => GestureDetector(
          onTap: () => _sendReaction(e),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: Text(e, style: const TextStyle(fontSize: 24)),
          ),
        )).toList(),
      ),
    );
  }
}

class _ViewerListSheet extends StatefulWidget {
  final String storyId;
  const _ViewerListSheet({required this.storyId});

  @override
  State<_ViewerListSheet> createState() => _ViewerListSheetState();
}

class _ViewerListSheetState extends State<_ViewerListSheet> {
  List<dynamic> _viewers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchViewers();
  }

  Future<void> _fetchViewers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      
      final response = await http.get(
        Uri.parse('https://team.cropsync.in/cine_circle/stories_api.php?action=get_story_viewers&mobile_number=$mobile&story_id=${widget.storyId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _viewers = data['data'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching viewers: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Viewers (${_viewers.length})',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(color: Colors.white24),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : (_viewers.isEmpty 
                  ? const Center(child: Text('No viewers yet', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _viewers.length,
                      itemBuilder: (context, index) {
                        final v = _viewers[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(v['profile_image_url'] ?? ''),
                          ),
                          title: Text(v['full_name'] ?? '', style: const TextStyle(color: Colors.white)),
                          trailing: v['reaction_emoji'] != null 
                            ? Text(v['reaction_emoji'], style: const TextStyle(fontSize: 20))
                            : null,
                        );
                      },
                    )
                ),
          ),
        ],
      ),
    );
  }
}
