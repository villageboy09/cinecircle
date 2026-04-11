import 'package:flutter/material.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> conversations = [
      {
        'name': 'Sofia Coppola',
        'role': 'Director',
        'time': '2h ago',
        'snippet': 'Last message about the script draft...',
        'unread': 2,
      },
      {
        'name': 'Casting Team, \'The Lighthouse\'',
        'role': 'Casting',
        'time': '5h ago',
        'snippet': 'Audition tapes received.',
        'unread': 0,
      },
      {
        'name': 'John Smith',
        'role': 'Cinematographer',
        'time': 'Yesterday',
        'snippet': 'Lighting plan for tomorrow\'s shoot.',
        'unread': 0,
      },
      {
        'name': 'Emily Chen',
        'role': 'Producer',
        'time': '1d ago',
        'snippet': 'Budget update. Please review.',
        'unread': 1,
      },
      {
        'name': 'David Lynch',
        'role': 'Collaborator',
        'time': '2d ago',
        'snippet': 'Interesting concept. Let\'s discuss.',
        'unread': 0,
      },
    ];

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
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Messages',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search conversations',
                    hintStyle: TextStyle(
                      fontFamily: 'Google Sans',
                      color: Colors.grey.shade500,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: conversations.length,
                separatorBuilder: (context, index) =>
                    Divider(color: Colors.grey.shade200, height: 1, indent: 96),
                itemBuilder: (context, index) {
                  final chat = conversations[index];
                  final bool hasUnread = chat['unread'] > 0;

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(contact: chat),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      chat['name'],
                                      style: TextStyle(
                                        fontFamily: 'Google Sans',
                                        fontSize: 16,
                                        fontWeight: hasUnread
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      chat['time'],
                                      style: TextStyle(
                                        fontFamily: 'Google Sans',
                                        fontSize: 13,
                                        color: hasUnread
                                            ? Colors.black87
                                            : Colors.grey.shade600,
                                        fontWeight: hasUnread
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            chat['role'],
                                            style: const TextStyle(
                                              fontFamily: 'Google Sans',
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            chat['snippet'],
                                            style: TextStyle(
                                              fontFamily: 'Google Sans',
                                              fontSize: 14,
                                              color: hasUnread
                                                  ? Colors.black
                                                  : Colors.grey.shade700,
                                              fontWeight: hasUnread
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (hasUnread)
                                      Container(
                                        margin: const EdgeInsets.only(top: 8.0),
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${chat['unread']}',
                                          style: const TextStyle(
                                            fontFamily: 'Google Sans',
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
