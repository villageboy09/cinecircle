import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_screen.dart';

const _socialApiPub = 'https://team.cropsync.in/cine_circle/social_api.php';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  bool _isFollowing = false;
  bool _isTogglingFollow = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<String> _getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone') ?? '';
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final mobile = await _getMobile();
      final res = await http.get(Uri.parse(
        '$_socialApiPub?action=get_user_profile&mobile_number=$mobile&target_user_id=${widget.userId}',
      ));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _profile     = data['data'];
            _isFollowing = data['data']['is_following'] == true;
          });
        }
      }
    } catch (e) {
      debugPrint('fetchProfile error: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggleFollow() async {
    if (_isTogglingFollow) return;
    setState(() => _isTogglingFollow = true);
    try {
      final mobile = await _getMobile();
      final res = await http.post(Uri.parse(_socialApiPub), body: {
        'action': 'toggle_follow',
        'mobile_number': mobile,
        'target_user_id': widget.userId,
      });
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _isFollowing = data['is_following'] == true;
            if (_profile != null) {
              _profile!['followers'] = data['followers'];
            }
          });
        }
      }
    } catch (e) {
      debugPrint('toggleFollow error: $e');
    }
    setState(() => _isTogglingFollow = false);
  }

  Future<void> _openChat() async {
    try {
      final mobile = await _getMobile();
      final res = await http.post(Uri.parse(_socialApiPub), body: {
        'action': 'start_conversation',
        'mobile_number': mobile,
        'recipient_id': widget.userId,
      });
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success' && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversationId: data['conversation_id'],
                recipientId: widget.userId,
                recipientName: _profile?['full_name'] ?? '',
                recipientRole: _profile?['role_title'] ?? '',
                recipientAvatar: _profile?['profile_image_url'] ?? '',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('openChat error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
          : _profile == null
              ? const Center(child: Text('Profile not found', style: TextStyle(fontFamily: 'Google Sans')))
              : _buildProfile(),
    );
  }

  Widget _buildProfile() {
    final p = _profile!;
    final bool hasImg  = (p['profile_image_url'] ?? '').isNotEmpty;
    final List skills  = p['skills'] ?? [];
    final List credits = p['credits'] ?? [];
    final List reels   = p['reels'] ?? [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // — Header —
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  image: hasImg
                      ? DecorationImage(image: NetworkImage(p['profile_image_url']), fit: BoxFit.cover)
                      : null,
                ),
                child: hasImg ? null : const Icon(Icons.person, size: 40, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(p['full_name'] ?? '',
                              style: const TextStyle(fontFamily: 'Google Sans', fontSize: 20, fontWeight: FontWeight.w600),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (p['follows_you'] == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                            child: const Text('Follows you', style: TextStyle(fontFamily: 'Google Sans', fontSize: 11, color: Colors.black54)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(p['role_title'] ?? '', style: const TextStyle(fontFamily: 'Google Sans', fontSize: 14, color: Colors.black54)),
                    if ((p['city'] ?? '').isNotEmpty)
                      Row(children: [
                        Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text(p['city'], style: TextStyle(fontFamily: 'Google Sans', fontSize: 12, color: Colors.grey.shade500)),
                      ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // — Action Buttons —
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _isTogglingFollow ? null : _toggleFollow,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isFollowing ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _isFollowing ? Colors.grey.shade300 : Colors.black),
                    ),
                    alignment: Alignment.center,
                    child: _isTogglingFollow
                        ? SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2,
                                color: _isFollowing ? Colors.black : Colors.white))
                        : Text(_isFollowing ? 'Following ✓' : 'Follow',
                            style: TextStyle(fontFamily: 'Google Sans', fontWeight: FontWeight.w600, fontSize: 15,
                                color: _isFollowing ? Colors.black : Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _openChat,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 16),
                        SizedBox(width: 6),
                        Text('Message', style: TextStyle(fontFamily: 'Google Sans', fontWeight: FontWeight.w600, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // — Stats —
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('${p['followers'] ?? 0}', 'Followers'),
              Container(height: 36, width: 1, color: Colors.grey.shade300),
              _buildStat('${p['following'] ?? 0}', 'Following'),
              Container(height: 36, width: 1, color: Colors.grey.shade300),
              _buildStat('${credits.length}', 'Credits'),
            ],
          ),
          Divider(height: 32, color: Colors.grey.shade200),
          // — Bio —
          if ((p['bio'] ?? '').isNotEmpty) ...[
            const Text('About', style: TextStyle(fontFamily: 'Google Sans', fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(p['bio'], style: const TextStyle(fontFamily: 'Google Sans', fontSize: 15, color: Colors.black87, height: 1.5)),
            Divider(height: 32, color: Colors.grey.shade200),
          ],
          // — Skills —
          if (skills.isNotEmpty) ...[
            const Text('Skills', style: TextStyle(fontFamily: 'Google Sans', fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: skills.map<Widget>((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(s.toString(), style: const TextStyle(fontFamily: 'Google Sans', fontSize: 13)),
              )).toList(),
            ),
            Divider(height: 32, color: Colors.grey.shade200),
          ],
          // — Credits —
          if (credits.isNotEmpty) ...[
            const Text('Credits', style: TextStyle(fontFamily: 'Google Sans', fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...credits.map<Widget>((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                const Icon(Icons.radio_button_checked, size: 8, color: Colors.black45),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  '${c['role']} — "${c['project_title']}"${c['year'] != null ? ' (${c['year']})' : ''}',
                  style: const TextStyle(fontFamily: 'Google Sans', fontSize: 14, color: Colors.black87),
                )),
              ]),
            )),
            Divider(height: 32, color: Colors.grey.shade200),
          ],
          // — Reels —
          if (reels.isNotEmpty) ...[
            const Text('Featured Reels', style: TextStyle(fontFamily: 'Google Sans', fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: reels.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final r = reels[i];
                  final hasThumbnail = (r['thumbnail_url'] ?? '').isNotEmpty;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        image: hasThumbnail
                            ? DecorationImage(image: NetworkImage(r['thumbnail_url']), fit: BoxFit.cover)
                            : null,
                      ),
                      alignment: Alignment.bottomLeft,
                      padding: const EdgeInsets.all(8),
                      child: Text(r['title'] ?? '',
                          style: TextStyle(fontFamily: 'Google Sans', fontSize: 12, fontWeight: FontWeight.w600,
                              color: hasThumbnail ? Colors.white : Colors.black87),
                          maxLines: 2),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildStat(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontFamily: 'Google Sans', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontFamily: 'Google Sans', fontSize: 13, color: Colors.grey.shade600)),
      ],
    );
  }
}
