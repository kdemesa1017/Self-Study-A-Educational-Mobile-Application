import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';

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
          content: Text('Add at least one question'),
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
      if (!q.isFlashcard && q.options.any((o) => o.text.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all options for question ${i + 1}')),
        );
        return;
      }
    }

    setState(() => _isCreating = true);

    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _isCreating = false);
      return;
    }

    // Create quiz
    final quiz = await ref.read(userQuizzesProvider(user.id).notifier).createQuiz(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      category: _categoryController.text.trim().isEmpty 
          ? null 
          : _categoryController.text.trim(),
    );

    if (quiz == null) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create quiz'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Add all questions
    for (final q in _questions) {
      await ref.read(userQuizzesProvider(user.id).notifier).addQuestion(
        quizId: quiz.id,
        questionText: q.questionController.text.trim(),
        options: q.isFlashcard 
            ? [q.backController.text.trim()] 
            : q.options.map((o) => o.text).toList(),
        correctAnswerIndex: q.isFlashcard ? 0 : q.correctAnswerIndex,
        isFlashcard: q.isFlashcard,
        flashcardBack: q.isFlashcard ? q.backController.text.trim() : null,
      );
    }

    setState(() => _isCreating = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz created successfully!')),
      );
      context.go('/my-quizzes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stepper(
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
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (_currentStep < 1)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: const Text('Next'),
                  )
                else
                  ElevatedButton(
                    onPressed: _isCreating ? null : _createQuiz,
                    child: _isCreating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Quiz'),
                  ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Quiz Details'),
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
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add at least one question to your quiz',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                ..._questions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final question = entry.value;
                  return _buildQuestionCard(index, question);
                }),
                const SizedBox(height: 16),
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
                  if (question.options.length < 4)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          question.options.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Option'),
                    ),
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
  ];
  final TextEditingController backController = TextEditingController();
  int correctAnswerIndex = 0;
  bool isFlashcard = false;
}
