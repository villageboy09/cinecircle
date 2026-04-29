import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _socialApiActivity =
    'https://team.cropsync.in/cine_circle/social_api.php';

const _filters = ['All', 'Network', 'Jobs', 'Screening Room', 'Trivia'];

// Map type → icon
const _notifIcons = {
  'follow': Icons.person_add_alt_1,
  'profile_view': Icons.visibility_outlined,
  'message': Icons.chat_bubble_outline,
  'post_like': Icons.favorite_border,
  'post_comment': Icons.comment_outlined,
  'job_match': Icons.work_outline,
  'job_application': Icons.assignment_turned_in_outlined,
  'daily_quiz': Icons.quiz_outlined,
  'reward_redeemed': Icons.card_giftcard_outlined,
  'system': Icons.info_outline,
};

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  int _filterIndex = 0;
  String? _userProfileImage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _userProfileImage = prefs.getString('user_image'));
  }

  Future<String> _getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone') ?? '';
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final mobile = await _getMobile();
      final filter = _filterIndex == 0 ? '' : _filters[_filterIndex];
      final res = await http.get(
        Uri.parse(
          '$_socialApiActivity?action=get_notifications&mobile_number=$mobile&type=${Uri.encodeComponent(filter)}',
        ),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _notifications = data['data'] ?? [];
            _unreadCount = data['unread_count'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('fetchNotifications error: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _markAllRead() async {
    try {
      final mobile = await _getMobile();
      await http.post(
        Uri.parse(_socialApiActivity),
        body: {'action': 'mark_notifications_read', 'mobile_number': mobile},
      );
      setState(() {
        for (var n in _notifications) {
          n['is_read'] = true;
        }
        _unreadCount = 0;
      });
    } catch (e) {
      debugPrint('markAllRead error: $e');
    }
  }

  Future<void> _markOneRead(String id) async {
    try {
      final mobile = await _getMobile();
      await http.post(
        Uri.parse(_socialApiActivity),
        body: {
          'action': 'mark_notifications_read',
          'mobile_number': mobile,
          'notification_id': id,
        },
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  color: Colors.black,
                  fontSize: 13,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1),
                image:
                    _userProfileImage != null && _userProfileImage!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_userProfileImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _userProfileImage == null
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  const Text(
                    'Activity',
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_unreadCount',
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Filter pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: _filters
                    .asMap()
                    .entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _filterIndex = e.key);
                            _fetchNotifications();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: e.key == _filterIndex
                                  ? Colors.black
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: e.key == _filterIndex
                                    ? Colors.black
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontFamily: 'Google Sans',
                                fontSize: 13,
                                color: e.key == _filterIndex
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: e.key == _filterIndex
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : _notifications.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: Colors.black,
                      onRefresh: _fetchNotifications,
                      child: ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (_, i) =>
                            _buildNotifItem(_notifications[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No activity yet',
            style: TextStyle(
              fontFamily: 'Google Sans',
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifItem(Map<String, dynamic> notif) {
    final bool isRead = notif['is_read'] == true;
    final icon = _notifIcons[notif['type']] ?? Icons.notifications_none;
    final bool hasAvatar =
        notif['actor_avatar'] != null &&
        (notif['actor_avatar'] as String).isNotEmpty;

    return InkWell(
      onTap: () {
        if (!isRead) {
          _markOneRead(notif['id'].toString());
          setState(() => notif['is_read'] = true);
          if (_unreadCount > 0) setState(() => _unreadCount--);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isRead ? Colors.white : Colors.grey.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar or icon circle
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                    image: hasAvatar
                        ? DecorationImage(
                            image: NetworkImage(notif['actor_avatar']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: hasAvatar
                      ? null
                      : Icon(icon, color: Colors.black54, size: 22),
                ),
                if (!isRead)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif['title'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  if (notif['body'] != null &&
                      (notif['body'] as String).isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      notif['body'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    notif['time_ago'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
