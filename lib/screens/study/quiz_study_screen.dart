import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../models/question_model.dart';

class QuizStudyScreen extends ConsumerStatefulWidget {
  final String quizId;

  const QuizStudyScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizStudyScreen> createState() => _QuizStudyScreenState();
}

class _QuizStudyScreenState extends ConsumerState<QuizStudyScreen> {
  bool _isLoading = true;
  List<QuestionModel> _questions = [];
  List<QuestionModel> _shuffledQuestions = [];
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _hasAnswered = false;
  List<int> _userAnswers = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final (_, questions) = ref
        .read(userQuizzesProvider(user.id).notifier)
        .getQuizWithQuestions(widget.quizId);

    // Filter out flashcards for quiz mode
    final quizQuestions = questions.where((q) => !q.isFlashcard).toList();
    
    setState(() {
      _questions = quizQuestions;
      _shuffledQuestions = [...quizQuestions]..shuffle();
      _isLoading = false;
    });
  }

  void _selectAnswer(int index) {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswer = index;
      _hasAnswered = true;
      _userAnswers.add(index);

      final currentQuestion = _shuffledQuestions[_currentIndex];
      if (index == currentQuestion.correctAnswerIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _shuffledQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _hasAnswered = false;
      });
    } else {
      _showResults();
    }
  }

  Future<void> _showResults() async {
    final total = _shuffledQuestions.length;
    final percentage = (_score / total * 100).round();
    
    // Update quiz stats
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref.read(userQuizzesProvider(user.id).notifier).updateQuizStats(
        widget.quizId,
        _score,
        total,
      );
    }

    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Quiz Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Score Circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: percentage >= 70
                        ? [Colors.green, Colors.green.shade600]
                        : percentage >= 50
                            ? [Colors.orange, Colors.orange.shade600]
                            : [Colors.red, Colors.red.shade600],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$_score/$total',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                percentage >= 70
                    ? 'Excellent work!'
                    : percentage >= 50
                        ? 'Good job!'
                        : 'Keep practicing!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/study');
              },
              child: const Text('Done'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _restartQuiz();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _selectedAnswer = null;
      _hasAnswered = false;
      _userAnswers = [];
      _shuffledQuestions.shuffle();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Mode')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.quiz,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No quiz questions available',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Add multiple-choice questions to this quiz',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = _shuffledQuestions[_currentIndex];
    final progress = (_currentIndex + 1) / _shuffledQuestions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Mode'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentIndex + 1}/${_shuffledQuestions.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            minHeight: 6,
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Score
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.emoji_events,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Score: $_score',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Question
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      currentQuestion.questionText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Options
                  ...currentQuestion.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    return _buildOptionCard(index, option, currentQuestion.correctAnswerIndex);
                  }),

                  const SizedBox(height: 32),

                  // Next Button
                  if (_hasAnswered)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _currentIndex < _shuffledQuestions.length - 1
                              ? 'Next Question'
                              : 'See Results',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildOptionCard(int index, String option, int correctIndex) {
    final isSelected = _selectedAnswer == index;
    final isCorrect = index == correctIndex;
    final showCorrect = _hasAnswered && isCorrect;
    final showWrong = _hasAnswered && isSelected && !isCorrect;

    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    IconData? trailingIcon;
    Color? iconColor;

    if (showCorrect) {
      backgroundColor = Colors.green.shade50;
      borderColor = Colors.green;
      trailingIcon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (showWrong) {
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red;
      trailingIcon = Icons.cancel;
      iconColor = Colors.red;
    } else if (isSelected) {
      backgroundColor = Theme.of(context).colorScheme.primaryContainer;
      borderColor = Theme.of(context).colorScheme.primary;
    }

    return GestureDetector(
      onTap: () => _selectAnswer(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected || showCorrect || showWrong
                    ? (showCorrect
                        ? Colors.green
                        : showWrong
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    color: isSelected || showCorrect || showWrong
                        ? Colors.white
                        : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (trailingIcon != null)
              Icon(trailingIcon, color: iconColor),
          ],
        ),
      ),
    );
  }
}
