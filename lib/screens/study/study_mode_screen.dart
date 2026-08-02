import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../models/quiz_model.dart';
import '../../widgets/skeleton_loader.dart';

class StudyModeScreen extends ConsumerWidget {
  const StudyModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    // Show skeleton while auth is still initialising
    if (userAsync.isLoading) return const PageSkeleton(list: true);

    final user = userAsync.valueOrNull;
    if (user == null) {
      return const PageSkeleton(list: true);
    }

    final quizzesAsync = ref.watch(userQuizzesProvider(user.id));

    return quizzesAsync.when(
      data: (quizzes) {
        final quizzesWithQuestions =
            quizzes.where((q) => q.questionIds.isNotEmpty).toList();
        return _buildContent(context, quizzes, quizzesWithQuestions);
      },
      loading: () => const PageSkeleton(list: true),
      error:
          (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error loading quizzes: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed:
                      () =>
                          ref
                              .read(userQuizzesProvider(user.id).notifier)
                              .refreshQuizzes(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<QuizModel> quizzes,
    List<QuizModel> quizzesWithQuestions,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Study Mode',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a quiz to start studying',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Study Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.folder_outlined,
                  title: 'Available',
                  value: '${quizzesWithQuestions.length}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.school_outlined,
                  title: 'Studied',
                  value:
                      '${quizzes.fold<int>(0, (sum, q) => sum + (q.studyCount ?? 0))}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Study Modes Info
          Text(
            'Study Modes',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModeCard(
                  context,
                  icon: Icons.flip,
                  title: 'Flashcards',
                  description: 'Flip cards to test your memory',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeCard(
                  context,
                  icon: Icons.quiz,
                  title: 'Quiz Mode',
                  description: 'Multiple choice questions with scoring',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Available Quizzes
          Text(
            'Select a Quiz to Study',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (quizzesWithQuestions.isEmpty)
            _buildEmptyState(context)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quizzesWithQuestions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final quiz = quizzesWithQuestions[index];
                return _buildQuizCard(context, quiz);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, QuizModel quiz) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // Tapping the card body prioritizes Flashcard mode.
        onTap: () => context.push('/study/flashcard/${quiz.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.quiz, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${quiz.questionIds.length} questions',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Primary action — Flashcards (prioritized)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () => context.push('/study/flashcard/${quiz.id}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.flip, size: 18),
                      label: const Text('Flashcards'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Secondary action — Quiz Mode
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/study/quiz/${quiz.id}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: BorderSide(color: Colors.green.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.quiz, size: 18),
                      label: const Text('Quiz Mode'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No quizzes available',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Create quizzes with questions to start studying',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/create-quiz'),
            icon: const Icon(Icons.add),
            label: const Text('Create Quiz'),
          ),
        ],
      ),
    );
  }
}