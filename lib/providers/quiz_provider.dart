import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/quiz_service.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';

final quizServiceProvider = Provider<QuizService>((ref) => QuizService());

final userQuizzesProvider = StateNotifierProvider.family<QuizNotifier, List<QuizModel>, String>(
  (ref, userId) => QuizNotifier(ref.watch(quizServiceProvider), userId),
);

final currentQuizProvider = StateProvider<QuizModel?>((ref) => null);
final currentQuestionsProvider = StateProvider<List<QuestionModel>>((ref) => []);

class QuizNotifier extends StateNotifier<List<QuizModel>> {
  final QuizService _quizService;
  final String _userId;

  QuizNotifier(this._quizService, this._userId) : super([]) {
    loadQuizzes();
  }

  void loadQuizzes() {
    state = _quizService.getUserQuizzes(_userId);
  }

  Future<QuizModel?> createQuiz({
    required String title,
    String? description,
    String? category,
  }) async {
    final quiz = await _quizService.createQuiz(
      userId: _userId,
      title: title,
      description: description,
      category: category,
    );
    loadQuizzes();
    return quiz;
  }

  Future<QuestionModel> addQuestion({
    required String quizId,
    required String questionText,
    required List<String> options,
    required int correctAnswerIndex,
    bool isFlashcard = false,
    String? flashcardBack,
  }) async {
    final question = await _quizService.addQuestion(
      quizId: quizId,
      questionText: questionText,
      options: options,
      correctAnswerIndex: correctAnswerIndex,
      isFlashcard: isFlashcard,
      flashcardBack: flashcardBack,
    );
    loadQuizzes();
    return question;
  }

  Future<QuizModel?> updateQuiz({
    required String quizId,
    String? title,
    String? description,
    String? category,
  }) async {
    final quiz = await _quizService.updateQuiz(
      quizId: quizId,
      title: title,
      description: description,
      category: category,
    );
    loadQuizzes();
    return quiz;
  }

  Future<QuestionModel?> updateQuestion({
    required String questionId,
    String? questionText,
    List<String>? options,
    int? correctAnswerIndex,
    bool? isFlashcard,
    String? flashcardBack,
  }) async {
    final question = await _quizService.updateQuestion(
      questionId: questionId,
      questionText: questionText,
      options: options,
      correctAnswerIndex: correctAnswerIndex,
      isFlashcard: isFlashcard,
      flashcardBack: flashcardBack,
    );
    return question;
  }

  Future<void> deleteQuestion(String questionId) async {
    await _quizService.deleteQuestion(questionId);
    loadQuizzes();
  }

  Future<void> deleteQuiz(String quizId) async {
    await _quizService.deleteQuiz(quizId);
    loadQuizzes();
  }

  (QuizModel?, List<QuestionModel>) getQuizWithQuestions(String quizId) {
    return _quizService.getQuizWithQuestions(quizId);
  }

  Future<void> syncAllData() async {
    await _quizService.syncAllData(_userId);
    loadQuizzes();
  }

  Future<void> updateQuizStats(String quizId, int score, int totalQuestions) async {
    await _quizService.updateQuizStats(quizId, score, totalQuestions);
    loadQuizzes();
  }

  List<QuizModel> searchQuizzes(String query) {
    return _quizService.searchQuizzes(query, _userId);
  }
}

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredQuizzesProvider = Provider.family<List<QuizModel>, String>((ref, userId) {
  final query = ref.watch(searchQueryProvider);
  final allQuizzes = ref.watch(userQuizzesProvider(userId));
  
  if (query.isEmpty) return allQuizzes;
  
  final lowerQuery = query.toLowerCase();
  return allQuizzes.where((quiz) {
    return quiz.title.toLowerCase().contains(lowerQuery) ||
        (quiz.description?.toLowerCase().contains(lowerQuery) ?? false) ||
        (quiz.category?.toLowerCase().contains(lowerQuery) ?? false);
  }).toList();
});
