import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _socialApiChat = 'https://team.cropsync.in/cine_circle/social_api.php';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String recipientId;
  final String recipientName;
  final String recipientRole;
  final String recipientAvatar;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.recipientId,
    required this.recipientName,
    required this.recipientRole,
    required this.recipientAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<String> _getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone') ?? '';
  }

  Future<void> _fetchMessages() async {
    setState(() => _isLoading = true);
    try {
      final mobile = await _getMobile();
      final res = await http.get(Uri.parse(
        '$_socialApiChat?action=get_messages&mobile_number=$mobile&conversation_id=${widget.conversationId}',
      ));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          setState(() => _messages = data['data'] ?? []);
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('fetchMessages error: $e');
    }
    setState(() => _isLoading = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    _msgCtrl.clear();
    setState(() {
      _isSending = true;
      // Optimistic: add immediately so UX is instant
      _messages.add({
        'body': text,
        'is_me': true,
        'sent_at': DateTime.now().toIso8601String(),
        'time_ago': 'Just now',
        'is_read': false,
      });
    });
    _scrollToBottom();

    try {
      final mobile = await _getMobile();
      await http.post(
        Uri.parse(_socialApiChat),
        body: {
          'action': 'send_message',
          'mobile_number': mobile,
          'recipient_id': widget.recipientId,
          'body': text,
        },
      );
    } catch (e) {
      debugPrint('sendMessage error: $e');
    }
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAvatar = widget.recipientAvatar.isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
                image: hasAvatar
                    ? DecorationImage(image: NetworkImage(widget.recipientAvatar), fit: BoxFit.cover)
                    : null,
              ),
              child: hasAvatar ? null : const Icon(Icons.person, color: Colors.grey, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.recipientName,
                      style: const TextStyle(fontFamily: 'Google Sans', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                  Text(widget.recipientRole,
                      style: TextStyle(fontFamily: 'Google Sans', fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Divider(color: Colors.grey.shade200, height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : _messages.isEmpty
                    ? Center(
                        child: Text('Say hello! 👋', style: TextStyle(fontFamily: 'Google Sans', color: Colors.grey.shade500, fontSize: 16)),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _buildBubble(_messages[i]),
                      ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _msgCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontFamily: 'Google Sans'),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(fontFamily: 'Google Sans', color: Colors.grey.shade500, fontSize: 15),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44, height: 44,
                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final bool isMe = msg['is_me'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? Colors.black : Colors.grey.shade100,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
            ),
            child: Text(msg['body'] ?? '',
                style: TextStyle(fontFamily: 'Google Sans', fontSize: 15, color: isMe ? Colors.white : Colors.black87, height: 1.4)),
          ),
          const SizedBox(height: 4),
          Text(msg['time_ago'] ?? '',
              style: TextStyle(fontFamily: 'Google Sans', fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
