import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'post_detail_screen.dart';
import 'discover_screen.dart';
import 'jobs_screen.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';
import 'trivia_screen.dart';
import 'activity_screen.dart';
import 'follow_card.dart';
import 'create_post_sheet.dart';
import 'feed_video_player.dart';
import 'public_profile_screen.dart';
import 'global_notifier.dart';
import 'stories_widgets.dart';
import 'story_viewer_screen.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  String? _nextCursor;
  List<dynamic> _posts = [];
  List<dynamic> _trending = [];
  List<dynamic> _nearby = [];
  String? _currentUserId;
  bool _currentUserHasStories = false;
  bool _currentUserHasUnviewed = false;
  String? _userProfileImage;
  Map<String, double> _aspectRatios = {};
  final Map<String, List<dynamic>> _viewersCache = {};
  final Map<String, List<dynamic>> _likesCache = {};

  // Badge counts
  int _unreadNotifications = 0;
  int _unreadMessages = 0;
  Timer? _badgeTimer;

  // FAB Scroll Logic
  late ScrollController _scrollController;
  bool _showFab = true;
  double _lastOffset = 0;
  DateTime? _lastBackPress;
  DateTime? _lastHomeTap;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _fetchHomeFeed();
    _loadUserProfile();
    _loadAspectRatios();
    _fetchBadgeCounts();
    // Poll badge counts every 60 seconds
    _badgeTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _fetchBadgeCounts(),
    );
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final delta = _scrollController.offset - _lastOffset;
    // Toggle FAB
    if (delta > 5 && _showFab && _scrollController.offset > 50) {
      setState(() => _showFab = false);
    } else if (delta < -5 && !_showFab) {
      setState(() => _showFab = true);
    }

    // Load more when near bottom
    if (_scrollController.position.maxScrollExtent > 0 &&
        _scrollController.offset >=
            _scrollController.position.maxScrollExtent - 200 &&
        delta > 0 &&
        !_isFetchingMore &&
        _hasMore) {
      _fetchMorePosts();
    }

    _lastOffset = _scrollController.offset;
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('user_phone') ?? '';
    final cachedImage = prefs.getString('user_image');

    if (cachedImage != null && cachedImage.isNotEmpty) {
      if (mounted) setState(() => _userProfileImage = cachedImage);
    }

    if (mobile.isNotEmpty) {
      try {
        final res = await http.post(
          Uri.parse('https://team.cropsync.in/cine_circle/cinecircle_api.php'),
          body: {'action': 'get_profile', 'mobile_number': mobile},
        );
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          if (data['status'] == 'success') {
            final img = data['profile']['profile_image_url'] ?? '';
            if (mounted) setState(() => _userProfileImage = img);
            await prefs.setString('user_image', img);
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _fetchHomeFeed({bool silent = false}) async {
    // Show skeleton only for true initial load
    if (_posts.isEmpty && !silent) {
      setState(() => _isLoading = true);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';

      final response = await http.get(
        Uri.parse(
          'https://team.cropsync.in/cine_circle/homefeed_api.php?mobile_number=$mobile&limit=15',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _currentUserId = data['data']['current_user_id']?.toString();
            _currentUserHasStories = data['data']['current_user_has_stories'] == true;
            _currentUserHasUnviewed = data['data']['current_user_has_unviewed'] == true;
            _posts = data['data']['posts'] ?? [];
            _trending = data['data']['trending'] ?? [];
            _nearby = data['data']['nearby'] ?? [];
            _nextCursor = data['data']['next_cursor'] as String?;
            _hasMore = data['data']['has_more'] == true;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Feed fetch error: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchMorePosts() async {
    if (_isFetchingMore || !_hasMore || _nextCursor == null) return;
    setState(() => _isFetchingMore = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      final response = await http.get(
        Uri.parse(
          'https://team.cropsync.in/cine_circle/homefeed_api.php'
          '?mobile_number=$mobile&limit=15&cursor=${Uri.encodeComponent(_nextCursor!)}',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final newPosts = List<dynamic>.from(data['data']['posts'] ?? []);
          setState(() {
            _posts.addAll(newPosts);
            _nextCursor = data['data']['next_cursor'] as String?;
            _hasMore = data['data']['has_more'] == true;
          });
        }
      }
    } catch (e) {
      debugPrint('fetchMore error: $e');
    }
    setState(() => _isFetchingMore = false);
  }

  Future<void> _fetchBadgeCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      if (mobile.isEmpty) return;

      // Notifications unread count
      final notifRes = await http.get(
        Uri.parse(
          'https://team.cropsync.in/cine_circle/social_api.php'
          '?action=get_notifications&mobile_number=$mobile&limit=1',
        ),
      );
      if (notifRes.statusCode == 200) {
        final d = json.decode(notifRes.body);
        if (d['status'] == 'success' && mounted) {
          setState(
            () => _unreadNotifications = (d['unread_count'] ?? 0) as int,
          );
        }
      }

      // Messages unread count (sum of all conversation unread_counts)
      final msgRes = await http.get(
        Uri.parse(
          'https://team.cropsync.in/cine_circle/social_api.php'
          '?action=get_conversations&mobile_number=$mobile',
        ),
      );
      if (msgRes.statusCode == 200) {
        final d = json.decode(msgRes.body);
        if (d['status'] == 'success' && mounted) {
          final convs = List<dynamic>.from(d['data'] ?? []);
          final total = convs.fold<int>(
            0,
            (sum, c) => sum + ((c['unread_count'] ?? 0) as int),
          );
          setState(() => _unreadMessages = total);
        }
      }
    } catch (e) {
      debugPrint('Badge count error: $e');
    }
  }

  Future<void> _loadAspectRatios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('post_aspect_ratios') ?? '{}';
      final Map<String, dynamic> map = json.decode(raw);
      setState(() {
        _aspectRatios = map.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
      });
    } catch (_) {}
  }

  String _formatTimeAgo(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'Just now';
    try {
      final DateTime postDate = DateTime.parse(timestamp);
      final Duration diff = DateTime.now().difference(postDate);

      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min';
      if (diff.inHours < 24) {
        return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'}';
      }
      if (diff.inDays < 7) {
        return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'}';
      }
      return '${postDate.day}/${postDate.month}/${postDate.year}';
    } catch (_) {
      return '';
    }
  }

  void _showChip(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Google Sans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? Colors.red.shade800
            : Colors.black.withValues(alpha: 0.9),
        duration: const Duration(seconds: 2),
        width: 220,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }

  Future<void> _toggleLike(int index) async {
    final post = _posts[index];
    final postId = post['id'];
    final isLiked =
        post['is_liked'] == 1 ||
        post['is_liked'] == true ||
        post['is_liked'] == '1';

    setState(() {
      _posts[index]['is_liked'] = !isLiked;
      _posts[index]['likes_count'] = isLiked
          ? (int.parse(post['likes_count'].toString()) - 1)
          : (int.parse(post['likes_count'].toString()) + 1);
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

  Future<void> _toggleSave(int index) async {
    final post = _posts[index];
    final postId = post['id'];
    final isSaved =
        post['is_saved'] == 1 ||
        post['is_saved'] == true ||
        post['is_saved'] == '1';

    // Optimistic UI update
    setState(() {
      _posts[index]['is_saved'] = !isSaved;
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
          setState(() => _posts[index]['is_saved'] = savedState);
          _showChip(savedState ? 'Post saved' : 'Post removed');
        } else {
          setState(() => _posts[index]['is_saved'] = isSaved);
        }
      } else {
        setState(() => _posts[index]['is_saved'] = isSaved);
      }
    } catch (e) {
      debugPrint('Save error $e');
      setState(() => _posts[index]['is_saved'] = isSaved);
    }
  }

  Future<void> _recordView(String postId) async {
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

  Future<void> _refreshHomeAndScrollTop() async {
    await _fetchHomeFeed();
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleHomeTap() {
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      return;
    }

    final now = DateTime.now();
    if (_lastHomeTap != null &&
        now.difference(_lastHomeTap!) <= const Duration(milliseconds: 350)) {
      _lastHomeTap = null;
      _refreshHomeAndScrollTop();
    } else {
      _lastHomeTap = now;
    }
  }

  Future<bool> _handleBackPress() async {
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      return false;
    }

    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Press back again to exit')),
        );
      }
      return false;
    }
    return true;
  }

  void _showCommentsBottomSheet(String postId, int postIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CommentsSheet(
        postId: postId,
        onCommentAdded: () {
          setState(() {
            final currentCount =
                int.tryParse(
                  _posts[postIndex]['comments_count']?.toString() ?? '0',
                ) ??
                0;
            _posts[postIndex]['comments_count'] = (currentCount + 1).toString();
          });
        },
      ),
    );
  }

  void _openCreatePostSheet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    );
    if (result == true) {
      _fetchHomeFeed();
    }
  }

  void _openHomeSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeSearchScreen(currentUserId: _currentUserId ?? ''),
      ),
    );
  }

  void _showPostOptions(Map<String, dynamic> post) {
    final bool isOwner = post['user_id']?.toString() == _currentUserId;
    final bool canEdit = isOwner && _canEditPost(post['created_at']);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (isOwner)
              _buildOptionItem(
                label: 'Delete Post',
                icon: Icons.delete_outline,
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(post['id'].toString());
                },
              ),
            if (canEdit)
              _buildOptionItem(
                label: 'Edit Post',
                icon: Icons.edit_outlined,
                onTap: () {
                  Navigator.pop(context);
                  _openEditPostSheet(post);
                },
              ),
            _buildOptionItem(
              label: 'Share Post',
              icon: Icons.ios_share,
              onTap: () {
                Navigator.pop(context);
                _sharePost(post);
              },
            ),
            if (!isOwner)
              _buildOptionItem(
                label: 'Report Post',
                icon: Icons.flag_outlined,
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _reportPost(post['id']?.toString() ?? '');
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _reportPost(String postId) {
    if (postId.isEmpty) return;

    const reasons = [
      'Inappropriate content',
      'Spam or misleading',
      'Harassment or bullying',
      'Fake profile or impersonation',
      'Violence or dangerous content',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Report post',
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Why are you reporting this post?',
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...reasons.map(
              (reason) => InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  await _submitReport(postId, reason);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flag_outlined,
                        size: 20,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        reason,
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport(String postId, String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      if (mobile.isEmpty) return;
      final response = await http.post(
        Uri.parse('https://team.cropsync.in/cine_circle/feed_actions_api.php'),
        body: {
          'action': 'report_post',
          'mobile_number': mobile,
          'post_id': postId,
          'reason': reason,
        },
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final isAlready = data['status'] == 'already_reported';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAlready
                  ? 'You have already reported this post.'
                  : (data['message'] ?? 'Report submitted'),
              style: const TextStyle(fontFamily: 'Google Sans'),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Report error: $e');
    }
  }

  bool _canEditPost(dynamic createdAt) {
    if (createdAt == null) return false;
    try {
      final ts = createdAt.toString();
      final normalized = ts.contains('Z') || ts.contains('+')
          ? ts
          : '${ts.replaceFirst(' ', 'T')}Z';
      final created = DateTime.parse(normalized).toLocal();
      return DateTime.now().difference(created).inMinutes <= 15;
    } catch (_) {
      return false;
    }
  }

  void _sharePost(Map<String, dynamic> post) {
    final postId = post['id']?.toString() ?? '';
    final url = 'https://team.cropsync.in/cine_circle/post/$postId';
    final title = post['title'] ?? 'Check out this post on CineCircle';
    
    // ignore: deprecated_member_use
    Share.share('$title: $url');
  }

  void _openEditPostSheet(Map<String, dynamic> post) {
    final titleController = TextEditingController(
      text: (post['title'] ?? '').toString(),
    );
    final descriptionController = TextEditingController(
      text: (post['description'] ?? '').toString(),
    );
    final categories = <String>[
      'Update',
      'Project Update',
      'Casting Call',
      'Screening Room',
      'Behind the Scenes',
      'Community Highlight',
    ];
    String selectedCategory = (post['category'] ?? 'Update').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          margin: const EdgeInsets.all(16),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Post',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: 'Caption',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                items: categories
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setModalState(() => selectedCategory = value);
                },
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final postId = post['id']?.toString() ?? '';
                    if (postId.isEmpty) return;
                    Navigator.pop(context);
                    await _updatePost(
                      postId: postId,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      category: selectedCategory,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updatePost({
    required String postId,
    required String title,
    required String description,
    required String category,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      final response = await http.post(
        Uri.parse('https://team.cropsync.in/cine_circle/social_api.php'),
        body: {
          'action': 'update_post',
          'mobile_number': mobile,
          'post_id': postId,
          'title': title,
          'description': description,
          'category': category,
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          await _fetchHomeFeed();
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Post updated')));
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Unable to update post')),
          );
        }
      }
    } catch (e) {
      debugPrint('Update post error: $e');
    }
  }

  void _openAuthorProfile(Map<String, dynamic> post) {
    final authorId = post['user_id']?.toString() ?? '';
    if (authorId.isEmpty) return;
    if (authorId == _currentUserId) {
      setState(() => _selectedIndex = 5);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: authorId)),
    );
  }

  Widget _buildOptionItem({
    required String label,
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? Colors.grey.shade800).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color ?? Colors.grey.shade800, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Google Sans',
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: color ?? Colors.grey.shade800,
        ),
      ),
      onTap: onTap,
    );
  }

  void _confirmDelete(String postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_sweep_rounded,
                color: Colors.red.shade600,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Delete this post?',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action is permanent and cannot be undone. Are you sure you want to remove this from your circle?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Google Sans',
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deletePost(postId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';

      final response = await http.post(
        Uri.parse('https://team.cropsync.in/cine_circle/social_api.php'),
        body: {
          'action': 'delete_post',
          'mobile_number': mobile,
          'post_id': postId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _posts.removeWhere((p) => p['id']?.toString() == postId);
          });
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Post deleted')));
          }
        }
      }
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }

  void _showViewsBottomSheet(String postId) {
    if (postId.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Viewers',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<dynamic>>(
              future: _fetchViewers(postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerListPlaceholder();
                }
                final viewers = snapshot.data ?? [];
                if (viewers.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No viewers yet.',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: ListView.separated(
                    itemCount: viewers.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final viewer = viewers[index];
                      final name = viewer['full_name'] ?? 'User';
                      final imageUrl = viewer['profile_image_url'] ?? '';
                      final city = viewer['city'] ?? '';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl.isEmpty
                              ? Icon(Icons.person, color: Colors.grey.shade500)
                              : null,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Google Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: city.toString().isNotEmpty
                            ? Text(
                                city,
                                style: const TextStyle(
                                  fontFamily: 'Google Sans',
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLikesBottomSheet(String postId) {
    if (postId.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Likes',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<dynamic>>(
              future: _fetchLikes(postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerListPlaceholder();
                }
                final likes = snapshot.data ?? [];
                if (likes.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No likes yet.',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: ListView.separated(
                    itemCount: likes.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = likes[index];
                      final name = user['full_name'] ?? 'User';
                      final imageUrl = user['profile_image_url'] ?? '';
                      final city = user['city'] ?? '';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl.isEmpty
                              ? Icon(Icons.person, color: Colors.grey.shade500)
                              : null,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Google Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: city.toString().isNotEmpty
                            ? Text(
                                city,
                                style: const TextStyle(
                                  fontFamily: 'Google Sans',
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<dynamic>> _fetchViewers(String postId) async {
    if (_viewersCache.containsKey(postId)) {
      return _viewersCache[postId]!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      final response = await http.get(
        Uri.parse(
          'https://team.cropsync.in/cine_circle/feed_actions_api.php?action=get_post_viewers&mobile_number=$mobile&post_id=$postId',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final viewers = List<dynamic>.from(data['data'] ?? []);
          _viewersCache[postId] = viewers;
          return viewers;
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<dynamic>> _fetchLikes(String postId) async {
    if (_likesCache.containsKey(postId)) {
      return _likesCache[postId]!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      final response = await http.get(
        Uri.parse(
          'https://team.cropsync.in/cine_circle/feed_actions_api.php?action=get_post_likes&mobile_number=$mobile&post_id=$postId',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final likes = List<dynamic>.from(data['data'] ?? []);
          _likesCache[postId] = likes;
          return likes;
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> feedItems = _posts.asMap().entries.map((entry) {
      int index = entry.key;
      var post = entry.value;
      return _buildFeedItem(index, post, key: ValueKey('post_${post['id']}'));
    }).toList();

    final trendingTalentModule = _trending.isNotEmpty
        ? Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trending Talent',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 290,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: _trending
                          .map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: _buildTrendingCard(t),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final nearbyCreatorsModule = _nearby.isNotEmpty
        ? Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nearby Creators',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.1,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: _nearby.map((n) => _buildNearbyCard(n)).toList(),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final List<Widget> combinedFeed = [];
    if (feedItems.isNotEmpty) {
      combinedFeed.add(feedItems[0]);
    } else {
      combinedFeed.add(
        const SizedBox(
          height: 100,
          child: Center(
            child: Text(
              "No posts found",
              style: TextStyle(fontFamily: 'Google Sans'),
            ),
          ),
        ),
      );
    }

    combinedFeed.add(trendingTalentModule);

    if (feedItems.length > 1) combinedFeed.add(feedItems[1]);
    if (feedItems.length > 2) combinedFeed.add(feedItems[2]);

    combinedFeed.add(nearbyCreatorsModule);

    if (feedItems.length > 3) combinedFeed.addAll(feedItems.sublist(3));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _handleBackPress();
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            // Feed Tab (Index 0)
            SafeArea(
              child: Column(
                children: [
                  // Top Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRect(
                          child: Container(
                            height: 32,
                            width: 120, // Adjust width as necessary
                            alignment: Alignment.centerLeft,
                            child: Transform.scale(
                              scale: 1.8,
                              child: Image.asset(
                                'assets/cinelogo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: Colors.black,
                            size: 24,
                          ),
                          onPressed: _openHomeSearch,
                        ),
                        const SizedBox(width: 4),
                        // Notifications bell with unread badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_none,
                                color: Colors.black,
                                size: 26,
                              ),
                              onPressed: () async {
                                setState(() => _unreadNotifications = 0);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ActivityScreen(),
                                  ),
                                );
                                // Refresh badges when returning
                                _fetchBadgeCounts();
                              },
                            ),
                            if (_unreadNotifications > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(width: 8),
                        UserAvatarWithStory(
                          userId: _currentUserId ?? '',
                          profileImageUrl: _userProfileImage ?? '',
                          radius: 17,
                          hasStories: _currentUserHasStories,
                          hasUnviewed: _currentUserHasUnviewed,
                          onTap: () {
                            setState(() {
                              _selectedIndex = 5;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  // List
                  Expanded(
                    child: _isLoading
                        ? _buildFeedSkeleton()
                        : RefreshIndicator(
                            color: Colors.black,
                            onRefresh: _fetchHomeFeed,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.zero,
                              itemCount: combinedFeed.length + 2,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return StoriesBar(
                                    currentUserId: _currentUserId,
                                    onStoryTap: (userStories) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => StoryViewerScreen(
                                            userStories: userStories,
                                            currentUserId: _currentUserId,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }
                                
                                if (index == combinedFeed.length + 1) {
                                  if (_isFetchingMore) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 24,
                                      ),
                                      child: Center(
                                        child: Shimmer.fromColors(
                                          baseColor: Colors.grey.shade200,
                                          highlightColor: Colors.white,
                                          child: Container(
                                            width: 120,
                                            height: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  if (!_hasMore && _posts.isNotEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 24,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '— You\'re all caught up —',
                                          style: TextStyle(
                                            fontFamily: 'Google Sans',
                                            fontSize: 13,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox(height: 80);
                                }
                                final item = combinedFeed[index - 1];
                                if (index == 1) return item;
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Divider(
                                      height: 1,
                                      thickness: 0.5,
                                      color: Colors.grey.shade200,
                                    ),
                                    item,
                                  ],
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const TriviaScreen(),
            // Discover Tab (Index 2)
            const DiscoverScreen(),
            // Jobs Tab (Index 3)
            const JobsScreen(),
            // Messages (Chat) Tab (Index 4)
            const MessagesScreen(),
            // Profile Tab (Index 5)
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
          onTap: (index) {
            if (index == 0) {
              _handleHomeTap();
            } else if (index == 4) {
              // Clear chat badge on open
              setState(() {
                _selectedIndex = index;
                _unreadMessages = 0;
              });
            } else if (index == 5) {
              setState(() => _selectedIndex = index);
              // Refresh profile image in case it was updated
              _loadUserProfile();
            } else {
              setState(() => _selectedIndex = index);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey.shade500,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Google Sans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Google Sans',
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'Trivia',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Discover',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.work_outline),
              activeIcon: Icon(Icons.work),
              label: 'Jobs',
            ),
            // Chat with unread dot
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.chat_bubble_outline),
                  if (_unreadMessages > 0)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.chat_bubble),
                  if (_unreadMessages > 0)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Chat',
            ),
          ],
        ),
        floatingActionButton: _selectedIndex == 0
            ? AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                offset: _showFab ? Offset.zero : const Offset(0, 3.5),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _showFab ? 1 : 0,
                  child: FloatingActionButton(
                    onPressed: () => _openCreatePostSheet(),
                    backgroundColor: Colors.black,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildFeedItem(int index, Map<String, dynamic> post, {Key? key}) {
    final String postId = post['id']?.toString() ?? '';
    final String timeAgo = _formatTimeAgo(post['created_at']);
    final double? storedRatio = _aspectRatios[postId];
    return FeedPostItem(
      key: key,
      post: post,
      timeAgo: timeAgo,
      aspectRatio: storedRatio,
      onOpenAuthor: () => _openAuthorProfile(post),
      onShowOptions: () => _showPostOptions(post),
      onToggleLike: () => _toggleLike(index),
      onShowLikes: () => _showLikesBottomSheet(postId),
      onShowComments: () => _showCommentsBottomSheet(postId, index),
      onShowViews: () => _showViewsBottomSheet(postId),
      onToggleSave: () => _toggleSave(index),
      onShare: () => _sharePost(post),
      onRecordView: postId.isNotEmpty ? () => _recordView(postId) : null,
      onDoubleTapLike: () => _toggleLike(index),
    );
  }

  Widget _buildTrendingCard(Map<String, dynamic> user) {
    final uid = user['id']?.toString() ?? '';
    final v = user['is_following'];
    final bool isFollowing = v == true || v == 1 || v == '1' || v == 'true';
    return FollowCard(
      key: ValueKey('trending_$uid'),
      userId: uid,
      name: user['full_name'] ?? 'User',
      role: user['role_title'] ?? 'Member',
      location: user['city'] ?? '',
      imageUrl: user['profile_image_url'],
      cardType: CardType.trending,
      initialIsFollowing: isFollowing,
    );
  }

  Widget _buildNearbyCard(Map<String, dynamic> user) {
    final uid = user['id']?.toString() ?? '';
    final v = user['is_following'];
    final bool isFollowing = v == true || v == 1 || v == '1' || v == 'true';
    return FollowCard(
      key: ValueKey('nearby_$uid'),
      userId: uid,
      name: user['full_name'] ?? 'User',
      role: user['role_title'] ?? 'Member',
      location: user['city'] ?? '',
      imageUrl: user['profile_image_url'],
      cardType: CardType.nearby,
      initialIsFollowing: isFollowing,
    );
  }

  Widget _buildFeedSkeleton() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: 4,
      separatorBuilder: (context, _) => const SizedBox(height: 8),
      itemBuilder: (context, _) => Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade200,
                    highlightColor: Colors.white,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade200,
                        highlightColor: Colors.white,
                        child: Container(
                          width: 120,
                          height: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade200,
                        highlightColor: Colors.white,
                        child: Container(
                          width: 80,
                          height: 10,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.white,
              child: Container(
                width: double.infinity,
                height: 400,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade200,
                highlightColor: Colors.white,
                child: Container(width: 200, height: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeedPostItem extends StatelessWidget {
  final Map<String, dynamic> post;
  final String timeAgo;
  final double? aspectRatio;
  final VoidCallback onOpenAuthor;
  final VoidCallback onShowOptions;
  final VoidCallback onToggleLike;
  final VoidCallback onShowLikes;
  final VoidCallback onShowComments;
  final VoidCallback onShowViews;
  final VoidCallback onToggleSave;
  final VoidCallback onShare;
  final VoidCallback? onRecordView;
  final VoidCallback? onDoubleTapLike;
  final bool showOptions;

  const FeedPostItem({
    super.key,
    required this.post,
    required this.timeAgo,
    this.aspectRatio,
    required this.onOpenAuthor,
    required this.onShowOptions,
    required this.onToggleLike,
    required this.onShowLikes,
    required this.onShowComments,
    required this.onShowViews,
    required this.onToggleSave,
    required this.onShare,
    this.onRecordView,
    this.onDoubleTapLike,
    this.showOptions = true,
  });

  @override
  Widget build(BuildContext context) {
    final String postId = post['id']?.toString() ?? '';
    final String fullName = post['author_name'] ?? 'User';
    final String profileImg = post['profile_image_url'] ?? '';
    final String category = post['category'] ?? 'Update';
    final String title = post['title'] ?? '';
    final String description = post['description'] ?? '';

    final bool isLiked =
        post['is_liked'] == 1 ||
        post['is_liked'] == true ||
        post['is_liked'] == '1';
    final bool isSaved =
        post['is_saved'] == 1 ||
        post['is_saved'] == true ||
        post['is_saved'] == '1';
    final String likesCount = (post['likes_count'] ?? '0').toString();
    final String commentsCount = (post['comments_count'] ?? '0').toString();
    final String viewsCount = (post['views_count'] ?? '0').toString();

    if (onRecordView != null && postId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onRecordView!());
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Instagram Style)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                UserAvatarWithStory(
                  userId: post['user_id']?.toString() ?? '',
                  profileImageUrl: profileImg,
                  radius: 18,
                  hasStories: post['has_stories'] == true || post['has_stories'] == 1,
                  hasUnviewed: post['has_unviewed_stories'] == true || post['has_unviewed_stories'] == 1,
                  onTap: onOpenAuthor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onOpenAuthor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontFamily: 'Google Sans',
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Category Tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Google Sans',
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (showOptions)
                  GestureDetector(
                    onTap: onShowOptions,
                    child: const Icon(Icons.more_vert, size: 18),
                  ),
              ],
            ),
          ),

          // CAPTION ABOVE MEDIA (As requested)
          Padding(
            padding: const EdgeInsets.only(
              left: 14,
              right: 14,
              bottom: 10,
              top: 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          // Media (Full Width)
          if ((post['media_url'] ?? '').toString().isNotEmpty) ...[
            GestureDetector(
              onDoubleTap: onDoubleTapLike,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: Colors.grey.shade100,
                      width: 0.5,
                    ),
                  ),
                ),
                child: post['media_type'] == 'image'
                    ? (aspectRatio != null
                          ? AspectRatio(
                              aspectRatio: aspectRatio!,
                              child: Image.network(
                                post['media_url'],
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.network(
                              post['media_url'],
                              fit: BoxFit.contain,
                            ))
                    : post['media_type'] == 'video'
                    ? FeedVideoPlayer(videoUrl: post['media_url'])
                    : const SizedBox.shrink(),
              ),
            ),
          ],

          // Actions Row (Cupertino Style)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _buildActionIcon(
                  icon: isLiked
                      ? CupertinoIcons.heart_fill
                      : CupertinoIcons.heart,
                  color: isLiked ? Colors.red : Colors.black,
                  onTap: onToggleLike,
                ),
                const SizedBox(width: 20),
                _buildActionIcon(
                  icon: CupertinoIcons.chat_bubble,
                  onTap: onShowComments,
                ),
                const SizedBox(width: 20),
                _buildActionIcon(
                  icon: CupertinoIcons.paperplane,
                  onTap: onShare,
                ),
                const Spacer(),
                // Views (Stats)
                GestureDetector(
                  onTap: onShowViews,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bar_chart_rounded,
                        size: 20,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        viewsCount,
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                _buildActionIcon(
                  icon: isSaved
                      ? CupertinoIcons.bookmark_fill
                      : CupertinoIcons.bookmark,
                  onTap: onToggleSave,
                ),
              ],
            ),
          ),

          // Likes Count Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: GestureDetector(
              onTap: onShowLikes,
              child: Text(
                '$likesCount likes',
                style: const TextStyle(
                  fontFamily: 'Google Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          if (commentsCount != '0')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: GestureDetector(
                onTap: onShowComments,
                child: Text(
                  'View all $commentsCount comments',
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    Color color = Colors.black,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 24, color: color),
    );
  }
}

// ──────────────────────────────────────────────
// Standalone Comments Bottom Sheet Widget
// ──────────────────────────────────────────────
class CommentsSheet extends StatefulWidget {
  final String postId;
  final VoidCallback onCommentAdded;

  const CommentsSheet({
    super.key,
    required this.postId,
    required this.onCommentAdded,
  });

  @override
  State<CommentsSheet> createState() => CommentsSheetState();
}

class ShimmerListPlaceholder extends StatelessWidget {
  final int itemCount;

  const ShimmerListPlaceholder({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: ListView.separated(
          itemCount: itemCount,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 120,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  final List<String> _quickComments = const [
    'Great work!',
    'Interested in this.',
    'Looks amazing.',
    'Sent you a DM.',
  ];

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      final response = await http.get(
        Uri.parse(
          'https://team.cropsync.in/cine_circle/feed_actions_api.php?action=get_comments&mobile_number=$mobile&post_id=${widget.postId}',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _comments = data['data'] ?? [];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Fetch comments error: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _postComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      final response = await http.post(
        Uri.parse('https://team.cropsync.in/cine_circle/feed_actions_api.php'),
        body: {
          'action': 'comment_post',
          'mobile_number': mobile,
          'post_id': widget.postId,
          'comment': text,
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _controller.clear();
          widget.onCommentAdded();
          await _fetchComments();
        }
      }
    } catch (e) {
      debugPrint('Post comment error: $e');
    }
    setState(() => _isSending = false);
  }

  String _formatTimeAgo(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'Just now';
    try {
      final DateTime postDate = DateTime.parse(timestamp);
      final Duration diff = DateTime.now().difference(postDate);

      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min';
      if (diff.inHours < 24) {
        return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'}';
      }
      if (diff.inDays < 7) {
        return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'}';
      }
      return '${postDate.day}/${postDate.month}/${postDate.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            // Drag Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Comments',
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            if (_quickComments.isNotEmpty)
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  itemCount: _quickComments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final text = _quickComments[index];
                    return ActionChip(
                      label: Text(
                        text,
                        style: const TextStyle(fontFamily: 'Google Sans'),
                      ),
                      onPressed: () {
                        _controller.text = text;
                        _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: _controller.text.length),
                        );
                      },
                    );
                  },
                ),
              ),
            // Comments List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                  : _comments.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.black26,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No comments yet. Be the first!',
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _comments.length,
                      itemBuilder: (context, i) {
                        final c = _comments[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: c['profile_image_url'] != null
                                    ? NetworkImage(c['profile_image_url'])
                                    : null,
                                child: c['profile_image_url'] == null
                                    ? Icon(
                                        Icons.person,
                                        size: 18,
                                        color: Colors.grey.shade500,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          c['full_name'] ?? 'User',
                                          style: const TextStyle(
                                            fontFamily: 'Google Sans',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatTimeAgo(c['created_at']),
                                          style: TextStyle(
                                            fontFamily: 'Google Sans',
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c['comment'] ?? '',
                                      style: const TextStyle(
                                        fontFamily: 'Google Sans',
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            // Input Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 280,
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: TextStyle(
                          fontFamily: 'Google Sans',
                          color: Colors.grey.shade500,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isSending ? null : _postComment,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Home Search Screen
// ──────────────────────────────────────────────
class HomeSearchScreen extends StatefulWidget {
  final String currentUserId;

  const HomeSearchScreen({super.key, required this.currentUserId});

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  List<dynamic> _users = [];
  List<dynamic> _posts = [];
  List<dynamic> _newUsers = [];
  bool _isLoadingNewUsers = false;
  final Map<String, List<dynamic>> _viewersCache = {};
  final Map<String, List<dynamic>> _likesCache = {};

  @override
  void initState() {
    super.initState();
    _fetchNewUsers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<String> _getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone') ?? '';
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchResults(value.trim());
    });
  }

  Future<void> _fetchNewUsers() async {
    setState(() => _isLoadingNewUsers = true);
    try {
      final mobile = await _getMobile();
      final res = await http.get(
        Uri.parse(
          'https://team.cropsync.in/cine_circle/feed_actions_api.php?action=get_new_users&mobile_number=$mobile',
        ),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          setState(() => _newUsers = data['data'] ?? []);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingNewUsers = false);
  }

  Future<void> _fetchResults(String query) async {
    if (query.isEmpty) {
      setState(() {
        _users = [];
        _posts = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final mobile = await _getMobile();
      final uri = Uri.parse(
        'https://team.cropsync.in/cine_circle/feed_actions_api.php?action=search&mobile_number=$mobile&query=${Uri.encodeComponent(query)}',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _users = data['users'] ?? [];
            _posts = data['posts'] ?? [];
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openProfile(String userId) {
    if (userId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: userId)),
    );
  }

  String _formatTimeAgo(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'Just now';
    try {
      final DateTime postDate = DateTime.parse(timestamp);
      final Duration diff = DateTime.now().difference(postDate);

      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min';
      if (diff.inHours < 24) {
        return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'}';
      }
      if (diff.inDays < 7) {
        return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'}';
      }
      return '${postDate.day}/${postDate.month}/${postDate.year}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _recordView(String postId) async {
    try {
      final mobile = await _getMobile();
      if (mobile.isEmpty) return;
      await http.post(
        Uri.parse('https://team.cropsync.in/cine_circle/feed_actions_api.php'),
        body: {
          'action': 'view_post',
          'mobile_number': mobile,
          'post_id': postId,
        },
      );
    } catch (_) {}
  }

  Future<void> _toggleLikeForPost(int index) async {
    final post = _posts[index];
    final postId = post['id']?.toString() ?? '';
    if (postId.isEmpty) return;
    final isLiked =
        post['is_liked'] == 1 ||
        post['is_liked'] == true ||
        post['is_liked'] == '1';

    setState(() {
      _posts[index]['is_liked'] = !isLiked;
      final current = int.tryParse(post['likes_count']?.toString() ?? '0') ?? 0;
      _posts[index]['likes_count'] = isLiked ? current - 1 : current + 1;
    });

    try {
      final mobile = await _getMobile();
      await http.post(
        Uri.parse('https://team.cropsync.in/cine_circle/feed_actions_api.php'),
        body: {
          'action': 'like_post',
          'mobile_number': mobile,
          'post_id': postId,
        },
      );
    } catch (_) {}
  }

  Future<void> _toggleSaveForPost(int index) async {
    final post = _posts[index];
    final postId = post['id']?.toString() ?? '';
    if (postId.isEmpty) return;
    final isSaved =
        post['is_saved'] == 1 ||
        post['is_saved'] == true ||
        post['is_saved'] == '1';

    setState(() {
      _posts[index]['is_saved'] = !isSaved;
    });

    try {
      final mobile = await _getMobile();
      await http.post(
        Uri.parse('https://team.cropsync.in/cine_circle/feed_actions_api.php'),
        body: {
          'action': 'save_post',
          'mobile_number': mobile,
          'post_id': postId,
        },
      );
    } catch (_) {}
  }

  void _showCommentsBottomSheet(String postId, int postIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CommentsSheet(
        postId: postId,
        onCommentAdded: () {
          setState(() {
            final currentCount =
                int.tryParse(
                  _posts[postIndex]['comments_count']?.toString() ?? '0',
                ) ??
                0;
            _posts[postIndex]['comments_count'] = (currentCount + 1).toString();
          });
        },
      ),
    );
  }

  void _showLikesBottomSheet(String postId) {
    if (postId.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Likes',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<dynamic>>(
              future: _fetchLikes(postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerListPlaceholder();
                }
                final likes = snapshot.data ?? [];
                if (likes.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No likes yet.',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: ListView.separated(
                    itemCount: likes.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = likes[index];
                      final name = user['full_name'] ?? 'User';
                      final imageUrl = user['profile_image_url'] ?? '';
                      final city = user['city'] ?? '';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl.isEmpty
                              ? Icon(Icons.person, color: Colors.grey.shade500)
                              : null,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Google Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: city.toString().isNotEmpty
                            ? Text(
                                city,
                                style: const TextStyle(
                                  fontFamily: 'Google Sans',
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showViewsBottomSheet(String postId) {
    if (postId.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Viewers',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<dynamic>>(
              future: _fetchViewers(postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerListPlaceholder();
                }
                final viewers = snapshot.data ?? [];
                if (viewers.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No viewers yet.',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: ListView.separated(
                    itemCount: viewers.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final viewer = viewers[index];
                      final name = viewer['full_name'] ?? 'User';
                      final imageUrl = viewer['profile_image_url'] ?? '';
                      final city = viewer['city'] ?? '';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl.isEmpty
                              ? Icon(Icons.person, color: Colors.grey.shade500)
                              : null,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Google Sans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: city.toString().isNotEmpty
                            ? Text(
                                city,
                                style: const TextStyle(
                                  fontFamily: 'Google Sans',
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<dynamic>> _fetchViewers(String postId) async {
    if (_viewersCache.containsKey(postId)) {
      return _viewersCache[postId]!;
    }
    try {
      final mobile = await _getMobile();
      final response = await http.get(
        Uri.parse(
          'https://team.cropsync.in/cine_circle/feed_actions_api.php?action=get_post_viewers&mobile_number=$mobile&post_id=$postId',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final viewers = List<dynamic>.from(data['data'] ?? []);
          _viewersCache[postId] = viewers;
          return viewers;
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<dynamic>> _fetchLikes(String postId) async {
    if (_likesCache.containsKey(postId)) {
      return _likesCache[postId]!;
    }
    try {
      final mobile = await _getMobile();
      final response = await http.get(
        Uri.parse(
          'https://team.cropsync.in/cine_circle/feed_actions_api.php?action=get_post_likes&mobile_number=$mobile&post_id=$postId',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final likes = List<dynamic>.from(data['data'] ?? []);
          _likesCache[postId] = likes;
          return likes;
        }
      }
    } catch (_) {}
    return [];
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
          'Search',
          style: TextStyle(
            fontFamily: 'Google Sans',
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search users and posts...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                  : _users.isEmpty &&
                        _posts.isEmpty &&
                        _searchCtrl.text.trim().isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No results found for "${_searchCtrl.text}"',
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        if (_searchCtrl.text.isEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'New on CineCircle',
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Discover and follow recent members',
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_isLoadingNewUsers)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              ),
                            )
                          else if (_newUsers.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No new users found.',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            )
                          else
                            ..._newUsers.asMap().entries.map((entry) {
                              final u = entry.value;
                              return _buildUserResultTile(
                                u,
                                isNewUser: true,
                                index: entry.key,
                              );
                            }),
                        ],
                        if (_users.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Users',
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._users.asMap().entries.map((entry) {
                            return _buildUserResultTile(
                              entry.value,
                              index: entry.key,
                            );
                          }),
                          const Divider(height: 24),
                        ],
                        if (_posts.isNotEmpty) ...[
                          const Text(
                            'Posts',
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._posts.asMap().entries.map((entry) {
                            final index = entry.key;
                            final post = entry.value as Map<String, dynamic>;
                            final postId = post['id']?.toString() ?? '';
                            return Column(
                              children: [
                                FeedPostItem(
                                  post: post,
                                  timeAgo: _formatTimeAgo(post['created_at']),
                                  onOpenAuthor: () => _openProfile(
                                    post['user_id']?.toString() ?? '',
                                  ),
                                  onShowOptions: () {},
                                  onToggleLike: () => _toggleLikeForPost(index),
                                  onShowLikes: () =>
                                      _showLikesBottomSheet(postId),
                                  onShowComments: () =>
                                      _showCommentsBottomSheet(postId, index),
                                  onShowViews: () =>
                                      _showViewsBottomSheet(postId),
                                  onToggleSave: () => _toggleSaveForPost(index),
                                  onShare: () => _sharePost(post),
                                  onRecordView: postId.isNotEmpty
                                      ? () => _recordView(postId)
                                      : null,
                                  onDoubleTapLike: () =>
                                      _toggleLikeForPost(index),
                                  showOptions: false,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PostDetailScreen(post: post),
                                      ),
                                    ),
                                    child: const Text(
                                      'Open post',
                                      style: TextStyle(
                                        fontFamily: 'Google Sans',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const Divider(height: 24),
                              ],
                            );
                          }),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _sharePost(Map<String, dynamic> post) {
    final postId = post['id']?.toString() ?? '';
    final url = 'https://team.cropsync.in/cine_circle/post/$postId';
    final title = post['title'] ?? 'Check out this post on CineCircle';
    
    // ignore: deprecated_member_use
    Share.share('$title: $url');
  }

  Widget _buildUserResultTile(
    Map<String, dynamic> u, {
    bool isNewUser = false,
    required int index,
  }) {
    final userId = u['id']?.toString() ?? '';
    final isSelf = userId == widget.currentUserId;
    final imageUrl = u['profile_image_url'] ?? '';

    return ValueListenableBuilder<Map<String, bool>>(
      valueListenable: GlobalNotifier.instance.followStates,
      builder: (context, states, _) {
        final isFollowing = states[userId] ?? (u['is_following'] == true);
        return ListTile(
          onTap: () => _openProfile(userId),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipOval(
              child: imageUrl.toString().isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Icon(Icons.person, color: Colors.grey.shade400),
            ),
          ),
          title: Text(
            u['full_name'] ?? 'User',
            style: const TextStyle(
              fontFamily: 'Google Sans',
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            [
              u['role_title'],
              u['city'],
            ].where((v) => v != null && v.toString().isNotEmpty).join(' • '),
            style: TextStyle(
              fontFamily: 'Google Sans',
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          trailing: isSelf
              ? null
              : GestureDetector(
                  onTap: () => _toggleFollow(index, isNewUser: isNewUser),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isFollowing ? Colors.grey.shade100 : Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isFollowing
                            ? Colors.grey.shade300
                            : Colors.black,
                      ),
                    ),
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        color: isFollowing ? Colors.black87 : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Future<void> _toggleFollow(int index, {bool isNewUser = false}) async {
    final list = isNewUser ? _newUsers : _users;
    final user = list[index];
    final userId = user['id'].toString();
    final states = GlobalNotifier.instance.followStates.value;
    final isFollowing = states[userId] ?? (user['is_following'] == true);

    // UI Feedback: Update GlobalNotifier immediately
    GlobalNotifier.instance.updateFollowState(userId, !isFollowing);
    GlobalNotifier.instance.adjustFollowing(isFollowing ? -1 : 1);

    try {
      final mobile = await _getMobile();
      final res = await http.post(
        Uri.parse('https://team.cropsync.in/cine_circle/social_api.php'),
        body: {
          'action': 'toggle_follow',
          'mobile_number': mobile,
          'target_user_id': userId,
        },
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          final next = data['is_following'] == true;
          GlobalNotifier.instance.updateFollowState(userId, next);
        }
      }
    } catch (e) {
      debugPrint('Follow toggle error: $e');
      // Rollback on error
      GlobalNotifier.instance.updateFollowState(userId, isFollowing);
      GlobalNotifier.instance.adjustFollowing(isFollowing ? 1 : -1);
    }
  }
}
