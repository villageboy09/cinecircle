import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _triviaApiBase = 'https://team.cropsync.in/cine_circle/trivia_api.php';

class DailyQuizScreen extends StatefulWidget {
  final String challengeId;
  final String challengeTitle;
  final int creditsReward;
  final VoidCallback? onCompleted;

  const DailyQuizScreen({
    super.key,
    required this.challengeId,
    required this.challengeTitle,
    required this.creditsReward,
    this.onCompleted,
  });

  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<dynamic> _questions = [];
  int _currentIndex = 0;
  // Maps question_id → selected option letter ('A','B','C','D')
  final Map<String, String> _answers = {};
  bool _showResult = false;
  int _score = 0;
  int _creditsEarned = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _fetchQuestions();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<String> _getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone') ?? '';
  }

  Future<void> _fetchQuestions() async {
    setState(() => _isLoading = true);
    try {
      final mobile = await _getMobile();
      final res = await http.get(Uri.parse(
        '$_triviaApiBase?action=get_challenge_questions&mobile_number=$mobile&challenge_id=${widget.challengeId}',
      ));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'already_completed') {
          if (mounted) Navigator.pop(context);
          return;
        }
        if (data['status'] == 'success') {
          setState(() {
            _questions = data['questions'] ?? [];
            _isLoading = false;
          });
          _animController.forward();
          return;
        }
      }
    } catch (e) {
      debugPrint('fetchQuestions error: $e');
    }
    setState(() => _isLoading = false);
  }

  void _selectOption(String questionId, String option) {
    setState(() => _answers[questionId] = option);
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _animController.reverse().then((_) {
        setState(() => _currentIndex++);
        _animController.forward();
      });
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      _animController.reverse().then((_) {
        setState(() => _currentIndex--);
        _animController.forward();
      });
    }
  }

  Future<void> _submitAnswers() async {
    setState(() => _isSubmitting = true);
    try {
      final mobile = await _getMobile();
      final res = await http.post(
        Uri.parse(_triviaApiBase),
        body: {
          'action': 'submit_answers',
          'mobile_number': mobile,
          'challenge_id': widget.challengeId,
          'answers': json.encode(_answers),
        },
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success' || data['status'] == 'already_completed') {
          setState(() {
            _score = data['score'] ?? 0;
            _creditsEarned = data['credits_earned'] ?? 0;
            _showResult = true;
            _isSubmitting = false;
          });
          widget.onCompleted?.call();
          return;
        }
      }
    } catch (e) {
      debugPrint('submitAnswers error: $e');
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) return _buildResultScreen();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/cinelogo.png', height: 24, fit: BoxFit.contain),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                '+${widget.creditsReward} credits',
                style: const TextStyle(fontFamily: 'Google Sans', fontSize: 12, color: Colors.black),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _questions.isEmpty
              ? const Center(child: Text('No questions found.', style: TextStyle(fontFamily: 'Google Sans')))
              : _buildQuizBody(),
    );
  }

  Widget _buildQuizBody() {
    final q = _questions[_currentIndex];
    final qId = q['id'].toString();
    final total = _questions.length;
    final progress = (_currentIndex + 1) / total;
    final selectedOption = _answers[qId];
    final hasImage = q['image_url'] != null && (q['image_url'] as String).isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.challengeTitle, textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Google Sans', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 8),
            Text('Answer correctly to earn rewards', textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Google Sans', fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 24),
            // Progress
            Text('Question ${_currentIndex + 1} of $total',
              style: const TextStyle(fontFamily: 'Google Sans', fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        // Optional question image
                        if (hasImage) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              q['image_url'],
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Text(
                          q['question_text'] ?? '',
                          style: const TextStyle(fontFamily: 'Google Sans', fontSize: 18, color: Colors.black, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        _buildOption(qId, 'A', q['option_a'] ?? '', selectedOption),
                        const SizedBox(height: 12),
                        _buildOption(qId, 'B', q['option_b'] ?? '', selectedOption),
                        const SizedBox(height: 12),
                        _buildOption(qId, 'C', q['option_c'] ?? '', selectedOption),
                        const SizedBox(height: 12),
                        _buildOption(qId, 'D', q['option_d'] ?? '', selectedOption),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Navigation row
            Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _prevQuestion,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(0, 52),
                      ),
                      child: const Text('Back', style: TextStyle(fontFamily: 'Google Sans', fontSize: 16)),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: selectedOption == null
                        ? null
                        : (_currentIndex < _questions.length - 1 ? _nextQuestion : _submitAnswers),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(0, 52),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : Text(
                            _currentIndex < _questions.length - 1 ? 'Next Question' : 'Submit Answers',
                            style: const TextStyle(fontFamily: 'Google Sans', fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip today', style: TextStyle(fontFamily: 'Google Sans', color: Colors.black87, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String questionId, String letter, String text, String? selected) {
    final isSelected = selected == letter;
    return InkWell(
      onTap: () => _selectOption(questionId, letter),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.black, width: isSelected ? 2.5 : 1.0),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? Colors.white : Colors.grey.shade400),
                color: isSelected ? Colors.white : Colors.transparent,
              ),
              child: Center(
                child: Text(letter, style: TextStyle(fontFamily: 'Google Sans', fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.grey.shade600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                style: TextStyle(fontFamily: 'Google Sans', fontSize: 16, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final total = _questions.length;
    final pct = total > 0 ? (_score / total * 100).round() : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.emoji_events_rounded, size: 80, color: Colors.black),
              const SizedBox(height: 24),
              const Text('Quiz Complete!', textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Google Sans', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 16),
              Text('$_score / $total correct  ($pct%)', textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Google Sans', fontSize: 18, color: Colors.black87)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  children: [
                    const Text('Credits Earned', style: TextStyle(fontFamily: 'Google Sans', fontSize: 14, color: Colors.black54)),
                    const SizedBox(height: 8),
                    Text('+$_creditsEarned', style: const TextStyle(fontFamily: 'Google Sans', fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(0, 52),
                ),
                child: const Text('Back to Trivia', style: TextStyle(fontFamily: 'Google Sans', fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
