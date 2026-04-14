import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'cine_credits_screen.dart';
import 'daily_quiz_screen.dart';

const _apiBase = 'https://team.cropsync.in/cine_circle/trivia_api.php';

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  bool _isLoading = true;
  int _creditBalance = 0;
  List<dynamic> _categories = [];
  List<dynamic> _challenges = [];
  List<dynamic> _recentHistory = [];

  // Maps flutter icon name strings to IconData
  static const _iconMap = {
    'movie_filter': Icons.movie_filter,
    'chair_alt': Icons.chair_alt,
    'emoji_events': Icons.emoji_events,
    'star': Icons.star,
    'music_note': Icons.music_note,
    'camera_alt': Icons.camera_alt,
    'local_movies': Icons.local_movies,
    'people': Icons.people,
  };

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<String> _getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone') ?? '';
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final mobile = await _getMobile();
    await Future.wait([
      _fetchCredits(mobile),
      _fetchCategories(mobile),
      _fetchChallenges(mobile),
      _claimDailyLogin(mobile),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchCredits(String mobile) async {
    try {
      final res = await http.get(
        Uri.parse('$_apiBase?action=get_credits&mobile_number=$mobile'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _creditBalance = data['data']['balance'] ?? 0;
            _recentHistory = data['data']['history'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('fetchCredits error: $e');
    }
  }

  Future<void> _fetchCategories(String mobile) async {
    try {
      final res = await http.get(
        Uri.parse('$_apiBase?action=get_categories&mobile_number=$mobile'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          setState(() => _categories = data['data'] ?? []);
        }
      }
    } catch (e) {
      debugPrint('fetchCategories error: $e');
    }
  }

  Future<void> _fetchChallenges(String mobile) async {
    try {
      final res = await http.get(
        Uri.parse('$_apiBase?action=get_challenges&mobile_number=$mobile'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          setState(() => _challenges = data['data'] ?? []);
        }
      }
    } catch (e) {
      debugPrint('fetchChallenges error: $e');
    }
  }

  Future<void> _claimDailyLogin(String mobile) async {
    try {
      await http.post(
        Uri.parse(_apiBase),
        body: {'action': 'daily_login_reward', 'mobile_number': mobile},
      );
    } catch (_) {}
  }

  // Pick the daily bonus challenge (is_daily == true) or first challenge
  Map<String, dynamic>? get _dailyChallenge {
    try {
      return _challenges.firstWhere(
        (c) => c['is_daily'] == 1 || c['is_daily'] == true || c['is_daily'] == '1',
      ) as Map<String, dynamic>;
    } catch (_) {
      return _challenges.isNotEmpty ? _challenges.first as Map<String, dynamic> : null;
    }
  }

  void _openChallenge(Map<String, dynamic> challenge) {
    if (challenge['already_completed'] == 1 || challenge['already_completed'] == true || challenge['already_completed'] == '1') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You\'ve already completed this challenge today!', style: TextStyle(fontFamily: 'Google Sans')),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailyQuizScreen(
          challengeId: challenge['id'],
          challengeTitle: challenge['title'] ?? 'Quiz',
          creditsReward: int.tryParse(challenge['credits_reward'].toString()) ?? 0,
          onCompleted: () => _loadAll(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: Colors.black,
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header: Logo + Credits
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/cinelogo.png', height: 32, fit: BoxFit.contain),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CineCreditsScreen()),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.copyright, size: 16, color: Colors.black),
                          const SizedBox(width: 6),
                          Text(
                            _isLoading ? 'Credits: ...' : 'Credits: $_creditBalance',
                            style: const TextStyle(
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
              const Center(
                child: Text(
                  'Trivia Challenge',
                  style: TextStyle(fontFamily: 'Google Sans', fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: -0.5),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Play quick rounds and collect credits',
                  style: TextStyle(fontFamily: 'Google Sans', fontSize: 16, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 32),
              Divider(color: Colors.grey.shade300, height: 1),
              const SizedBox(height: 32),

              // Category Cards
              if (_isLoading)
                ...[_buildLoadingCard(), const SizedBox(height: 16), _buildLoadingCard(), const SizedBox(height: 16), _buildLoadingCard()]
              else if (_categories.isEmpty)
                const Center(child: Text('No categories yet', style: TextStyle(fontFamily: 'Google Sans', color: Colors.black54)))
              else
                ..._categories.asMap().entries.map((entry) {
                  final cat = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildCategoryCard(cat),
                  );
                }),

              const SizedBox(height: 16),

              // Daily Bonus Block
              if (!_isLoading && _dailyChallenge != null)
                _buildDailyChallengeCard(_dailyChallenge!),

              const SizedBox(height: 32),
              Divider(color: Colors.grey.shade300, height: 1),
              const SizedBox(height: 24),

              // Recent Rewards
              const Text(
                'Recent Rewards',
                style: TextStyle(fontFamily: 'Google Sans', fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const SizedBox(height: 36, child: Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)))
              else if (_recentHistory.isEmpty)
                Text('Complete a quiz to earn your first credits!', style: TextStyle(fontFamily: 'Google Sans', color: Colors.grey.shade500))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _recentHistory.map((h) {
                      final amount = h['amount'] ?? 0;
                      final title = h['title'] ?? '';
                      final label = amount > 0 ? '$title (+$amount)' : '$title ($amount)';
                      return Padding(padding: const EdgeInsets.only(right: 8), child: _buildRewardPill(label));
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    final iconData = _iconMap[cat['icon_name']] ?? Icons.quiz;
    final hasImage = cat['image_url'] != null && (cat['image_url'] as String).isNotEmpty;
    final credits = cat['credits_reward']?.toString() ?? '0';

    // Find challenge matching this category
    final linkedChallenges = _challenges.where((c) => c['category_name'] == cat['name']).toList();

    return GestureDetector(
      onTap: linkedChallenges.isNotEmpty ? () => _openChallenge(linkedChallenges.first) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black),
        ),
        child: Row(
          children: [
            // Icon or Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 56,
                height: 56,
                color: Colors.grey.shade100,
                child: hasImage
                    ? Image.network(cat['image_url'], fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(iconData, color: Colors.black87, size: 28))
                    : Icon(iconData, color: Colors.black87, size: 28),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat['name'] ?? '', style: const TextStyle(fontFamily: 'Google Sans', fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text('Estimated credits: +$credits', style: const TextStyle(fontFamily: 'Google Sans', fontSize: 14, color: Colors.black87)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChallengeCard(Map<String, dynamic> challenge) {
    final hasImage = challenge['image_url'] != null && (challenge['image_url'] as String).isNotEmpty;
    final isCompleted = challenge['already_completed'] == 1 || challenge['already_completed'] == true || challenge['already_completed'] == '1';
    final credits = challenge['credits_reward']?.toString() ?? '0';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner image
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                challenge['image_url'],
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(challenge['title'] ?? "Today's Bonus Trivia", style: const TextStyle(fontFamily: 'Google Sans', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 12),
                Text(
                  challenge['description'] ?? 'Test your knowledge and earn double credits!',
                  style: const TextStyle(fontFamily: 'Google Sans', fontSize: 15, color: Colors.black87, height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isCompleted ? null : () => _openChallenge(challenge),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted ? Colors.grey.shade300 : Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isCompleted ? 'Completed ✓' : 'Start Trivia (+$credits credits)',
                      style: const TextStyle(fontFamily: 'Google Sans', fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
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
      child: Text(text, style: const TextStyle(fontFamily: 'Google Sans', fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black)),
    );
  }
}
