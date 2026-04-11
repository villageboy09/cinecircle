import 'package:flutter/material.dart';

class DailyQuizScreen extends StatefulWidget {
  const DailyQuizScreen({super.key});

  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen> {
  int _selectedOption = -1;

  @override
  Widget build(BuildContext context) {
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
              child: const Text(
                '+25 credits',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Daily Quiz',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Answer correctly to earn rewards',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Question 1 of 5',
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.2, // 1 out of 5
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                minHeight: 4,
              ),
              const SizedBox(height: 32),
              Expanded(
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
                        const Text(
                          'Which of these film movements is known for its emphasis on realism, location shooting, and non-professional actors?',
                          style: TextStyle(
                            fontFamily: 'Google Sans',
                            fontSize: 18,
                            color: Colors.black,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        _buildOptionButton(0, 'French New Wave'),
                        const SizedBox(height: 16),
                        _buildOptionButton(1, 'Italian Neorealism'),
                        const SizedBox(height: 16),
                        _buildOptionButton(2, 'German Expressionism'),
                        const SizedBox(height: 16),
                        _buildOptionButton(3, 'Hollywood Golden Age'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedOption != -1 ? () {} : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Answer',
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Skip today',
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(int index, String text) {
    bool isSelected = _selectedOption == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedOption = index;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.black,
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Google Sans',
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
