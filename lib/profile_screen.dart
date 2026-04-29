import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'video_player_screen.dart';
import 'edit_profile_screen.dart';
import 'welcome_screen.dart';
import 'social_cine_credits_screen.dart';
import 'followers_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  List<dynamic> _skillsList = [];
  List<dynamic> _creditsList = [];
  List<dynamic> _reelsList = [];
  List<dynamic> _postsList = [];
  List<dynamic> _savedPostsList = [];

  String _userName = 'Loading...';
  String _accountType = 'Loading...';
  String _userPhone = '';
  int _followersCount = 0;
  int _followingCount = 0;
  int _socialBalance = 0;
  bool _isPostsLoading = false;
  bool _isSavedPostsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('user_phone') ?? '';

    if (mobile.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('https://team.cropsync.in/cine_circle/cinecircle_api.php'),
        body: {'action': 'get_profile', 'mobile_number': mobile},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              _profileData = data['profile'];
              _skillsList = data['skills'] ?? [];
              _creditsList = data['credits'] ?? [];
              _reelsList = data['reels'] ?? [];

              _userName =
                  _profileData?['full_name'] ??
                  prefs.getString('user_name') ??
                  'User';
              _accountType =
                  _profileData?['role_title'] ??
                  prefs.getString('account_type') ??
                  'Public';
              _userPhone = mobile;
            });
            // Fetch follow counts after profile data is available (needs id)
            _loadFollowCounts(mobile);
            _loadSocialCredits(mobile);
            _loadUserPosts(mobile);
            _loadSavedPosts(mobile);
          }
          return;
        }
      }
    } catch (e) {
      // Keep basic prefs reading as fallback on network error
    }

    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'User';
        _accountType = prefs.getString('account_type') ?? 'Public';
        _userPhone = mobile;
      });
    }

    // Fetch follow counts from social API
    _loadFollowCounts(mobile);
    _loadSocialCredits(mobile);
    _loadUserPosts(mobile);
    _loadSavedPosts(mobile);
  }

  Future<void> _loadUserPosts(String mobile) async {
    try {
      if (mounted) setState(() => _isPostsLoading = true);
      final targetUserId = _profileData?['id']?.toString() ?? '';
      if (targetUserId.isEmpty) return;
      final response = await http.get(
        Uri.parse(
          'https://team.cropsync.in/cine_circle/social_api.php?action=get_user_posts&mobile_number=$mobile&target_user_id=$targetUserId',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _postsList = data['data'] ?? [];
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isPostsLoading = false);
    }
  }

  Future<void> _loadSavedPosts(String mobile) async {
    try {
      if (mounted) setState(() => _isSavedPostsLoading = true);
      final response = await http.get(
        Uri.parse(
          'https://team.cropsync.in/cine_circle/feed_actions_api.php?action=get_saved_posts&mobile_number=$mobile',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _savedPostsList = data['data'] ?? [];
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSavedPostsLoading = false);
    }
  }

  Future<void> _loadSocialCredits(String mobile) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://team.cropsync.in/cine_circle/social_api.php?action=get_credits&mobile_number=$mobile',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _socialBalance =
                int.tryParse(data['data']?['balance']?.toString() ?? '0') ?? 0;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadFollowCounts(String mobile) async {
    try {
      // We need our own userId ÔÇö get it from profile data
      final myId = _profileData?['id'];
      if (myId == null) return;
      final res = await http.get(
        Uri.parse(
          'https://team.cropsync.in/cine_circle/social_api.php?action=get_follow_state&mobile_number=$mobile&target_user_id=$myId',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _followersCount = data['followers'] ?? 0;
            _followingCount = data['following'] ?? 0;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: Colors.black,
          onRefresh: _loadUserData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                        image:
                            _profileData != null &&
                                _profileData!['profile_image_url'] != null &&
                                _profileData!['profile_image_url'].isNotEmpty
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(
                                  _profileData!['profile_image_url'],
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child:
                          (_profileData == null ||
                              _profileData!['profile_image_url'] == null ||
                              _profileData!['profile_image_url'].isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Left Side
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _userName,
                                        style: const TextStyle(
                                          fontFamily: 'Google Sans',
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified,
                                      color: Colors.black,
                                      size: 16,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _accountType,
                                  style: const TextStyle(
                                    fontFamily: 'Google Sans',
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Right Side
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _profileData?['city']?.isNotEmpty == true
                                        ? _profileData!['city']!
                                        : 'Not specified',
                                    style: TextStyle(
                                      fontFamily: 'Google Sans',
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (_userPhone.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _userPhone,
                                      style: TextStyle(
                                        fontFamily: 'Google Sans',
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Edit Profile Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                      if (result == true) {
                        _loadUserData();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SocialCineCreditsScreen(),
                          ),
                        );
                      },
                      child: _buildStat(
                        '$_socialBalance',
                        'Social Credits',
                        Icons.stars_rounded,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    GestureDetector(
                      onTap: () {
                        if (_profileData?['id'] == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowersScreen(
                              targetUserId: _profileData!['id'].toString(),
                              displayName: _userName,
                              initialTab: 0,
                            ),
                          ),
                        ).then((_) => _loadFollowCounts(_userPhone));
                      },
                      child: _buildStat(
                        '$_followersCount',
                        'Followers',
                        Icons.people_outline,
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    GestureDetector(
                      onTap: () {
                        if (_profileData?['id'] == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowersScreen(
                              targetUserId: _profileData!['id'].toString(),
                              displayName: _userName,
                              initialTab: 1,
                            ),
                          ),
                        ).then((_) => _loadFollowCounts(_userPhone));
                      },
                      child: _buildStat(
                        '$_followingCount',
                        'Following',
                        Icons.person_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 16),
                // About
                const Text(
                  'About',
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _profileData?['bio']?.isNotEmpty == true
                      ? _profileData!['bio']!
                      : 'Write a bit about yourself and your journey.',
                  style: const TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 16),
                // Featured Reel Divider & Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Featured Reel',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.black,
                      ),
                      onPressed: () => _showAddReelBottomSheet(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: _reelsList.isEmpty
                      ? const Center(
                          child: Text(
                            'No featured reels added.',
                            style: TextStyle(fontFamily: 'Google Sans'),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          itemCount: _reelsList.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            return _buildReelCard(_reelsList[index]);
                          },
                        ),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 16),
                // Credits Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Credits',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.black,
                      ),
                      onPressed: () => _showAddCreditBottomSheet(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_creditsList.isEmpty)
                  const Text(
                    'No credits added yet.',
                    style: TextStyle(fontFamily: 'Google Sans'),
                  ),
                ..._creditsList.map((c) {
                  final title = c['project_title'] ?? '';
                  final role = c['role'] ?? '';
                  final year = c['year'] != null ? ' (${c['year']})' : '';
                  return _buildCreditItem('$role - "$title"$year');
                }),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 16),
                // Skills Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Skills',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.black,
                      ),
                      onPressed: () => _showAddSkillBottomSheet(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _skillsList.isEmpty
                    ? const Text(
                        'No skills added yet.',
                        style: TextStyle(fontFamily: 'Google Sans'),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        children: _skillsList
                            .map((s) => _buildSkillChip(s['skill_name'] ?? ''))
                            .toList(),
                      ),
                const SizedBox(height: 24),
                DefaultTabController(
                  length: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TabBar(
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey.shade500,
                        indicatorColor: Colors.black,
                        tabs: const [
                          Tab(text: 'Posts'),
                          Tab(text: 'Saved'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 420,
                        child: TabBarView(
                          children: [
                            _buildPostGrid(
                              posts: _postsList,
                              isLoading: _isPostsLoading,
                              emptyText:
                                  'No posts yet. Your posts will appear here.',
                            ),
                            _buildPostGrid(
                              posts: _savedPostsList,
                              isLoading: _isSavedPostsLoading,
                              emptyText: 'No saved posts yet.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _showLogoutBottomSheet(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddReelBottomSheet() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    File? selectedMedia;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Featured Reel',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickVideo(
                    source: ImageSource.gallery,
                  );
                  if (picked != null) {
                    setModalState(() => selectedMedia = File(picked.path));
                  }
                },
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(
                        Icons.video_library,
                        color: selectedMedia != null
                            ? Colors.black
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedMedia != null
                              ? selectedMedia!.path.split('/').last
                              : 'Select Video',
                          style: TextStyle(
                            color: selectedMedia != null
                                ? Colors.black
                                : Colors.grey.shade600,
                            fontFamily: 'Google Sans',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (selectedMedia == null) return;
                          setModalState(() => isSaving = true);
                          final prefs = await SharedPreferences.getInstance();
                          final mobile = prefs.getString('user_phone') ?? '';
                          try {
                            var request = http.MultipartRequest(
                              'POST',
                              Uri.parse(
                                'https://team.cropsync.in/cine_circle/cinecircle_api.php',
                              ),
                            );
                            request.fields['action'] = 'upload_featured_reel';
                            request.fields['mobile_number'] = mobile;
                            request.fields['title'] = titleController.text;
                            request.fields['description'] = descController.text;
                            request.files.add(
                              await http.MultipartFile.fromPath(
                                'media',
                                selectedMedia!.path,
                              ),
                            );

                            var streamedResponse = await request.send();
                            if (streamedResponse.statusCode == 200) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                _loadUserData();
                              }
                            } else {
                              setModalState(() => isSaving = false);
                            }
                          } catch (e) {
                            setModalState(() => isSaving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Add Reel',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCreditBottomSheet() {
    final titleController = TextEditingController();
    final roleController = TextEditingController();
    final yearController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Credit',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Project Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roleController,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yearController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (titleController.text.isEmpty ||
                              roleController.text.isEmpty) {
                            return;
                          }
                          setModalState(() => isSaving = true);
                          final prefs = await SharedPreferences.getInstance();
                          final mobile = prefs.getString('user_phone') ?? '';
                          try {
                            await http.post(
                              Uri.parse(
                                'https://team.cropsync.in/cine_circle/cinecircle_api.php',
                              ),
                              body: {
                                'action': 'add_credit',
                                'mobile_number': mobile,
                                'project_title': titleController.text,
                                'role': roleController.text,
                                'year': yearController.text,
                              },
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              _loadUserData();
                            }
                          } catch (e) {
                            setModalState(() => isSaving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Add Credit',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSkillBottomSheet() {
    final skillController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Skill',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: skillController,
                decoration: InputDecoration(
                  labelText: 'Skill Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (skillController.text.isEmpty) return;
                          setModalState(() => isSaving = true);
                          final prefs = await SharedPreferences.getInstance();
                          final mobile = prefs.getString('user_phone') ?? '';
                          try {
                            await http.post(
                              Uri.parse(
                                'https://team.cropsync.in/cine_circle/cinecircle_api.php',
                              ),
                              body: {
                                'action': 'add_skill',
                                'mobile_number': mobile,
                                'skill_name': skillController.text,
                              },
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              _loadUserData();
                            }
                          } catch (e) {
                            setModalState(() => isSaving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Add Skill',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String count, String label, IconData icon, {Color? color}) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.black87),
            const SizedBox(width: 6),
            Text(
              count,
              style: const TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Google Sans',
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildReelCard(Map<String, dynamic> reelData) {
    final title = reelData['title'] ?? 'Feature Reel';
    final url = reelData['media_url'] ?? '';

    return GestureDetector(
      onTap: () {
        if (url.isNotEmpty) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (c, a1, a2) =>
                  FullScreenVideoPlayer(videoUrl: url, title: title),
              transitionsBuilder: (c, anim, a2, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        }
      },
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: url.isNotEmpty ? url : title,
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    url.isNotEmpty
                        ? ReelThumbnail(videoUrl: url)
                        : const SizedBox.shrink(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const Positioned(
                      bottom: 8,
                      left: 8,
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.movie_creation, color: Colors.black, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Google Sans',
          fontSize: 13,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPostGrid({
    required List<dynamic> posts,
    required bool isLoading,
    required String emptyText,
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
      );
    }

    if (posts.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Google Sans',
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index] as Map<String, dynamic>;
        final mediaUrl = (post['media_url'] ?? '').toString();
        final hasMedia = mediaUrl.isNotEmpty;
        final isVideo = post['media_type'] == 'video';
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: hasMedia
                        ? isVideo
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Container(color: Colors.black12),
                                    const Center(
                                      child: Icon(
                                        Icons.play_circle_fill,
                                        size: 54,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : CachedNetworkImage(
                                  imageUrl: mediaUrl,
                                  fit: BoxFit.cover,
                                )
                        : const Center(
                            child: Icon(
                              Icons.article_outlined,
                              size: 42,
                              color: Colors.black45,
                            ),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (post['title'] ?? '').toString().isNotEmpty
                          ? post['title'].toString()
                          : (post['description'] ?? '').toString().isNotEmpty
                          ? post['description'].toString()
                          : 'Untitled post',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${post['likes_count'] ?? 0} likes · ${post['comments_count'] ?? 0} comments',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 48), // starry
              const SizedBox(height: 16),
              const Text(
                'Log Out',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to log out of CineCircle?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Google Sans',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const WelcomeScreen(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        }
                      },
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
                          color: Colors.white,
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
        );
      },
    );
  }
}

class ReelThumbnail extends StatefulWidget {
  final String videoUrl;
  const ReelThumbnail({super.key, required this.videoUrl});

  @override
  State<ReelThumbnail> createState() => _ReelThumbnailState();
}

class _ReelThumbnailState extends State<ReelThumbnail> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _initialized = true;
              });
            }
          })
          .catchError((e) {
            // Ignored, thumbnail just remains grey wrapper
          });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _controller == null) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white24,
            strokeWidth: 2,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
