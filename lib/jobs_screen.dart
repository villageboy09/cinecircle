import 'package:flutter/material.dart';
import 'job_detail_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  int _selectedTab = 0; // 0 = Casting, 1 = Daily Short

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Segmented Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? Colors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Casting',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontWeight: FontWeight.w600,
                            color: _selectedTab == 0 ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? Colors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Daily Short',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontWeight: FontWeight.w600,
                            color: _selectedTab == 1 ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Content
          Expanded(
            child: _selectedTab == 0 ? _buildCastingView() : _buildDailyView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCastingView() {
    final jobs = [
      {
        'title': 'Lead Actor for Indie Feature',
        'company': 'Moonlight Productions',
        'location': 'Los Angeles, CA',
        'type': 'Paid - Union',
        'time': '2d ago',
        'buttonText': 'Apply',
      },
      {
        'title': 'Cinematographer Needed',
        'company': 'Visionary Films',
        'location': 'New York, NY',
        'type': 'Paid - Non-Union',
        'time': '1d ago',
        'buttonText': 'View',
      },
      {
        'title': 'Post-Production Editor',
        'company': 'Creative Cut Studios',
        'location': 'Remote',
        'type': 'Contract',
        'time': '3d ago',
        'buttonText': 'Apply',
      },
      {
        'title': 'Production Assistant',
        'company': 'On-Set Productions',
        'location': 'Atlanta, GA',
        'type': 'Entry Level',
        'time': '5h ago',
        'buttonText': 'View',
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: const Text(
              'Jobs',
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
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontFamily: 'Google Sans'),
                decoration: InputDecoration(
                  hintText: 'Search jobs...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'Google Sans'),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                _buildFilterPill('Casting', true),
                const SizedBox(width: 8),
                _buildFilterPill('Crew', false),
                const SizedBox(width: 8),
                _buildFilterPill('Services', false),
                const SizedBox(width: 8),
                _buildFilterPill('Remote', false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade300, height: 1),
          // Job list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: jobs.length,
            separatorBuilder: (context, index) => Divider(color: Colors.grey.shade300, height: 1),
            itemBuilder: (context, index) {
              final job = jobs[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobDetailScreen(job: job),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['title']!,
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job['company']!,
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        job['location']!,
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        job['type']!,
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            job['time']!,
                            style: const TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              job['buttonText']!,
                              style: const TextStyle(
                                fontFamily: 'Google Sans',
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDailyView() {
    final dailyOpportunities = [
      {
        'title': 'Need 2 supporting actors for short film',
        'role': 'Supporting',
        'type': 'Short Film',
        'date': 'Oct 26, 2024',
        'pay': '₹5000/day',
        'location': 'Mumbai',
      },
      {
        'title': 'Female lead required for ad shoot',
        'tag': 'URGENT',
        'role': 'Lead',
        'type': 'Ad Shoot',
        'date': 'Oct 27-28, 2024',
        'pay': '₹15000/day',
        'location': 'Delhi',
      },
      {
        'title': 'Background artists needed tomorrow',
        'role': 'Background',
        'type': 'Feature Film',
        'date': 'Oct 25, 2024',
        'pay': '₹2000/day',
        'location': 'Hyderabad',
      },
      {
        'title': 'Daily dancers for music video',
        'role': 'Dancer',
        'type': 'Music Video',
        'date': 'Oct 29, 2024',
        'pay': '₹8000/day',
        'location': 'Bangalore',
      },
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Image.asset(
            'assets/cinelogo.png',
            height: 40,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          const Text(
            'Daily Actor Needs',
            style: TextStyle(
              fontFamily: 'Google Sans',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildFilterPill('All', true),
                const SizedBox(width: 8),
                _buildFilterPill('Lead', false),
                const SizedBox(width: 8),
                _buildFilterPill('Supporting', false),
                const SizedBox(width: 8),
                _buildFilterPill('Background', false),
                const SizedBox(width: 8),
                _buildFilterPill('Child Artist', false),
                const SizedBox(width: 8),
                _buildFilterPill('Dancer', false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: dailyOpportunities.length,
            itemBuilder: (context, index) {
              final opp = dailyOpportunities[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobDetailScreen(job: {
                        'title': opp['title'],
                        'company': 'Independent Project',
                        'location': opp['location'],
                        'time': 'Just now',
                        'type': opp['type'],
                      }),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (opp['tag'] != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            opp['tag']!,
                            style: const TextStyle(
                              fontFamily: 'Google Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        opp['title']!,
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${opp['role']} | ${opp['type']} | ${opp['date']} | ${opp['pay']} | ${opp['location']}',
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Apply Now',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? Border.all(color: Colors.black) : Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Google Sans',
          color: isSelected ? Colors.white : Colors.black,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
