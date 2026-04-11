import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final Map<String, dynamic> contact;

  const ChatScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['name'] ?? 'Sarah Chen',
                    style: const TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    contact['role'] ?? 'Cinematographer',
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
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
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                _buildMessageBubble(
                  'Hey Alex, just reviewing the casting tapes. The final two for the lead are excellent.',
                  isMe: false,
                ),
                _buildMessageBubble(
                  'Hi Sarah, sure. I\'ll be free in 10.',
                  isMe: true,
                ),
                _buildMessageBubble(
                  'Do you have a moment to chat about their availability?',
                  isMe: false,
                ),
                _buildMessageBubble(
                  'I\'m leaning towards the second candidate.',
                  isMe: false,
                ),
                _buildMessageBubble(
                  'Did you notice their distinct styles?',
                  isMe: true,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          fontFamily: 'Google Sans',
                          color: Colors.grey.shade500,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.send,
                  color: Colors.black,
                  size: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, {required bool isMe}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isMe ? Colors.white : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: Radius.circular(isMe ? 24 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 24),
          ),
          border: isMe ? Border.all(color: Colors.black, width: 2) : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Google Sans',
            fontSize: 15,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
