import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'job_detail_screen.dart';

const _jobsApiBase = 'https://team.cropsync.in/cine_circle/jobs_api.php';

const _castingFilters = ['All', 'Casting', 'Crew', 'Services', 'Remote'];
const _dailyFilters   = ['All', 'Lead', 'Supporting', 'Background', 'Child Artist', 'Dancer'];

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab       = 0;
  int _castingFilter     = 0;
  int _dailyFilter       = 0;
  bool _isLoading        = false;
  List<dynamic> _casting = [];
  List<dynamic> _daily   = [];
  final TextEditingController _searchCtrl = TextEditingController();
  late final PageController _pageCtrl = PageController();

  @override
  void initState() {
    super.initState();
    _fetchCasting();
    _fetchDaily();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<String> _getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone') ?? '';
  }

  Future<void> _fetchCasting({String search = ''}) async {
    setState(() => _isLoading = true);
    try {
      final mobile = await _getMobile();
      final filter = _castingFilter == 0 ? '' : _castingFilters[_castingFilter];
      final res = await http.get(Uri.parse(
        '$_jobsApiBase?action=get_casting_jobs&mobile_number=$mobile&job_type=${Uri.encodeComponent(filter)}&search=${Uri.encodeComponent(search)}',
      ));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') setState(() => _casting = data['data'] ?? []);
      }
    } catch (e) {
      debugPrint('fetchCasting error: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchDaily({String search = ''}) async {
    setState(() => _isLoading = true);
    try {
      final mobile = await _getMobile();
      final filter = _dailyFilter == 0 ? '' : _dailyFilters[_dailyFilter];
      final res = await http.get(Uri.parse(
        '$_jobsApiBase?action=get_daily_posts&mobile_number=$mobile&role_type=${Uri.encodeComponent(filter)}&search=${Uri.encodeComponent(search)}',
      ));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') setState(() => _daily = data['data'] ?? []);
      }
    } catch (e) {
      debugPrint('fetchDaily error: $e');
    }
    setState(() => _isLoading = false);
  }

  void _switchTab(int index) {
    if (index == _selectedTab) return;
    setState(() => _selectedTab = index);
    _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _openDetail(Map<String, dynamic> job, String jobType) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, _) => JobDetailScreen(
          jobId: job['id'].toString(),
          jobType: jobType,
          onApplied: () {
            if (jobType == 'casting') {
              _fetchCasting();
            } else {
              _fetchDaily();
            }
          },
        ),
        transitionsBuilder: (_, anim, _, child) {
          final slide = Tween<Offset>(
            begin: const Offset(1.0, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
          return SlideTransition(position: slide, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

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
                  _buildToggleTab('Casting', 0),
                  _buildToggleTab('Daily Short', 1),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(), // only toggle controls it
              onPageChanged: (i) => setState(() => _selectedTab = i),
              children: [
                RefreshIndicator(
                  color: Colors.black,
                  onRefresh: _fetchCasting,
                  child: _buildCastingView(),
                ),
                RefreshIndicator(
                  color: Colors.black,
                  onRefresh: _fetchDaily,
                  child: _buildDailyView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontFamily: 'Google Sans',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isSelected ? Colors.white : Colors.black87,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  // ─── CASTING TAB ─────────────────────────────────────────
  Widget _buildCastingView() {
    return SingleChildScrollView(
      key: const ValueKey('casting'),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Jobs',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Google Sans',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Find your next film role',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Google Sans', fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          // Search bar — grey filled, matches Daily's clean look
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.black, fontFamily: 'Google Sans', fontSize: 14),
                onSubmitted: (v) => _fetchCasting(search: v),
                decoration: InputDecoration(
                  hintText: 'Search jobs...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'Google Sans', fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade500, size: 18),
                          onPressed: () { _searchCtrl.clear(); setState(() {}); _fetchCasting(); },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: _castingFilters.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () { setState(() => _castingFilter = e.key); _fetchCasting(); },
                  child: _buildFilterPill(e.value, e.key == _castingFilter),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading && _casting.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
            )
          else if (_casting.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(children: [
                Icon(Icons.work_outline, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No jobs found.', style: TextStyle(fontFamily: 'Google Sans', color: Colors.grey.shade500)),
              ]),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _casting.length,
              itemBuilder: (_, i) => _buildJobCard(_casting[i], 'casting'),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── DAILY SHORT TAB ─────────────────────────────────────
  Widget _buildDailyView() {
    return SingleChildScrollView(
      key: const ValueKey('daily'),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Daily Actor Needs',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Google Sans',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Quick gigs posted daily',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Google Sans', fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          // Filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: _dailyFilters.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () { setState(() => _dailyFilter = e.key); _fetchDaily(); },
                  child: _buildFilterPill(e.value, e.key == _dailyFilter),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading && _daily.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
            )
          else if (_daily.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(children: [
                Icon(Icons.movie_creation_outlined, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No gigs found.', style: TextStyle(fontFamily: 'Google Sans', color: Colors.grey.shade500)),
              ]),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _daily.length,
              itemBuilder: (_, i) => _buildJobCard(_daily[i], 'daily'),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── SHARED CARD ─────────────────────────────────────────
  Widget _buildJobCard(Map<String, dynamic> job, String jobType) {
    final bool hasApplied = job['has_applied'] == true;
    final bool hasImage   = job['image_url'] != null && (job['image_url'] as String).isNotEmpty;

    // Build meta line from available fields
    final List<String?> metaParts = jobType == 'casting'
        ? [job['company'], job['pay_type'], job['location'], job['time_ago']]
        : [job['role_type'], job['project_type'], job['shoot_date'], job['pay_per_day'], job['location']];
    final meta = metaParts.where((e) => e != null && e.toString().isNotEmpty).join(' | ');

    return GestureDetector(
      onTap: () => _openDetail(job, jobType),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional banner
            if (hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Image.network(
                  job['image_url'],
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // URGENT badge
                  if (job['is_urgent'] == true) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('URGENT',
                          style: TextStyle(fontFamily: 'Google Sans', fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    job['title'] ?? '',
                    style: const TextStyle(fontFamily: 'Google Sans', fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                  const SizedBox(height: 6),
                  Text(meta, style: TextStyle(fontFamily: 'Google Sans', fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: hasApplied ? null : () => _openDetail(job, jobType),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: hasApplied ? Colors.grey.shade100 : Colors.black,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: hasApplied ? Colors.grey.shade300 : Colors.black),
                      ),
                      child: Text(
                        hasApplied ? 'Applied ✓' : 'Apply Now',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          color: hasApplied ? Colors.grey.shade500 : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Google Sans',
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
