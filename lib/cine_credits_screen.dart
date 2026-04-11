import 'package:flutter/material.dart';
import 'redeem_rewards_screen.dart';

class CineCreditsScreen extends StatelessWidget {
  const CineCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Image.asset(
          'assets/cinelogo.png',
          height: 32,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            const Text(
              'Cine-Credits',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 28,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '2,450 Cine-Credits',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Total Balance',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Earning Summary',
                    icon: Icons.arrow_upward,
                    rows: {
                      'Review Rewards:': '1,200',
                      'Quiz Wins:': '800',
                      'Engagement:': '450',
                    },
                    totalLabel: 'Total Earned:',
                    totalValue: '2,450',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Redemption Summary',
                    icon: Icons.arrow_downward,
                    rows: {
                      'Ticket Redemptions:': '',
                      'Early-Access:': '-500',
                      'Unlocks:': '-150',
                    },
                    totalLabel: 'Total Redeemed:',
                    totalValue: '-650',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Divider(color: Colors.grey.shade300, height: 1),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Transactions',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildTransactionItem(
              icon: Icons.movie_filter,
              title: 'Review Reward: \'The Silent Sea\'',
              subtitle: 'Today',
              amount: '+500',
              isPositive: true,
            ),
            _buildTransactionItem(
              icon: Icons.quiz,
              title: 'Quiz Win: Film Noir Knowledge',
              subtitle: 'Yesterday',
              amount: '+300',
              isPositive: true,
            ),
            _buildTransactionItem(
              icon: Icons.local_activity,
              title: 'Ticket Redemption: \'Dune Part Two\'',
              subtitle: 'Oct 20',
              amount: '-250',
              isPositive: false,
            ),
            _buildTransactionItem(
              icon: Icons.lock_open,
              title: 'Early-Access Unlock: \'Festival Pass\'',
              subtitle: 'Oct 15',
              amount: '-150',
              isPositive: false,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RedeemRewardsScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Redeem Credits',
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Earn More',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required IconData icon,
    required Map<String, String> rows,
    required String totalLabel,
    required String totalValue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...rows.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    entry.value,
                    style: const TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                totalLabel,
                style: const TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
              Text(
                totalValue,
                style: const TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required bool isPositive,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: Colors.black54),
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            amount,
            style: const TextStyle(
              fontFamily: 'Google Sans',
              fontSize: 15,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
