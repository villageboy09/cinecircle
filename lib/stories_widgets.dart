import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'post_story_screen.dart';
import 'story_viewer_screen.dart';

class StoriesBar extends StatefulWidget {
  final String? currentUserId;
  final Function(Map<String, dynamic> userStories)? onStoryTap;

  const StoriesBar({super.key, this.currentUserId, this.onStoryTap});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  List<dynamic> _usersWithStories = [];
  Map<String, dynamic>? _myStories;

  @override
  void initState() {
    super.initState();
    _fetchStories();
  }

  @override
  void didUpdateWidget(StoriesBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUserId != widget.currentUserId) {
      _fetchStories();
    }
  }

  Future<void> _fetchStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      
      final response = await http.get(
        Uri.parse('https://team.cropsync.in/cine_circle/stories_api.php?action=get_active_stories&mobile_number=$mobile'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              final List<dynamic> allUsers = data['data'] ?? [];
              _myStories = null;
              
              // Filter out "me" from the list and store separately
              _usersWithStories = allUsers.where((u) {
                if (u['user_id']?.toString() == widget.currentUserId?.toString()) {
                  _myStories = u;
                  return false;
                }
                return true;
              }).toList();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching stories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: _usersWithStories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddStoryButton();
          }
          
          final user = _usersWithStories[index - 1];
          return _buildStoryAvatar(user);
        },
      ),
    );
  }

  Widget _buildAddStoryButton() {
    final bool hasStories = _myStories != null;
    final bool hasUnviewed = _myStories?['has_unviewed'] == true;

    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          GestureDetector(
            onTap: () async {
              if (hasStories) {
                widget.onStoryTap?.call(_myStories!);
              } else {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PostStoryScreen()),
                );
                if (result == true) {
                  _fetchStories();
                }
              }
            },
            child: Container(
              width: 65,
              height: 65,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnviewed 
                  ? const LinearGradient(
                      colors: [Colors.purple, Colors.orange, Colors.yellow],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    )
                  : (hasStories ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade300]) : null),
                color: hasStories ? null : Colors.transparent,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: hasStories ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                    child: ClipOval(
                      child: _myStories?['profile_image_url'] != null
                        ? CachedNetworkImage(
                            imageUrl: _myStories!['profile_image_url'],
                            fit: BoxFit.cover,
                            width: 65,
                            height: 65,
                          )
                        : Container(
                            width: 65,
                            height: 65,
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.person, color: Colors.grey, size: 30),
                          ),
                    ),
                  ),
                  if (!hasStories)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 14),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PostStoryScreen()),
                          );
                          if (result == true) {
                            _fetchStories();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Your Story',
            style: TextStyle(fontSize: 11, fontFamily: 'Google Sans'),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryAvatar(Map<String, dynamic> user) {
    final bool hasUnviewed = user['has_unviewed'] == true;
    
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: GestureDetector(
        onTap: () => widget.onStoryTap?.call(user),
        child: Column(
          children: [
            Container(
              width: 65,
              height: 65,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnviewed 
                  ? const LinearGradient(
                      colors: [Colors.purple, Colors.orange, Colors.yellow],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade300, Colors.grey.shade300],
                    ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: user['profile_image_url'] ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.shade100),
                    errorWidget: (context, url, error) => const Icon(Icons.person),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 70,
              child: Text(
                user['full_name'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontFamily: 'Google Sans'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserAvatarWithStory extends StatelessWidget {
  final String userId;
  final String profileImageUrl;
  final double radius;
  final bool hasStories;
  final bool hasUnviewed;
  final VoidCallback? onTap;

  const UserAvatarWithStory({
    super.key,
    required this.userId,
    required this.profileImageUrl,
    this.radius = 20,
    this.hasStories = false,
    this.hasUnviewed = false,
    this.onTap,
  });

  Future<void> _handleTap(BuildContext context) async {
    if (onTap != null) {
      onTap!();
      return;
    }

    if (!hasStories) return;

    // Fetch full story data for this user
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      
      final response = await http.get(
        Uri.parse('https://team.cropsync.in/cine_circle/stories_api.php?action=get_user_stories&mobile_number=$mobile&user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && context.mounted) {
          final userStories = data['data'];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryViewerScreen(
                userStories: userStories,
                currentUserId: prefs.getString('user_id'),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching user stories on tap: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        width: radius * 2 + 10,
        height: radius * 2 + 10,
        padding: EdgeInsets.all(hasStories ? 3 : 0),
        decoration: hasStories ? BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasUnviewed 
            ? const LinearGradient(
                colors: [Colors.purple, Colors.orange, Colors.yellow],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              )
            : LinearGradient(
                colors: [Colors.grey.shade300, Colors.grey.shade300],
              ),
        ) : null,
        child: Container(
          padding: EdgeInsets.all(hasStories ? 2 : 0),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundImage: profileImageUrl.isNotEmpty 
              ? CachedNetworkImageProvider(profileImageUrl)
              : null,
            child: profileImageUrl.isEmpty ? const Icon(Icons.person) : null,
          ),
        ),
      ),
    );
  }
}
