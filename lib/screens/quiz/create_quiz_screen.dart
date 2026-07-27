import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/connectivity_provider.dart';

class CreateQuizScreen extends ConsumerStatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  ConsumerState<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends ConsumerState<CreateQuizScreen> {
  final _quizFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  
  final List<QuestionFormData> _questions = [];
  bool _isCreating = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuestionFormData());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _createQuiz() async {
    if (!_quizFormKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question before creating the quiz.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate all questions
    for (var i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter text for question ${i + 1}')),
        );
        return;
      }
      if (!q.isFlashcard && q.options.length != 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question ${i + 1} must have exactly 4 choices.')),
        );
        return;
      }
      if (!q.isFlashcard && q.options.any((o) => o.text.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all options for question ${i + 1}')),
        );
        return;
      }
      if (!q.isFlashcard && (q.correctAnswerIndex < 0 || q.correctAnswerIndex > 3)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please choose the correct answer for question ${i + 1}')),
        );
        return;
      }
    }

    setState(() => _isCreating = true);

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      setState(() => _isCreating = false);
      return;
    }

    try {
      final quiz = await ref.read(userQuizzesProvider(user.id).notifier).createQuiz(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
      );

      for (final q in _questions) {
        await ref.read(userQuizzesProvider(user.id).notifier).addQuestion(
          quizId: quiz.id,
          questionText: q.questionController.text.trim(),
          options: q.isFlashcard
              ? [q.backController.text.trim()]
              : q.options.map((o) => o.text.trim()).toList(),
          correctAnswerIndex: q.isFlashcard ? 0 : q.correctAnswerIndex,
          isFlashcard: q.isFlashcard,
          flashcardBack: q.isFlashcard ? q.backController.text.trim() : null,
        );
      }

      setState(() => _isCreating = false);

      if (mounted) {
        final isOnline = await ref.read(connectivityServiceProvider).isOnline;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOnline
                  ? 'Quiz created successfully!'
                  : 'Quiz saved offline. It will sync when you\'re back online.',
            ),
          ),
        );
        context.go('/my-quizzes');
      }
    } catch (_) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create quiz'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (_currentStep + 1) / 2;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.08),
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create a Quiz',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currentStep == 0
                          ? 'Step 1 of 2  ·  Quiz details'
                          : 'Step 2 of 2  ·  Add questions',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor:
                            theme.colorScheme.onSurface.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Material(
                    elevation: 0,
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Stepper(
                        type: StepperType.horizontal,
                        currentStep: _currentStep,
                        onStepContinue: () {
                          if (_currentStep < 1) {
                            setState(() => _currentStep++);
                          } else {
                            _createQuiz();
                          }
                        },
                        onStepCancel: () {
                          if (_currentStep > 0) {
                            setState(() => _currentStep--);
                          }
                        },
                        onStepTapped: (step) => setState(() => _currentStep = step),
                        controlsBuilder: (context, details) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                            child: Row(
                              children: [
                                if (_currentStep > 0) ...[
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: details.onStepCancel,
                                      child: const Text('Back'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _currentStep < 1
                                        ? details.onStepContinue
                                        : (_isCreating ? null : _createQuiz),
                                    child: _isCreating
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : Text(_currentStep < 1 ? 'Continue' : 'Create Quiz'),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        steps: [
                          Step(
                            title: const Text('Details'),
                            content: Form(
                              key: _quizFormKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _titleController,
                                    decoration: const InputDecoration(
                                      labelText: 'Quiz Title *',
                                      hintText: 'e.g., Biology 101',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a quiz title';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _descriptionController,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                      labelText: 'Description',
                                      hintText: 'Brief description of this quiz...',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _categoryController,
                                    decoration: const InputDecoration(
                                      labelText: 'Category',
                                      hintText: 'e.g., Science, History, Math',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Step(
                            title: const Text('Questions'),
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add Questions',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Add at least one question to your quiz',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ..._questions.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final question = entry.value;
                                  return _buildQuestionCard(index, question);
                                }),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _addQuestion,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Question'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, QuestionFormData question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Flashcard toggle
                    ChoiceChip(
                      label: const Text('Flashcard'),
                      selected: question.isFlashcard,
                      onSelected: (selected) {
                        setState(() {
                          question.isFlashcard = selected;
                          if (selected) {
                            question.correctAnswerIndex = 0;
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removeQuestion(index),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: question.questionController,
              decoration: const InputDecoration(
                labelText: 'Question',
                hintText: 'Enter your question here',
              ),
            ),
            const SizedBox(height: 16),
            if (question.isFlashcard)
              TextFormField(
                controller: question.backController,
                decoration: const InputDecoration(
                  labelText: 'Answer (Back of card)',
                  hintText: 'Enter the answer here',
                ),
              )
            else
              Column(
                children: [
                  ...question.options.asMap().entries.map((entry) {
                    final optIndex = entry.key;
                    final option = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: optIndex,
                            groupValue: question.correctAnswerIndex,
                            onChanged: (value) {
                              setState(() {
                                question.correctAnswerIndex = value!;
                              });
                            },
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: option,
                              decoration: InputDecoration(
                                labelText: 'Option ${optIndex + 1}',
                                hintText: optIndex == 0 
                                    ? 'Enter correct answer' 
                                    : 'Enter option',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class QuestionFormData {
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> options = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final TextEditingController backController = TextEditingController();
  int correctAnswerIndex = 0;
  bool isFlashcard = false;
}
