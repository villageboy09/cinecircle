import 'package:flutter/material.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Activity',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  _buildFilterPill('All', true),
                  const SizedBox(width: 8),
                  _buildFilterPill('Jobs', false),
                  const SizedBox(width: 8),
                  _buildFilterPill('Network', false),
                  const SizedBox(width: 8),
                  _buildFilterPill('Screening Room', false),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildActivityItem(
                    icon: Icons.person,
                    title: '3 people viewed your profile.',
                    time: '2h ago',
                  ),
                  _buildActivityItem(
                    icon: Icons.person_add_alt_1,
                    title: 'Mark Johnson sent you a connection request.',
                    time: '4h ago',
                  ),
                  _buildActivityItem(
                    icon: Icons.work_outline,
                    title: 'New jobs match your saved search \'Cinematographer\'.',
                    time: '5h ago',
                  ),
                  _buildActivityItem(
                    icon: Icons.videocam_outlined,
                    title: 'Urgent Casting Call for \'Sunrise Project\'.',
                    time: '1d ago',
                  ),
                  _buildActivityItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'Sarah Lee commented on your \'Short Film Draft\'.',
                    time: '1d ago',
                  ),
                  _buildActivityItem(
                    icon: Icons.verified_user_outlined,
                    title: 'Your professional profile has been verified.',
                    time: '2d ago',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey.shade200 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Google Sans',
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildActivityItem({required IconData icon, required String title, required String time}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black54, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 15,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
