import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/quiz_service.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';

final quizServiceProvider = Provider<QuizService>((ref) => QuizService());

final userQuizzesProvider =
    StateNotifierProvider.family<QuizNotifier, AsyncValue<List<QuizModel>>, String>(
  (ref, userId) => QuizNotifier(ref.watch(quizServiceProvider), userId),
);

final currentQuizProvider = StateProvider<QuizModel?>((ref) => null);
final currentQuestionsProvider = StateProvider<List<QuestionModel>>((ref) => []);

class QuizNotifier extends StateNotifier<AsyncValue<List<QuizModel>>> {
  final QuizService _quizService;
  final String _userId;

  QuizNotifier(this._quizService, this._userId)
      : super(const AsyncValue.loading()) {
    loadQuizzes();
  }

  Future<void> loadQuizzes() async {
    state = const AsyncLoading<List<QuizModel>>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => _quizService.getUserQuizzes(_userId),
    );
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
    await loadQuizzes();
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
    await loadQuizzes();
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
    await loadQuizzes();
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
    await loadQuizzes();
    return question;
  }

  Future<void> deleteQuestion(String questionId) async {
    await _quizService.deleteQuestion(questionId);
    await loadQuizzes();
  }

  Future<void> deleteQuiz(String quizId) async {
    await _quizService.deleteQuiz(quizId);
    await loadQuizzes();
  }

  Future<(QuizModel?, List<QuestionModel>)> getQuizWithQuestions(String quizId) {
    return _quizService.getQuizWithQuestions(quizId);
  }

  Future<void> refreshQuizzes() async {
    await loadQuizzes();
  }

  Future<void> updateQuizStats(String quizId, int score, int totalQuestions) async {
    await _quizService.updateQuizStats(quizId, score, totalQuestions);
    await loadQuizzes();
  }

  Future<List<QuizModel>> searchQuizzes(String query) {
    return _quizService.searchQuizzes(query, _userId);
  }
}

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredQuizzesProvider =
    Provider.family<AsyncValue<List<QuizModel>>, String>((ref, userId) {
  final query = ref.watch(searchQueryProvider);
  final quizzesAsync = ref.watch(userQuizzesProvider(userId));

  return quizzesAsync.whenData((quizzes) {
    if (query.isEmpty) return quizzes;
    final lowerQuery = query.toLowerCase();
    return quizzes.where((quiz) {
      return quiz.title.toLowerCase().contains(lowerQuery) ||
          (quiz.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          (quiz.category?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  });
});
