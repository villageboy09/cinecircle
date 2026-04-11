import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'discover_screen.dart';
import 'jobs_screen.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';
import 'trivia_screen.dart';
import 'rentals_screen.dart';
import 'activity_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchHomeFeed();
  }

  Future<void> _fetchHomeFeed() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      
      final response = await http.get(Uri.parse('https://team.cropsync.in/cine_circle/homefeed_api.php?mobile_number=$mobile'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
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
    final isLiked = post['is_liked'] == 1 || post['is_liked'] == true || post['is_liked'] == '1';
    
    setState(() {
      _posts[index]['is_liked'] = !isLiked;
      _posts[index]['likes_count'] = isLiked ? (int.parse(post['likes_count'].toString()) - 1) : (int.parse(post['likes_count'].toString()) + 1);
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

  void _showCommentsBottomSheet(String postId) {
    // For now simple alert dialog bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("Comments", style: TextStyle(fontFamily: 'Google Sans', fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Expanded(child: Center(child: Text("Coming Soon..."))),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: () {}),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> feedItems = _posts.asMap().entries.map((entry) {
      int index = entry.key;
      var post = entry.value;
      return _buildFeedItem(index, post);
    }).toList();

    final trendingTalentModule = _trending.isNotEmpty ? Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Trending Talent',
              style: TextStyle(fontFamily: 'Google Sans', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 290,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: _trending.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _buildTrendingCard(t['full_name'] ?? 'User', t['role_title'] ?? 'Member', t['city'] ?? '', 'Follow', t['profile_image_url']),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    ) : const SizedBox.shrink();

    final nearbyCreatorsModule = _nearby.isNotEmpty ? Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Nearby Creators',
              style: TextStyle(fontFamily: 'Google Sans', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
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
              children: _nearby.map((n) => _buildNearbyCard(n['full_name'] ?? 'User', n['role_title'] ?? 'Member', n['city'] ?? '', n['profile_image_url'])).toList(),
            ),
          ),
        ],
      ),
    ) : const SizedBox.shrink();

    final List<Widget> combinedFeed = [];
    if (feedItems.isNotEmpty) {
      combinedFeed.add(feedItems[0]);
    } else {
       combinedFeed.add(const SizedBox(height: 100, child: Center(child: Text("No posts found", style: TextStyle(fontFamily: 'Google Sans')))));
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
                      bottom: BorderSide(
                        color: Color(0xFFF0F0F0),
                      ),
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
                        icon: const Icon(Icons.explore_outlined, color: Colors.black, size: 26),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const DiscoverScreen()));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.black, size: 26),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const MessagesScreen()));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.black, size: 26),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityScreen()));
                        },
                      ),
                    ],
                  ),
                ),
                // List
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
                    : RefreshIndicator(
                        color: Colors.black,
                        onRefresh: _fetchHomeFeed,
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: combinedFeed.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) => combinedFeed[index],
                        ),
                      ),
                ),
              ],
            ),
          ),
          // Trivia Tab (Index 1)
          const TriviaScreen(),
          // Jobs Tab (Index 2)
          const JobsScreen(),
          // Rentals Tab (Index 3)
          const RentalsScreen(),
          // Profile Tab (Index 4)
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
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
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_center_outlined),
            activeIcon: Icon(Icons.business_center),
            label: 'Rentals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildFeedItem(int index, Map<String, dynamic> post) {
    final String postId = post['id'].toString();
    final bool isLiked = post['is_liked'] == 1 || post['is_liked'] == true || post['is_liked'] == '1';
    final String likesCount = post['likes_count']?.toString() ?? '0';
    final String commentsCount = post['comments_count']?.toString() ?? '0';
    final bool isVideo = post['media_type'] == 'video';
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: post['profile_image_url'] != null ? NetworkImage(post['profile_image_url']) : null,
                  child: post['profile_image_url'] == null ? Icon(Icons.person, color: Colors.grey.shade500) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['author_name'] ?? 'User',
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        _formatTimeAgo(post['created_at']),
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_horiz, color: Colors.grey.shade600),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    post['category'] ?? 'Update',
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
                    post['title'] ?? '',
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
              post['description'] ?? '',
              style: const TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Media Placeholder linked to Double Tap
          GestureDetector(
            onDoubleTap: () => _toggleLike(index),
            child: Container(
              width: double.infinity,
              height: 220,
              color: Colors.grey.shade100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (post['media_url'] != null && post['media_type'] == 'image') 
                     Image.network(post['media_url'], fit: BoxFit.cover, width: double.infinity)
                  else
                     Icon(isVideo ? Icons.videocam_outlined : Icons.image_outlined, color: Colors.grey.shade300, size: 64),
                  if (isVideo)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(index),
                  child: Row(
                    children: [
                      Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 26, color: isLiked ? Colors.red : Colors.black87),
                      const SizedBox(width: 6),
                      Text(likesCount, style: const TextStyle(fontFamily: 'Google Sans', fontWeight: FontWeight.w600)),
                    ]
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _showCommentsBottomSheet(postId),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 24, color: Colors.black87),
                      const SizedBox(width: 6),
                      Text(commentsCount, style: const TextStyle(fontFamily: 'Google Sans', fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: const Icon(Icons.reply, size: 26, color: Colors.black87),
                ),
                const Spacer(),
                const Icon(Icons.bookmark_border, size: 26, color: Colors.black87),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(String name, String role, String location, String buttonText, String? imageUrl) {
    return Container(
      width: 180, // Substantially wider
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 80, // Much larger icon container
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
              image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
            ),
            child: imageUrl == null ? Icon(Icons.person, color: Colors.grey.shade400, size: 40) : null,
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                role,
                style: const TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 12,
                  color: Color(0xFF616161),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                location,
                style: const TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 13,
                  color: Color(0xFF9E9E9E),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: buttonText == 'Follow' ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: buttonText == 'Follow' ? null : Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              buttonText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Google Sans',
                color: buttonText == 'Follow' ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyCard(String name, String role, String location, String? imageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
            ),
            child: imageUrl == null ? Icon(Icons.person, color: Colors.grey.shade400) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: const TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 11,
                    color: Color(0xFF616161),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    location,
                    style: const TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
