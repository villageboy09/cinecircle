import 'package:flutter/material.dart';

class RedeemRewardsScreen extends StatelessWidget {
  const RedeemRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/cinelogo.png', height: 24, fit: BoxFit.contain),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.copyright, size: 16, color: Colors.black87),
                const SizedBox(width: 4),
                const Text(
                  '3,240 Credits',
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Text(
                'Redeem Rewards',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            // Custom Tab Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  _buildTab('Merchandise', true),
                  _buildTab('Movie Tickets', false),
                  _buildTab('Event Passes', false),
                  _buildTab('Fan Drops', false),
                  _buildTab('Premium', false),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade50.withValues(alpha: 0.5),
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.3],
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'Use credits on merchandise, movie tickets, and industry events',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildRewardItem(
                      Icons.checkroom,
                      'Official CineCircle Hoodie',
                      '1,500 Credits',
                      'Limited Stock',
                    ),
                    _buildRewardItem(
                      Icons.collections,
                      'Limited Film Poster Set',
                      '1,200 Credits',
                      'Available Now',
                    ),
                    _buildRewardItem(
                      Icons.local_activity,
                      '2 Movie Tickets',
                      '900 Credits',
                      'Valid Nationwide',
                    ),
                    _buildRewardItem(
                      Icons.badge,
                      'Premiere Event Pass',
                      '2,500 Credits',
                      'Coming Soon',
                    ),
                    _buildRewardItem(
                      Icons.ondemand_video,
                      'Masterclass Access',
                      '1,800 Credits',
                      'On-Demand',
                    ),
                    _buildRewardItem(
                      Icons.people,
                      'Festival Networking Pass',
                      '2,000 Credits',
                      'Limited Availability',
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 20),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Google Sans',
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.black : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildRewardItem(
    IconData icon,
    String title,
    String cost,
    String subtitle,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: Colors.black87),
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
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$cost • $subtitle',
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Redeem',
              style: TextStyle(
                fontFamily: 'Google Sans',
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
