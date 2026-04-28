import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'public_profile_screen.dart';

const _socialApi = 'https://team.cropsync.in/cine_circle/social_api.php';

/// Shows the followers OR following list for any [targetUserId].
/// Pass [initialTab] = 0 for Followers, 1 for Following.
class FollowersScreen extends StatefulWidget {
  final String targetUserId;
  final String displayName; // e.g. "Arjun"
  final int initialTab;     // 0 = Followers, 1 = Following

  const FollowersScreen({
    super.key,
    required this.targetUserId,
    required this.displayName,
    this.initialTab = 0,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.displayName,
          style: const TextStyle(
            fontFamily: 'Google Sans',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: Colors.black,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
            fontFamily: 'Google Sans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Google Sans',
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UserListTab(
            targetUserId: widget.targetUserId,
            mode: 'followers',
          ),
          _UserListTab(
            targetUserId: widget.targetUserId,
            mode: 'following',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Reusable paginated list for followers / following
// ─────────────────────────────────────────────
class _UserListTab extends StatefulWidget {
  final String targetUserId;
  final String mode; // 'followers' | 'following'

  const _UserListTab({
    required this.targetUserId,
    required this.mode,
  });

  @override
  State<_UserListTab> createState() => _UserListTabState();
}

class _UserListTabState extends State<_UserListTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _myMobile;
  String? _myUserId;   // ← logged-in user's ID to hide self follow button
  late ScrollController _scrollCtrl;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()..addListener(_onScroll);
    _init();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _myMobile = prefs.getString('user_phone') ?? '';
    await _fetchPage(1);
  }

  Future<void> _fetchPage(int page) async {
    if (page == 1) setState(() => _isLoading = true);
    try {
      final action =
          widget.mode == 'followers' ? 'get_followers' : 'get_following';
      final uri = Uri.parse(
        '$_socialApi?action=$action'
        '&mobile_number=${Uri.encodeComponent(_myMobile ?? '')}'
        '&target_user_id=${widget.targetUserId}'
        '&page=$page',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          final List<dynamic> raw = data['data'] ?? [];
          final rows = raw.cast<Map<String, dynamic>>();
          final String serverMyId = data['my_user_id']?.toString() ?? '';
          if (mounted) {
            setState(() {
              if (page == 1) {
                _users = rows;
              } else {
                _users.addAll(rows);
              }
              _hasMore = rows.length == 30;
              _page = page;
              if (serverMyId.isNotEmpty) _myUserId = serverMyId;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('fetchPage error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    await _fetchPage(_page + 1);
    if (mounted) setState(() => _isLoadingMore = false);
  }

  Future<void> _toggleFollow(int index) async {
    final user = _users[index];
    final wasFollowing = user['is_following'] == true;

    setState(() {
      _users[index] = {...user, 'is_following': !wasFollowing};
    });

    try {
      final res = await http.post(Uri.parse(_socialApi), body: {
        'action': 'toggle_follow',
        'mobile_number': _myMobile ?? '',
        'target_user_id': user['id'].toString(),
      });
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _users[index] = {
              ..._users[index],
              'is_following': data['is_following'] == true,
            };
          });
        } else {
          if (mounted) {
            setState(() => _users[index] = {
              ...user,
              'is_following': wasFollowing,
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _users[index] = {
          ...user,
          'is_following': wasFollowing,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.mode == 'followers'
                  ? Icons.people_outline
                  : Icons.person_add_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              widget.mode == 'followers'
                  ? 'No followers yet'
                  : 'Not following anyone yet',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.mode == 'followers'
                  ? 'When people follow this account,\nthey\'ll appear here.'
                  : 'When this account follows people,\nthey\'ll appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 14,
                color: Colors.grey.shade400,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.black,
      onRefresh: () => _fetchPage(1),
      child: ListView.builder(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _users.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _users.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                ),
              ),
            );
          }
          return _buildUserTile(index);
        },
      ),
    );
  }

  Widget _buildUserTile(int index) {
    final u = _users[index];
    final String userId = u['id']?.toString() ?? '';
    final String name = u['full_name'] ?? 'User';
    final String role = u['role_title'] ?? '';
    final String city = u['city'] ?? '';
    final String? imageUrl =
        (u['profile_image_url']?.toString() ?? '').isNotEmpty
            ? u['profile_image_url'].toString()
            : null;
    final bool isFollowing = u['is_following'] == true;
    final bool followsMe = u['follows_you'] == true;

    return InkWell(
      onTap: () {
        if (userId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PublicProfileScreen(userId: userId),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null
                  ? Icon(Icons.person, size: 28, color: Colors.grey.shade500)
                  : null,
            ),
            const SizedBox(width: 12),
            // Name / role / city
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (followsMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Follows you',
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (role.isNotEmpty)
                    Text(
                      role,
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (city.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 2),
                        Text(
                          city,
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Hide follow button for self
            if (userId != _myUserId)
              GestureDetector(
                onTap: () => _toggleFollow(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFollowing ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isFollowing ? Colors.grey.shade300 : Colors.black,
                    ),
                  ),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isFollowing ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
