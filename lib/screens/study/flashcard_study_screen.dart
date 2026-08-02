import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flip_card/flip_card.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../models/question_model.dart';
import '../../widgets/skeleton_loader.dart';

class FlashcardStudyScreen extends ConsumerStatefulWidget {
  final String quizId;

  const FlashcardStudyScreen({super.key, required this.quizId});

  @override
  ConsumerState<FlashcardStudyScreen> createState() =>
      _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends ConsumerState<FlashcardStudyScreen> {
  bool _isLoading = true;

  // The set currently being reviewed this round. On the first round this is
  // the same as _allFlashcards; on subsequent "Study Again" rounds this is
  // only the cards the user marked "Still Learning" last time.
  List<QuestionModel> _questions = [];

  int _currentIndex = 0;
  int _knownCount = 0;
  int _unknownCount = 0;

  // Cards the user marked "Still Learning" during the current round.
  final List<QuestionModel> _unknownThisRound = [];

  // Incremented every time a new study session starts so that FlipCard
  // always rebuilds from the front (Question) side.
  int _sessionKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuestions());
  }

  Future<void> _loadQuestions() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final (_, questions) = await ref
        .read(userQuizzesProvider(user.id).notifier)
        .getQuizWithQuestions(widget.quizId);

    // Filter only flashcards or use all questions as flashcards
    final flashcards = questions.where((q) => q.isFlashcard).toList();
    final workingSet = flashcards.isNotEmpty ? flashcards : questions;

    if (mounted) {
      setState(() {
        _questions = List.of(workingSet);
        _isLoading = false;
      });
    }
  }

  void _markKnown() {
    setState(() {
      _knownCount++;
      _advance();
    });
  }

  void _markUnknown() {
    setState(() {
      _unknownCount++;
      _unknownThisRound.add(_questions[_currentIndex]);
      _advance();
    });
  }

  void _advance() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
    } else {
      _showCompletionDialog();
    }
  }

  Future<void> _showCompletionDialog() async {
    final total = _questions.length;
    final known = _knownCount;
    final unknown = _unknownCount;
    final remainingUnknown = List<QuestionModel>.from(_unknownThisRound);

    // Update stats
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null) {
      await ref
          .read(userQuizzesProvider(user.id).notifier)
          .updateQuizStats(widget.quizId, known, total);
    }

    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text('Study Session Complete!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.celebration,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You reviewed $total cards',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildResultChip(Colors.green, 'Known: $known'),
                      const SizedBox(width: 8),
                      _buildResultChip(Colors.red, 'Unknown: $unknown'),
                    ],
                  ),
                  if (remainingUnknown.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '"Study Again" will only show the $unknown card(s) '
                      'you\'re still learning.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
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
                  onPressed: remainingUnknown.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          setState(() {
                            // Only the cards marked "Still Learning" carry
                            // over into the next round.
                            _questions = remainingUnknown;
                            _unknownThisRound.clear();
                            _currentIndex = 0;
                            _knownCount = 0;
                            _unknownCount = 0;
                            // Bump session key so every FlipCard is rebuilt
                            // fresh, starting on the Question (front) side.
                            _sessionKey++;
                          });
                        },
                  child: const Text('Study Again'),
                ),
              ],
            ),
      );

      // If there was nothing left to review (perfect round), just leave.
      if (remainingUnknown.isEmpty && mounted) {
        context.go('/study');
      }
    }
  }

  Widget _buildResultChip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        resizeToAvoidBottomInset: false,
        body: PageSkeleton(),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: const Text('Flashcards')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flip, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No flashcards available',
                style: Theme.of(context).textTheme.titleLarge,
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

    final currentQuestion = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentIndex + 1}/${_questions.length}',
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
            minHeight: 4,
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatChip(
                        icon: Icons.check_circle,
                        label: '$_knownCount',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _buildStatChip(
                        icon: Icons.help_outline,
                        label: '$_unknownCount',
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Flashcard
                  // ValueKey changes when card index OR session changes,
                  // forcing a fresh rebuild always starting on front (Question).
                  Expanded(
                    child: FlipCard(
                      key: ValueKey('card_${_sessionKey}_$_currentIndex'),
                      direction: FlipDirection.HORIZONTAL,
                      front: _buildCardSide(
                        context,
                        title: 'Question',
                        content: currentQuestion.questionText,
                        hint: 'Tap to flip',
                      ),
                      back: _buildCardSide(
                        context,
                        title: 'Answer',
                        content: currentQuestion.displayAnswer,
                        hint: 'Tap to flip back',
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _markUnknown,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.close),
                          label: const Text('Still Learning'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _markKnown,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            foregroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('Got it!'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSide(
    BuildContext context, {
    required String title,
    required String content,
    required String hint,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            hint,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}