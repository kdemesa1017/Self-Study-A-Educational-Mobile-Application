import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../models/quiz_model.dart';
import '../../models/question_model.dart';

class QuizDetailScreen extends ConsumerStatefulWidget {
  final String quizId;

  const QuizDetailScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _EditQuizBottomSheet extends ConsumerStatefulWidget {
  final QuizModel quiz;
  final VoidCallback onSaved;

  const _EditQuizBottomSheet({
    required this.quiz,
    required this.onSaved,
  });

  @override
  ConsumerState<_EditQuizBottomSheet> createState() => _EditQuizBottomSheetState();
}

class _EditQuizBottomSheetState extends ConsumerState<_EditQuizBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quiz.title);
    _descriptionController = TextEditingController(text: widget.quiz.description ?? '');
    _categoryController = TextEditingController(text: widget.quiz.category ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    await ref.read(userQuizzesProvider(user.id).notifier).updateQuiz(
          quizId: widget.quiz.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
        );

    if (!mounted) return;
    Navigator.pop(context);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Quiz',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Quiz Title *',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a quiz title';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditQuestionBottomSheet extends ConsumerStatefulWidget {
  final QuestionModel question;
  final VoidCallback onSaved;

  const _EditQuestionBottomSheet({
    required this.question,
    required this.onSaved,
  });

  @override
  ConsumerState<_EditQuestionBottomSheet> createState() =>
      _EditQuestionBottomSheetState();
}

class _EditQuestionBottomSheetState extends ConsumerState<_EditQuestionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionController;
  late final TextEditingController _backController;
  late final List<TextEditingController> _optionControllers;

  bool _isFlashcard = false;
  int _correctAnswerIndex = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isFlashcard = widget.question.isFlashcard;
    _correctAnswerIndex = widget.question.correctAnswerIndex;

    _questionController = TextEditingController(text: widget.question.questionText);
    _backController = TextEditingController(text: widget.question.flashcardBack ?? '');

    final initialOptions = widget.question.options;
    _optionControllers = List.generate(
      4,
      (i) => TextEditingController(text: i < initialOptions.length ? initialOptions[i] : ''),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _backController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    final options = _isFlashcard
        ? [_backController.text.trim()]
        : _optionControllers.map((c) => c.text.trim()).toList();

    await ref.read(userQuizzesProvider(user.id).notifier).updateQuestion(
          questionId: widget.question.id,
          questionText: _questionController.text.trim(),
          options: options,
          correctAnswerIndex: _isFlashcard ? 0 : _correctAnswerIndex,
          isFlashcard: _isFlashcard,
          flashcardBack: _isFlashcard ? _backController.text.trim() : null,
        );

    if (!mounted) return;
    Navigator.pop(context);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Question',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ChoiceChip(
              label: const Text('Flashcard Mode'),
              selected: _isFlashcard,
              onSelected: (selected) {
                setState(() {
                  _isFlashcard = selected;
                  if (_isFlashcard) {
                    _correctAnswerIndex = 0;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question *',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a question';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            if (_isFlashcard)
              TextFormField(
                controller: _backController,
                decoration: const InputDecoration(
                  labelText: 'Answer (Back of card) *',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the answer';
                  }
                  return null;
                },
              )
            else
              Column(
                children: [
                  ..._optionControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: index,
                            groupValue: _correctAnswerIndex,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _correctAnswerIndex = value);
                            },
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: 'Option ${index + 1} *',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter this option';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizDetailScreenState extends ConsumerState<QuizDetailScreen> {
  bool _isLoading = true;
  QuizModel? _quiz;
  List<QuestionModel> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _editQuiz() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _quiz == null) return;
    if (_quiz!.userId != user.id) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditQuizBottomSheet(
        quiz: _quiz!,
        onSaved: _loadQuiz,
      ),
    );
  }

  Future<void> _editQuestion(QuestionModel question) async {
    final user = ref.read(currentUserProvider);
    if (user == null || _quiz == null) return;
    if (_quiz!.userId != user.id) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditQuestionBottomSheet(
        question: question,
        onSaved: _loadQuiz,
      ),
    );
  }

  Future<void> _loadQuiz() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final (quiz, questions) = await ref
        .read(userQuizzesProvider(user.id).notifier)
        .getQuizWithQuestions(widget.quizId);

    if (mounted) {
      setState(() {
        _quiz = quiz;
        _questions = questions;
        _isLoading = false;
      });
      // If quiz was deleted, navigate away
      if (quiz == null) {
        context.go('/my-quizzes');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This quiz no longer exists')),
        );
      }
    }
  }

  Future<void> _deleteQuestion(String questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await ref
            .read(userQuizzesProvider(user.id).notifier)
            .deleteQuestion(questionId);
        _loadQuiz();
      }
    }
  }

  Future<void> _deleteQuiz() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Are you sure you want to delete "${_quiz?.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await ref
            .read(userQuizzesProvider(user.id).notifier)
            .deleteQuiz(widget.quizId);
        if (mounted) {
          context.go('/my-quizzes');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz deleted successfully')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        resizeToAvoidBottomInset: false,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_quiz == null) {
      return const Scaffold(
        resizeToAvoidBottomInset: false,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final currentUser = ref.read(currentUserProvider);
    final canEdit = currentUser != null && _quiz!.userId == currentUser.id;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _quiz!.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Decorative image (no assets needed)
                  Image.network(
                    'https://images.unsplash.com/photo-1523240795612-9a054b0db644?auto=format&fit=crop&w=1200&q=60',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Scrim so text stays readable
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.black.withOpacity(0.55),
                        ],
                      ),
                    ),
                  ),
                  // Existing content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_quiz!.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _quiz!.category!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (_quiz!.description != null)
                          Text(
                            _quiz!.description!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editQuiz();
                      break;
                    case 'delete':
                      _deleteQuiz();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    enabled: canEdit,
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: canEdit ? null : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Edit Quiz',
                          style: TextStyle(
                            color: canEdit ? null : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Quiz', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStatCard(
                    context,
                    icon: Icons.help_outline,
                    value: '${_questions.length}',
                    label: 'Questions',
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    context,
                    icon: Icons.school_outlined,
                    value: '${_quiz!.studyCount ?? 0}',
                    label: 'Study Sessions',
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    context,
                    icon: Icons.trending_up,
                    value: '${((_quiz!.averageScore ?? 0) * 100).toInt()}%',
                    label: 'Avg Score',
                  ),
                ],
              ),
            ),
          ),

          // Study Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _questions.isEmpty
                          ? null
                          : () => context.push('/study/flashcard/${widget.quizId}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.flip),
                      label: const Text('Flashcards'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _questions.isEmpty
                          ? null
                          : () => context.push('/study/quiz/${widget.quizId}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.quiz),
                      label: const Text('Quiz Mode'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Questions Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Questions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: canEdit ? () => _showAddQuestionDialog() : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
          ),

          // Questions List
          if (_questions.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyQuestionsState(context),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final question = _questions[index];
                  return _buildQuestionTile(context, question);
                },
                childCount: _questions.length,
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionTile(BuildContext context, QuestionModel question) {
    final currentUser = ref.read(currentUserProvider);
    final canEdit = currentUser != null && _quiz != null && _quiz!.userId == currentUser.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: () => _editQuestion(question),
        title: Text(
          question.questionText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: question.isFlashcard
            ? const Text('Flashcard')
            : Text('${question.options.length} options'),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: question.isFlashcard
                ? Colors.orange.withOpacity(0.2)
                : Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            question.isFlashcard ? Icons.flip : Icons.help_outline,
            size: 20,
            color: question.isFlashcard ? Colors.orange : Colors.blue,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: canEdit ? () => _deleteQuestion(question.id) : null,
        ),
      ),
    );
  }

  Widget _buildEmptyQuestionsState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.help_outline,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No questions yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddQuestionDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Question'),
          ),
        ],
      ),
    );
  }

  void _showAddQuestionDialog() {
    // Navigate to create quiz screen for now
    // In a full implementation, this would show a dialog to add a single question
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddQuestionBottomSheet(
        quizId: widget.quizId,
        onQuestionAdded: _loadQuiz,
      ),
    );
  }
}

class _AddQuestionBottomSheet extends ConsumerStatefulWidget {
  final String quizId;
  final VoidCallback onQuestionAdded;

  const _AddQuestionBottomSheet({
    required this.quizId,
    required this.onQuestionAdded,
  });

  @override
  ConsumerState<_AddQuestionBottomSheet> createState() =>
      _AddQuestionBottomSheetState();
}

class _AddQuestionBottomSheetState
    extends ConsumerState<_AddQuestionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _backController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  bool _isFlashcard = false;
  int _correctAnswerIndex = 0;
  bool _isSaving = false;

  @override
  void dispose() {
    _questionController.dispose();
    _backController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref.read(userQuizzesProvider(user.id).notifier).addQuestion(
        quizId: widget.quizId,
        questionText: _questionController.text.trim(),
        options: _isFlashcard
            ? [_backController.text.trim()]
            : _optionControllers.map((c) => c.text).toList(),
        correctAnswerIndex: _isFlashcard ? 0 : _correctAnswerIndex,
        isFlashcard: _isFlashcard,
        flashcardBack: _isFlashcard ? _backController.text.trim() : null,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onQuestionAdded();
      }
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Question',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ChoiceChip(
                label: const Text('Flashcard Mode'),
                selected: _isFlashcard,
                onSelected: (selected) {
                  setState(() => _isFlashcard = selected);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  hintText: 'Enter your question',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a question';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_isFlashcard)
                TextFormField(
                  controller: _backController,
                  decoration: const InputDecoration(
                    labelText: 'Answer (Back of card)',
                    hintText: 'Enter the answer',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the answer';
                    }
                    return null;
                  },
                )
              else
                Column(
                  children: [
                    ..._optionControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: index,
                              groupValue: _correctAnswerIndex,
                              onChanged: (value) {
                                setState(() => _correctAnswerIndex = value!);
                              },
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: controller,
                                decoration: InputDecoration(
                                  labelText: 'Option ${index + 1}',
                                  hintText: index == 0
                                      ? 'Correct answer'
                                      : 'Wrong answer',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter this option';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveQuestion,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Question'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
