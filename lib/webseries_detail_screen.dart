import 'package:flutter/material.dart';
import 'webseries_player_screen.dart';

class WebseriesDetailScreen extends StatelessWidget {
  final Map<String, String> series;

  const WebseriesDetailScreen({super.key, required this.series});

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
          height: 28,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.black, size: 26),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Top Header Details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Series Cover Placeholder
                    Container(
                      width: 140,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          series['title']!.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Google Sans',
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Series Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            series['title']!,
                            style: const TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildGenrePill(series['genre']!),
                              const SizedBox(width: 8),
                              _buildGenrePill('Campus'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'A group of students uncover dark secrets during their overnight stay.',
                            style: TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _navigateToPlayer(context, 1);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 24),
                        label: const Text(
                          'Play From Episode 1',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Custom Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTabTitle('About', false),
                    _buildTabTitle('Episodes', true),
                    _buildTabTitle('Cast', false),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              // Episodes List
              const SizedBox(height: 8),
              _buildEpisodeItem(context, 1, 'The Arrival', '1m 20s', 1.0, '100%'),
              _buildEpisodeItem(context, 2, 'Whispers in the Hall', '2m 10s', 0.75, '75%'),
              _buildEpisodeItem(context, 3, 'Room 303', '1m 45s', 0.50, '50%'),
              _buildEpisodeItem(context, 4, 'The First Clue', '2m 05s', 0.25, '25%'),
              _buildEpisodeItem(context, 5, 'Missing Person', '1m 55s', 0.0, '0%'),
              _buildEpisodeItem(context, 6, 'The Chase', '2m 30s', 0.0, '0%'),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenrePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Google Sans',
          fontSize: 13,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTabTitle(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
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
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.black : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildEpisodeItem(BuildContext context, int epNumber, String title, String time, double progress, String progressLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Episode $epNumber: $title',
                  style: const TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      progressLabel,
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          InkWell(
            onTap: () => _navigateToPlayer(context, epNumber),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Play',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPlayer(BuildContext context, int epNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebseriesPlayerScreen(
          seriesTitle: series['title']!,
          episodeNumber: epNumber,
        ),
      ),
    );
  }
}
