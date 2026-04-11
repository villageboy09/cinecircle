import 'package:flutter/material.dart';

class JobDetailScreen extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobDetailScreen({super.key, required this.job});

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job['title'] ?? 'Lead Cinematographer',
              style: const TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${job['company'] ?? 'CineCircle Productions'} • ${job['location'] ?? 'Los Angeles, CA'}',
              style: const TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${job['type'] ?? 'Contract'} • Posted ${job['time'] ?? '2 days ago'}',
              style: const TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'We are seeking a visionary Lead Cinematographer to define the visual language for an upcoming indie feature. This role requires deep creative collaboration and technical mastery.',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 15,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Requirements',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('5+ years experience in feature films'),
            _buildBulletPoint('Strong portfolio of narrative work'),
            _buildBulletPoint('Proficient with ARRI and RED cameras'),
            _buildBulletPoint('Excellent communication and leadership skills'),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Responsibilities',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Collaborate with director on visual style'),
            _buildBulletPoint('Lead camera and lighting teams'),
            _buildBulletPoint('Create shot lists and lighting plans'),
            _buildBulletPoint('Ensure high-quality image capture'),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Submission materials',
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Resume/CV'),
            _buildBulletPoint('Cover letter'),
            _buildBulletPoint('Link to online portfolio/reel'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Now',
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.favorite, color: Colors.black),
                label: const Text(
                  'Save Job',
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(fontSize: 18, height: 1.2, color: Colors.black),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
