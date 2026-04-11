import 'package:flutter/material.dart';
import 'webseries_detail_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final webseries = [
      {
        'title': 'Midnight Hostel',
        'genre': 'Thriller',
        'episodes': '8 Episodes',
        'duration': '12 min',
      },
      {
        'title': 'City Loop',
        'genre': 'Drama',
        'episodes': '10 Episodes',
        'duration': '15 min',
      },
      {
        'title': 'Before Packup',
        'genre': 'Comedy',
        'episodes': '6 Episodes',
        'duration': '10 min',
      },
      {
        'title': 'Reel Hearts',
        'genre': 'Romance',
        'episodes': '12 Episodes',
        'duration': '18 min',
      },
      {
        'title': 'Casting Call',
        'genre': 'Satire',
        'episodes': '5 Episodes',
        'duration': '8 min',
      },
      {
        'title': 'Take Two',
        'genre': 'Documentary',
        'episodes': '4 Episodes',
        'duration': '20 min',
      },
    ];

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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'All Webseries',
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
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search webseries...',
                      hintStyle: TextStyle(
                        fontFamily: 'Google Sans',
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    _buildFilterPill('All', isSelected: true),
                    const SizedBox(width: 8),
                    _buildFilterPill('Ongoing'),
                    const SizedBox(width: 8),
                    _buildFilterPill('Completed'),
                    const SizedBox(width: 8),
                    _buildFilterPill('Most Watched'),
                    const SizedBox(width: 8),
                    _buildFilterPill('New'),
                    const SizedBox(width: 8),
                    _buildFilterPill('Shorts'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Webseries Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: webseries.length,
                  itemBuilder: (context, index) {
                    final item = webseries[index];
                    return _buildWebseriesCard(context, item);
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String title, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Google Sans',
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildWebseriesCard(BuildContext context, Map<String, String> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Left Placeholder
          Container(
            width: 70, // Narrow rect to fit nicely inside the grid cell
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                bottomLeft: Radius.circular(11),
              ),
            ),
          ),
          // Right Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['title']!,
                    style: const TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['genre']!,
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['episodes']!,
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['duration']!,
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WebseriesDetailScreen(series: item),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'View Show',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
