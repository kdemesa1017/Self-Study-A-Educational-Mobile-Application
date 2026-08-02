import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../models/quiz_model.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/offline_mode_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isOfflineMode = false;
  Timer? _slowLoadTimer;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    // Kick off the streak check as soon as the screen is visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(streakProvider);
      _startSlowLoadTimer();
    });
  }

  @override
  void dispose() {
    _slowLoadTimer?.cancel();
    super.dispose();
  }

  void _startSlowLoadTimer() {
    _slowLoadTimer?.cancel();
    // If data is still loading after 30 seconds, offer the offline modal.
    _slowLoadTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted) return;
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.valueOrNull;
      final isQuizzesLoading = user != null && ref.read(userQuizzesProvider(user.id)).isLoading;
      final isAuthLoading = userAsync.isLoading;

      if ((isAuthLoading || isQuizzesLoading) && !_dialogShown && !_isOfflineMode) {
        _showOfflineDialog();
      }
    });
  }

  void _showOfflineDialog() {
    if (_dialogShown || !mounted) return;
    _dialogShown = true;
    OfflineModeDialog.show(
      context,
      onWait: () {
        setState(() => _dialogShown = false);
        _startSlowLoadTimer();
      },
      onGoOffline: () => setState(() => _isOfflineMode = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    // Show skeleton while Firebase Auth is still initialising
    if (userAsync.isLoading && !_isOfflineMode) return const PageSkeleton();

    final user = userAsync.valueOrNull;
    final quizzesAsync =
        user != null
            ? ref.watch(userQuizzesProvider(user.id))
            : const AsyncValue.data(<QuizModel>[]);

    return quizzesAsync.when(
      data: (quizzes) => _buildContent(context, ref, user, quizzes),
      loading: () => const PageSkeleton(),

      error:
          (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 64,
                  color: Color(0xFF6C63FF),
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not load data',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Check your internet connection',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (user != null) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed:
                        () =>
                            ref
                                .read(userQuizzesProvider(user.id).notifier)
                                .refreshQuizzes(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() => _isOfflineMode = true),
                    child: const Text('Use Offline Mode'),
                  ),
                ],
              ],
            ),
          ),
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    user,
    List<QuizModel> quizzes,
  ) {
    final recentQuizzes = quizzes.take(3).toList();
    final totalQuizzes = quizzes.length;
    final totalQuestions = quizzes.fold<int>(
      0,
      (sum, quiz) => sum + quiz.questionIds.length,
    );
    final streakAsync = ref.watch(streakProvider);
    final streakCount = streakAsync.valueOrNull ?? user?.streakCount ?? 0;
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;

    return RefreshIndicator(
      onRefresh:
          user != null
              ? () =>
                  ref
                      .read(userQuizzesProvider(user.id).notifier)
                      .refreshQuizzes()
              : () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Offline badge ──────────────────────────────────────────────
            if (_isOfflineMode || !isOnline)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Offline Mode — showing cached data',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_isOfflineMode && isOnline) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _isOfflineMode = false),
                        child: Text(
                          'Go online',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // ── Welcome card ───────────────────────────────────────────────
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/Logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Self Study',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome back,',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.name ?? 'Student',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ready to learn something new today?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Streak card ────────────────────────────────────────────────
            _StreakCard(streakCount: streakCount, isOnline: isOnline),
            const SizedBox(height: 24),

            // ── Stats ──────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.folder_outlined,
                    title: 'Quizzes',
                    value: totalQuizzes.toString(),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.help_outline,
                    title: 'Questions',
                    value: totalQuestions.toString(),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.school_outlined,
                    title: 'Studied',
                    value:
                        quizzes
                            .fold<int>(0, (sum, q) => sum + (q.studyCount ?? 0))
                            .toString(),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Quick Actions ──────────────────────────────────────────────
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    icon: Icons.add_circle_outline,
                    title: 'Create Quiz',
                    subtitle: 'Make a new study set',
                    color: Colors.purple,
                    onTap: () => context.push('/create-quiz'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    context,
                    icon: Icons.school_outlined,
                    title: 'Study Mode',
                    subtitle: 'Review your quizzes',
                    color: Colors.teal,
                    onTap: () => context.push('/study'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── AI Generator button (online-only) ──────────────────────────
            _AiGenerateButton(
              isOnline: isOnline,
              onTap: () => context.push('/ai-generator'),
            ),
            const SizedBox(height: 24),

            // ── Recent Quizzes ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Quizzes',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.push('/my-quizzes'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentQuizzes.isEmpty)
              _buildEmptyState(context)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentQuizzes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final quiz = recentQuizzes[index];
                  return _buildQuizCard(context, quiz);
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.8), color],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, QuizModel quiz) {
    return GestureDetector(
      onTap: () => context.push('/quiz/${quiz.id}'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${quiz.questionIds.length} questions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No quizzes yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first quiz to get started!',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
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

// ── Streak Card ─────────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int streakCount;
  final bool isOnline;

  const _StreakCard({required this.streakCount, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final today = _todayLabel();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFCC80)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Flame icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8C00)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.local_fire_department, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Streak',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$streakCount',
                      style: const TextStyle(
                        color: Color(0xFFE65100),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      streakCount == 1 ? 'day' : 'days',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Text(
                  '✅ $today',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isOnline) ...[
                const SizedBox(height: 4),
                Text(
                  'Syncing when online',
                  style: TextStyle(
                    color: Colors.orange.shade600,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[now.month - 1]} ${now.day}';
  }
}

// ── AI Generator Button ─────────────────────────────────────────────────────────

class _AiGenerateButton extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onTap;

  const _AiGenerateButton({required this.isOnline, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isOnline ? onTap : () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI generation requires internet connection'),
            backgroundColor: Color(0xFF6C63FF),
          ),
        );
      },
      child: AnimatedOpacity(
        opacity: isOnline ? 1.0 : 0.55,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6C63FF), Color(0xFF4834D4)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Generate with AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'FREE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isOnline
                          ? 'Upload PDF, TXT or DOCX → instant quiz'
                          : 'Requires internet connection',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
