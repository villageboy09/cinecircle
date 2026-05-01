import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'home_screen.dart'; // To use FeedPostItem and CommentsSheet
import 'public_profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? post;
  final String? postId;
  const PostDetailScreen({super.key, this.post, this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Map<String, dynamic>? _post;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _post = Map<String, dynamic>.from(widget.post!);
      _isInitialLoading = false;
      _recordView();
    } else if (widget.postId != null) {
      _fetchPostDetails(widget.postId!);
    }
  }

  Future<void> _fetchPostDetails(String postId) async {
    setState(() => _isInitialLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      final res = await http.get(
        Uri.parse(
          'https://team.cropsync.in/cine_circle/feed_actions_api.php?action=get_post&mobile_number=$mobile&post_id=$postId',
        ),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _post = data['data'];
            _isInitialLoading = false;
          });
          _recordView();
          return;
        }
      }
    } catch (e) {
      debugPrint('fetchPostDetails error: $e');
    }
    if (mounted) {
      setState(() => _isInitialLoading = false);
      _showChip('Error loading post');
    }
  }

  Future<void> _recordView() async {
    final postId = _post?['id']?.toString() ?? '';
    if (postId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      if (mobile.isEmpty) return;

      await http.post(
        Uri.parse('https://team.cropsync.in/cine_circle/feed_actions_api.php'),
        body: {
          'action': 'view_post',
          'mobile_number': mobile,
          'post_id': postId,
        },
      );
    } catch (e) {
      debugPrint('View record error: $e');
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;
    final postId = _post!['id'];
    final isLiked =
        _post!['is_liked'] == 1 ||
        _post!['is_liked'] == true ||
        _post!['is_liked'] == '1';
    final currentLikes =
        int.tryParse(_post!['likes_count']?.toString() ?? '0') ?? 0;

    setState(() {
      _post!['is_liked'] = !isLiked;
      _post!['likes_count'] = isLiked ? (currentLikes - 1) : (currentLikes + 1);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      await http.post(
        Uri.parse('https://team.cropsync.in/cine_circle/feed_actions_api.php'),
        body: {
          'action': 'like_post',
          'mobile_number': mobile,
          'post_id': postId.toString(),
        },
      );
    } catch (e) {
      debugPrint('Like error $e');
    }
  }

  Future<void> _toggleSave() async {
    if (_post == null) return;
    final postId = _post!['id'];
    final isSaved =
        _post!['is_saved'] == 1 ||
        _post!['is_saved'] == true ||
        _post!['is_saved'] == '1';

    setState(() {
      _post!['is_saved'] = !isSaved;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      final response = await http.post(
        Uri.parse('https://team.cropsync.in/cine_circle/feed_actions_api.php'),
        body: {
          'action': 'save_post',
          'mobile_number': mobile,
          'post_id': postId.toString(),
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final savedState = data['is_saved'] as bool;
          setState(() => _post!['is_saved'] = savedState);
          _showChip(savedState ? 'Post saved' : 'Post removed');
        } else {
          setState(() => _post!['is_saved'] = isSaved);
        }
      } else {
        setState(() => _post!['is_saved'] = isSaved);
      }
    } catch (e) {
      debugPrint('Save error $e');
      setState(() => _post!['is_saved'] = isSaved);
    }
  }

  void _showComments() {
    if (_post == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CommentsSheet(
        postId: _post!['id'].toString(),
        onCommentAdded: () {
          setState(() {
            final currentCount =
                int.tryParse(_post!['comments_count']?.toString() ?? '0') ?? 0;
            _post!['comments_count'] = (currentCount + 1).toString();
          });
        },
      ),
    );
  }

  void _sharePost() {
    if (_post == null) return;
    final postId = _post!['id']?.toString() ?? '';
    final url = 'https://team.cropsync.in/cine_circle/post/$postId';
    final title = _post!['title'] ?? 'Check out this post on CineCircle';

    // ignore: deprecated_member_use
    Share.share('$title: $url');
  }

  void _showChip(String message) {
    if (!mounted) return;
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Google Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Post Details',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Google Sans',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _post == null
          ? const Center(child: Text('Post not found'))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: FeedPostItem(
                post: _post!,
                timeAgo: _post!['created_at'] ?? 'Just now',
                onOpenAuthor: () {
                  final authorId =
                      (_post!['author_id'] ?? _post!['user_id'] ?? '')
                          .toString();
                  if (authorId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PublicProfileScreen(userId: authorId),
                      ),
                    );
                  }
                },
                onShowOptions: () {
                  // Options logic can be added here if needed
                },
                onToggleLike: _toggleLike,
                onShowLikes: () {
                  // Show likes logic
                },
                onShowComments: _showComments,
                onShowViews: () {
                  // Show views logic
                },
                onToggleSave: _toggleSave,
                onShare: _sharePost,
                onDoubleTapLike: _toggleLike,
              ),
            ),
    );
  }
}
