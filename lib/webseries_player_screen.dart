import 'package:flutter/material.dart';

class WebseriesPlayerScreen extends StatelessWidget {
  final String seriesTitle;
  final int episodeNumber;

  const WebseriesPlayerScreen({
    super.key,
    required this.seriesTitle,
    required this.episodeNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video Background Placeholder
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A), // Dark slate placeholder color
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white24,
                  size: 80,
                ),
              ),
            ),

            // Top Gradient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Bottom Gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Header Elements
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Image.asset(
                            'assets/cinelogo.png',
                            height: 24,
                            fit: BoxFit.contain,
                            color: Colors.white, // Simple tinting for dark mode
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.skip_next,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Next: Episode ${episodeNumber + 1}',
                                style: const TextStyle(
                                  fontFamily: 'Google Sans',
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'auto-plays',
                                style: TextStyle(
                                  fontFamily: 'Google Sans',
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '$seriesTitle • Episode $episodeNumber',
                    style: const TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Right Action Column
            Positioned(
              right: 20,
              bottom: 120, // Sit above the slider
              child: Column(
                children: [
                  _buildActionIcon(Icons.favorite, true), // Liked
                  const SizedBox(height: 24),
                  _buildActionIcon(Icons.chat_bubble_outline, false),
                  const SizedBox(height: 24),
                  _buildActionIcon(
                    Icons.reply,
                    false,
                    rotate: true,
                  ), // Share icon
                  const SizedBox(height: 24),
                  _buildActionIcon(Icons.bookmark_border, false),
                  const SizedBox(height: 24),
                  _buildActionIcon(Icons.more_horiz, false),
                ],
              ),
            ),

            // Bottom Content
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Things get weird in the common room.',
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#${seriesTitle.replaceAll(' ', '')} #Webseries',
                    style: const TextStyle(
                      fontFamily: 'Google Sans',
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Seek bar
                      Expanded(
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: 0.5,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const Positioned(
                              left: 170, // Approximating 50% for visual
                              child: CircleAvatar(
                                radius: 6,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        '50%',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Pagination dots and scale
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      _buildDot(false),
                      _buildDot(true), // Assuming page 2 layout matches visual
                      _buildDot(false),
                      _buildDot(false),
                      _buildDot(false),
                      _buildDot(false),
                      _buildDot(false),
                      _buildDot(false),
                      const Spacer(),
                      const Text(
                        '3/10',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          color: Colors.white54,
                          fontSize: 12,
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
  }

  Widget _buildActionIcon(IconData icon, bool isActive, {bool rotate = false}) {
    return Transform(
      alignment: Alignment.center,
      transform: rotate ? Matrix4.rotationY(3.14159) : Matrix4.identity(),
      child: Icon(
        icon,
        color: isActive ? Colors.white : Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 6 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}
