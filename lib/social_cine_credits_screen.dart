import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'social_redeem_rewards_screen.dart';

const _creditsApiBase = 'https://team.cropsync.in/cine_circle/social_api.php';

class SocialCineCreditsScreen extends StatefulWidget {
  const SocialCineCreditsScreen({super.key});

  @override
  State<SocialCineCreditsScreen> createState() => _SocialCineCreditsScreenState();
}

class _SocialCineCreditsScreenState extends State<SocialCineCreditsScreen> {
  bool _isLoading = true;
  int _balance = 0;
  int _totalEarned = 0;
  int _totalSpent = 0;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchCredits();
  }

  Future<void> _fetchCredits() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone') ?? '';
      final res = await http.get(
        Uri.parse('$_creditsApiBase?action=get_credits&mobile_number=$mobile'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _balance = data['data']['balance'] ?? 0;
            _totalEarned = data['data']['total_earned'] ?? 0;
            _totalSpent = data['data']['total_spent'] ?? 0;
            _history = data['data']['history'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('fetchCredits error: $e');
    }
    setState(() => _isLoading = false);
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  // Map source string to icon
  IconData _sourceIcon(String? source) {
    switch (source) {
      case 'quiz_win': return Icons.quiz;
      case 'daily_login': return Icons.login;
      case 'engagement': return Icons.thumb_up_outlined;
      case 'review_reward': return Icons.movie_filter;
      case 'redemption': return Icons.local_activity;
      case 'early_access': return Icons.lock_open;
      case 'unlock': return Icons.star_border;
      default: return Icons.copyright;
    }
  }

  // Breakdown of earned vs spent by source
  Map<String, int> get _earnBreakdown {
    final Map<String, int> result = {};
    for (final h in _history) {
      if (h['type'] == 'earn') {
        final source = h['source'] ?? 'other';
        result[source] = (result[source] ?? 0) + (h['amount'] as num).toInt();
      }
    }
    return result;
  }

  Map<String, int> get _spendBreakdown {
    final Map<String, int> result = {};
    for (final h in _history) {
      if (h['type'] == 'spend') {
        final source = h['source'] ?? 'other';
        result[source] = (result[source] ?? 0) + (h['amount'] as num).toInt().abs();
      }
    }
    return result;
  }

  String _labelForSource(String source) {
    switch (source) {
      case 'quiz_win': return 'Quiz Wins:';
      case 'daily_login': return 'Daily Login:';
      case 'engagement': return 'Engagement:';
      case 'review_reward': return 'Review Rewards:';
      case 'redemption': return 'Ticket Redemptions:';
      case 'early_access': return 'Early-Access:';
      case 'unlock': return 'Unlocks:';
      default: return source;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Image.asset('assets/cinelogo.png', height: 32, fit: BoxFit.contain),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: Colors.black,
        onRefresh: _fetchCredits,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _isLoading
              ? const SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator(color: Colors.black)),
                )
              : Column(
                  children: [
                    // Title & Balance
                    const Text('Social Credits',
                        style: TextStyle(fontFamily: 'Google Sans', fontSize: 28, color: Colors.black)),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        '$_balance Social Credits',
                        key: ValueKey(_balance),
                        style: const TextStyle(fontFamily: 'Google Sans', fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Total Balance',
                        style: TextStyle(fontFamily: 'Google Sans', fontSize: 15, color: Colors.black87)),
                    const SizedBox(height: 32),

                    // Summary Cards
                    Row(
                      children: [
                        Expanded(child: _buildSummaryCard(
                          title: 'Earning Summary',
                          icon: Icons.arrow_upward,
                          rows: {
                            for (final e in _earnBreakdown.entries)
                              _labelForSource(e.key): '${e.value}',
                          },
                          totalLabel: 'Total Earned:',
                          totalValue: '$_totalEarned',
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSummaryCard(
                          title: 'Redemption Summary',
                          icon: Icons.arrow_downward,
                          rows: {
                            for (final e in _spendBreakdown.entries)
                              _labelForSource(e.key): '-${e.value}',
                          },
                          totalLabel: 'Total Redeemed:',
                          totalValue: '-$_totalSpent',
                        )),
                      ],
                    ),

                    const SizedBox(height: 32),
                    Divider(color: Colors.grey.shade300, height: 1),
                    const SizedBox(height: 24),

                    // Transaction History
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Recent Transactions',
                          style: TextStyle(fontFamily: 'Google Sans', fontSize: 18, color: Colors.black)),
                    ),
                    const SizedBox(height: 24),

                    if (_history.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text('No transactions yet. Complete a quiz to start!',
                              style: TextStyle(fontFamily: 'Google Sans', color: Colors.grey.shade500)),
                        ),
                      )
                    else
                      ..._history.map((h) => _buildTransactionItem(h)),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SocialRedeemRewardsScreen(balance: _balance)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Redeem Credits',
                            style: TextStyle(fontFamily: 'Google Sans', fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
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
                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontFamily: 'Google Sans', fontSize: 14, color: Colors.black)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (rows.isEmpty)
            Text('No activity', style: TextStyle(fontFamily: 'Google Sans', fontSize: 12, color: Colors.grey.shade500))
          else
            ...rows.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(entry.key, style: const TextStyle(fontFamily: 'Google Sans', fontSize: 12, color: Colors.black87))),
                  Text(entry.value, style: const TextStyle(fontFamily: 'Google Sans', fontSize: 12, color: Colors.black87)),
                ],
              ),
            )),
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(totalLabel, style: const TextStyle(fontFamily: 'Google Sans', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
              Text(totalValue, style: const TextStyle(fontFamily: 'Google Sans', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> h) {
    final bool isPositive = h['type'] == 'earn';
    final int amount = (h['amount'] as num).toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(_sourceIcon(h['source']), size: 22, color: Colors.black54),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h['title'] ?? '', style: const TextStyle(fontFamily: 'Google Sans', fontSize: 14, color: Colors.black)),
                const SizedBox(height: 4),
                Text(_formatDate(h['created_at']),
                    style: TextStyle(fontFamily: 'Google Sans', fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isPositive ? '+$amount' : '$amount',
            style: TextStyle(
              fontFamily: 'Google Sans',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isPositive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            ),
          ),
        ],
      ),
    );
  }
}
