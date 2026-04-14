import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_screen.dart';

const _socialApi = 'https://team.cropsync.in/cine_circle/social_api.php';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _isLoading = true;
  List<dynamic> _conversations = [];
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _filtered = [];

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<String> _getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone') ?? '';
  }

  Future<void> _fetchConversations() async {
    setState(() => _isLoading = true);
    try {
      final mobile = await _getMobile();
      final res = await http.get(Uri.parse(
        '$_socialApi?action=get_conversations&mobile_number=$mobile',
      ));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _conversations = data['data'] ?? [];
            _filtered = _conversations;
          });
        }
      }
    } catch (e) {
      debugPrint('fetchConversations error: $e');
    }
    setState(() => _isLoading = false);
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _conversations
          : _conversations.where((c) =>
              (c['full_name'] ?? '').toString().toLowerCase().contains(q) ||
              (c['last_message'] ?? '').toString().toLowerCase().contains(q)
            ).toList();
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
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('Messages',
                  style: TextStyle(fontFamily: 'Google Sans', fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontFamily: 'Google Sans'),
                  decoration: InputDecoration(
                    hintText: 'Search conversations',
                    hintStyle: TextStyle(fontFamily: 'Google Sans', color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : _filtered.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: Colors.black,
                          onRefresh: _fetchConversations,
                          child: ListView.separated(
                            itemCount: _filtered.length,
                            separatorBuilder: (_, _) => Divider(color: Colors.grey.shade200, height: 1, indent: 96),
                            itemBuilder: (_, i) => _buildConvTile(_filtered[i]),
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
          Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No messages yet', style: TextStyle(fontFamily: 'Google Sans', color: Colors.grey.shade500, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Follow someone and start a conversation', style: TextStyle(fontFamily: 'Google Sans', color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildConvTile(Map<String, dynamic> chat) {
    final int unread = chat['unread_count'] ?? 0;
    final bool hasUnread = unread > 0;
    final bool hasAvatar = chat['profile_image_url'] != null && (chat['profile_image_url'] as String).isNotEmpty;

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: chat['conversation_id'].toString(),
              recipientId: chat['other_user_id'].toString(),
              recipientName: chat['full_name'] ?? '',
              recipientRole: chat['role_title'] ?? '',
              recipientAvatar: chat['profile_image_url'] ?? '',
            ),
          ),
        );
        _fetchConversations(); // Refresh unread counts on return
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
                image: hasAvatar
                    ? DecorationImage(image: NetworkImage(chat['profile_image_url']), fit: BoxFit.cover)
                    : null,
              ),
              child: hasAvatar ? null : const Icon(Icons.person, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(chat['full_name'] ?? '',
                          style: TextStyle(fontFamily: 'Google Sans', fontSize: 16,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500, color: Colors.black)),
                      Text(chat['time_ago'] ?? '',
                          style: TextStyle(fontFamily: 'Google Sans', fontSize: 13,
                              color: hasUnread ? Colors.black87 : Colors.grey.shade600,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(chat['role_title'] ?? '',
                          style: const TextStyle(fontFamily: 'Google Sans', fontSize: 14, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(chat['last_message'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: 'Google Sans', fontSize: 14,
                                color: hasUnread ? Colors.black : Colors.grey.shade700,
                                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal)),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                          child: Text('$unread',
                              style: const TextStyle(fontFamily: 'Google Sans', color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                    ],
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
