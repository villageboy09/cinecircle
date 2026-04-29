import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<dynamic> _posts = [];
  List<dynamic> _trending = [];
  List<dynamic> _nearby = [];
  String? _currentUserId;
  String? _userProfileImage;

  // FAB Scroll Logic
  late ScrollController _scrollController;
  bool _showFab = true;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _fetchHomeFeed();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final delta = _scrollController.offset - _lastOffset;
    // Only toggle FAB when scroll delta is significant (reduces rebuilds)
    if (delta > 5 && _showFab && _scrollController.offset > 50) {
      setState(() => _showFab = false);
    } else if (delta < -5 && !_showFab) {
      setState(() => _showFab = true);
    }
    _lastOffset = _scrollController.offset;
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userProfileImage = prefs.getString('user_image');
    });
  }

  Future<void> _fetchHomeFeed() async {
    // Only show skeleton loading if we don't have any posts yet
    if (_posts.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';

      final response = await http.get(
        Uri.parse(
          'https://team.cropsync.in/cine_circle/homefeed_api.php?mobile_number=$mobile',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _currentUserId = data['data']['current_user_id']?.toString();
            _posts = data['data']['posts'] ?? [];
            _trending = data['data']['trending'] ?? [];
            _nearby = data['data']['nearby'] ?? [];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error $e');
    }
    setState(() => _isLoading = false);
  }

  String _formatTimeAgo(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'Now';
    try {
      final date = DateTime.parse(timestamp);
      final difference = DateTime.now().difference(date);
      if (difference.inDays > 0) return '${difference.inDays}d';
      if (difference.inHours > 0) return '${difference.inHours}h';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m';
      return 'Now';
    } catch (e) {
      return '';
    }
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  savedState
                      ? 'Post saved to bookmarks'
                      : 'Post removed from bookmarks',
                  style: const TextStyle(fontFamily: 'Google Sans'),
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        } else {
          // Revert on failure
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

  void _showCommentsBottomSheet(String postId, int postIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CommentsSheet(
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
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePostSheet(),
    );
    if (result == true) {
      _fetchHomeFeed();
    }
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  bool _canEditPost(dynamic createdAt) {
    if (createdAt == null) return false;
    try {
      final created = DateTime.parse(createdAt.toString()).toLocal();
      return DateTime.now().difference(created).inMinutes <= 15;
    } catch (_) {
      return false;
    }
  }

  void _sharePost(Map<String, dynamic> post) {
    final title = (post['title'] ?? '').toString().trim();
    final description = (post['description'] ?? '').toString().trim();
    final postId = post['id']?.toString() ?? '';
    final shareText = [
      if (title.isNotEmpty) title,
      if (description.isNotEmpty) description,
      if (postId.isNotEmpty) 'Post ID: $postId',
    ].join('\n\n');

    Clipboard.setData(ClipboardData(text: shareText));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Post copied to clipboard')));
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Trending Talent',
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Nearby Creators',
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
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

    return Scaffold(
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF0F0F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRect(
                        child: Container(
                          height: 40,
                          width: 140, // Adjust width as necessary
                          alignment: Alignment.center,
                          child: Transform.scale(
                            scale: 2.2, // Scaling up to crop empty white space
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
                          Icons.notifications_none,
                          color: Colors.black,
                          size: 26,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ActivityScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex =
                                5; // Index for Profile (Matches ProfileScreen position in IndexedStack)
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            image:
                                _userProfileImage != null &&
                                    _userProfileImage!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(_userProfileImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _userProfileImage == null
                              ? const Icon(Icons.person, size: 20)
                              : null,
                        ),
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
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: EdgeInsets.zero,
                            itemCount: combinedFeed.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              thickness: 0.5,
                              color: Colors.grey.shade200,
                            ),
                            itemBuilder: (context, index) =>
                                combinedFeed[index],
                          ),
                        ),
                ),
              ],
            ),
          ),
          // Trivia Tab (Index 1)
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
        currentIndex: _selectedIndex > 4
            ? 0
            : _selectedIndex, // Reset if Profile is selected via AppBar
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Trivia',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
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
    );
  }

  Widget _buildFeedItem(int index, Map<String, dynamic> post, {Key? key}) {
    final String postId = post['id']?.toString() ?? '';
    final String fullName = post['author_name'] ?? 'User';
    final String profileImg = post['profile_image_url'] ?? '';
    final String category = post['category'] ?? 'Update';
    final String title = post['title'] ?? '';
    final String description = post['description'] ?? '';
    final String timeAgo = _formatTimeAgo(post['created_at']);

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

    // Record view fire-and-forget (only once per postId per session)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (postId.isNotEmpty) _recordView(postId);
    });

    return Container(
      key: key,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _openAuthorProfile(post),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: profileImg.isNotEmpty
                        ? NetworkImage(profileImg)
                        : null,
                    child: profileImg.isEmpty
                        ? Icon(Icons.person, color: Colors.grey.shade500)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openAuthorProfile(post),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz, color: Colors.grey.shade600),
                  onPressed: () => _showPostOptions(post),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Category and Title context
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Description text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              description,
              style: const TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
          if ((post['media_url'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onDoubleTap: () => _toggleLike(index),
              child: Container(
                width: double.infinity,
                color: Colors.grey.shade100,
                child: post['media_type'] == 'image'
                    ? AspectRatio(
                        aspectRatio: 4 / 5,
                        child: Image.network(
                          post['media_url'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : post['media_type'] == 'video'
                    ? FeedVideoPlayer(videoUrl: post['media_url'])
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(index),
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 26,
                        color: isLiked ? Colors.red : Colors.black87,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        likesCount,
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _showCommentsBottomSheet(postId, index),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 24,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        commentsCount,
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Views count
                Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 22,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      viewsCount,
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Bookmark / Save button
                GestureDetector(
                  onTap: () => _toggleSave(index),
                  child: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    size: 26,
                    color: isSaved ? Colors.black : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(Map<String, dynamic> user) {
    return FollowCard(
      userId: user['id']?.toString() ?? '',
      name: user['full_name'] ?? 'User',
      role: user['role_title'] ?? 'Member',
      location: user['city'] ?? '',
      imageUrl: user['profile_image_url'],
      cardType: CardType.trending,
      initialIsFollowing: user['is_following'] == true,
    );
  }

  Widget _buildNearbyCard(Map<String, dynamic> user) {
    return FollowCard(
      userId: user['id']?.toString() ?? '',
      name: user['full_name'] ?? 'User',
      role: user['role_title'] ?? 'Member',
      location: user['city'] ?? '',
      imageUrl: user['profile_image_url'],
      cardType: CardType.nearby,
      initialIsFollowing: user['is_following'] == true,
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

// ──────────────────────────────────────────────
// Standalone Comments Bottom Sheet Widget
// ──────────────────────────────────────────────
class _CommentsSheet extends StatefulWidget {
  final String postId;
  final VoidCallback onCommentAdded;

  const _CommentsSheet({required this.postId, required this.onCommentAdded});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
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
    if (timestamp == null || timestamp.isEmpty) return 'Now';
    try {
      final date = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m';
      return 'Now';
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
