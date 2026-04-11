import 'package:flutter/material.dart';
import 'cine_credits_screen.dart';
import 'daily_quiz_screen.dart';

class TriviaScreen extends StatelessWidget {
  const TriviaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Logo + Credits
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/cinelogo.png',
                  height: 32,
                  fit: BoxFit.contain,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CineCreditsScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.copyright, size: 16, color: Colors.black),
                        SizedBox(width: 6),
                        Text(
                          'Credits: 240',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Title Sections
            const Center(
              child: Text(
                'Trivia Challenge',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Play quick rounds and collect credits',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Divider(color: Colors.grey.shade300, height: 1),
            const SizedBox(height: 32),
            // Category Cards
            _buildCategoryCard('Movies', 'Estimated credits: +10', Icons.movie_filter),
            const SizedBox(height: 16),
            _buildCategoryCard('Directors', 'Estimated credits: +15', Icons.chair_alt), // chair for director
            const SizedBox(height: 16),
            _buildCategoryCard('Awards', 'Estimated credits: +20', Icons.emoji_events),
            const SizedBox(height: 32),
            // Bonus Trivia Block
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today\'s Bonus Trivia',
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Test your knowledge on recent blockbusters and earn double credits!',
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DailyQuizScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Start Trivia',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Divider(color: Colors.grey.shade300, height: 1),
            const SizedBox(height: 24),
            // Recent Rewards
            const Text(
              'Recent Rewards',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRewardPill('Daily Login (+5)'),
                  const SizedBox(width: 8),
                  _buildRewardPill('Film Noir Quiz (+15)'),
                  const SizedBox(width: 8),
                  _buildRewardPill('Director Spotlight (+10)'),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black87, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Google Sans',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }
}
