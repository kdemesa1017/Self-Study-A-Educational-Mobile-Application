import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';
import '../models/user_model.dart';
import '../models/pending_quiz_operation.dart';

/// Hive-backed local cache for quizzes, questions and user profile.
///
/// All data is stored as plain JSON strings so we don't need generated
/// Hive type adapters or any code-generation step.
class LocalQuizStore {
  static const _quizBox = 'lqs_quizzes';
  static const _questionBox = 'lqs_questions';
  static const _userBox = 'lqs_user';
  static const _streakBox = 'lqs_streak';
  static const _pendingBox = 'lqs_pending_ops';

  // ── Initialisation ──────────────────────────────────────────────────────────

  static Future<void> init() async {
    await Hive.openBox<String>(_quizBox);
    await Hive.openBox<String>(_questionBox);
    await Hive.openBox<String>(_userBox);
    await Hive.openBox<String>(_streakBox);
    await Hive.openBox<String>(_pendingBox);
  }

  // ── Quizzes ─────────────────────────────────────────────────────────────────

  Future<void> saveQuizzes(String userId, List<QuizModel> quizzes) async {
    final box = Hive.box<String>(_quizBox);
    final encoded = jsonEncode(quizzes.map((q) => q.toFirestore()).toList());
    await box.put(userId, encoded);
  }

  Future<List<QuizModel>> loadQuizzes(String userId) async {
    final box = Hive.box<String>(_quizBox);
    final raw = box.get(userId);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => QuizModel.fromFirestore(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertQuiz(String userId, QuizModel quiz) async {
    final quizzes = await loadQuizzes(userId);
    final index = quizzes.indexWhere((q) => q.id == quiz.id);
    if (index >= 0) {
      quizzes[index] = quiz;
    } else {
      quizzes.insert(0, quiz);
    }
    await saveQuizzes(userId, quizzes);
  }

  Future<void> removeQuiz(String userId, String quizId) async {
    final quizzes = await loadQuizzes(userId);
    quizzes.removeWhere((q) => q.id == quizId);
    await saveQuizzes(userId, quizzes);
    await deleteQuestions(quizId);
  }

  Future<QuizModel?> findQuiz(String userId, String quizId) async {
    final quizzes = await loadQuizzes(userId);
    for (final quiz in quizzes) {
      if (quiz.id == quizId) return quiz;
    }
    return null;
  }

  // ── Questions ────────────────────────────────────────────────────────────────

  Future<void> saveQuestions(
    String quizId,
    List<QuestionModel> questions,
  ) async {
    final box = Hive.box<String>(_questionBox);
    final encoded = jsonEncode(
      questions.map((q) => q.toFirestore()).toList(),
    );
    await box.put(quizId, encoded);
  }

  Future<List<QuestionModel>> loadQuestions(String quizId) async {
    final box = Hive.box<String>(_questionBox);
    final raw = box.get(quizId);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => QuestionModel.fromFirestore(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertQuestion(QuestionModel question) async {
    final questions = await loadQuestions(question.quizId);
    final index = questions.indexWhere((q) => q.id == question.id);
    if (index >= 0) {
      questions[index] = question;
    } else {
      questions.add(question);
    }
    await saveQuestions(question.quizId, questions);
  }

  Future<void> removeQuestion(String quizId, String questionId) async {
    final questions = await loadQuestions(quizId);
    questions.removeWhere((q) => q.id == questionId);
    await saveQuestions(quizId, questions);
  }

  Future<void> deleteQuestions(String quizId) async {
    final box = Hive.box<String>(_questionBox);
    await box.delete(quizId);
  }

  Future<void> appendQuestionIdToQuiz(
    String userId,
    String quizId,
    String questionId,
  ) async {
    final quiz = await findQuiz(userId, quizId);
    if (quiz == null) return;

    if (quiz.questionIds.contains(questionId)) return;

    await upsertQuiz(
      userId,
      quiz.copyWith(
        questionIds: [...quiz.questionIds, questionId],
        lastModifiedAt: DateTime.now(),
      ),
    );
  }

  Future<void> removeQuestionIdFromQuiz(
    String userId,
    String quizId,
    String questionId,
  ) async {
    final quiz = await findQuiz(userId, quizId);
    if (quiz == null) return;

    await upsertQuiz(
      userId,
      quiz.copyWith(
        questionIds: quiz.questionIds.where((id) => id != questionId).toList(),
        lastModifiedAt: DateTime.now(),
      ),
    );
  }

  /// Keeps quiz metadata in sync with cached question lists.
  Future<List<QuizModel>> reconcileQuestionCounts(String userId) async {
    final quizzes = await loadQuizzes(userId);
    var changed = false;

    final reconciled = quizzes.map((quiz) {
      final cachedQuestions = Hive.box<String>(_questionBox).get(quiz.id);
      if (cachedQuestions == null) return quiz;

      final questions = (jsonDecode(cachedQuestions) as List<dynamic>)
          .map((e) => QuestionModel.fromFirestore(e as Map<String, dynamic>))
          .toList();
      if (questions.isEmpty) return quiz;

      final questionIds = questions.map((q) => q.id).toList();
      if (questionIds.length == quiz.questionIds.length &&
          questionIds.every(quiz.questionIds.contains)) {
        return quiz;
      }

      changed = true;
      return quiz.copyWith(
        questionIds: questionIds,
        lastModifiedAt: DateTime.now(),
      );
    }).toList();

    if (changed) {
      await saveQuizzes(userId, reconciled);
    }
    return reconciled;
  }

  // ── User profile ─────────────────────────────────────────────────────────────

  Future<void> saveUser(UserModel user) async {
    final box = Hive.box<String>(_userBox);
    await box.put(user.id, jsonEncode(user.toFirestore()));
  }

  Future<UserModel?> loadUser(String userId) async {
    final box = Hive.box<String>(_userBox);
    final raw = box.get(userId);
    if (raw == null) return null;
    return UserModel.fromFirestore(jsonDecode(raw) as Map<String, dynamic>);
  }

  // ── Streak (local pending sync) ──────────────────────────────────────────────

  Future<void> savePendingStreak(String userId, int count, String date) async {
    final box = Hive.box<String>(_streakBox);
    await box.put(userId, jsonEncode({'count': count, 'date': date}));
  }

  Future<Map<String, dynamic>?> loadPendingStreak(String userId) async {
    final box = Hive.box<String>(_streakBox);
    final raw = box.get(userId);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clearPendingStreak(String userId) async {
    final box = Hive.box<String>(_streakBox);
    await box.delete(userId);
  }

  // ── Pending quiz operations ──────────────────────────────────────────────────

  Future<List<PendingQuizOperation>> loadPendingOperations(String userId) async {
    final box = Hive.box<String>(_pendingBox);
    final raw = box.get(userId);
    if (raw == null) return [];

    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map(
          (e) => PendingQuizOperation.fromJson(e as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> savePendingOperations(
    String userId,
    List<PendingQuizOperation> operations,
  ) async {
    final box = Hive.box<String>(_pendingBox);
    final encoded = jsonEncode(operations.map((op) => op.toJson()).toList());
    await box.put(userId, encoded);
  }

  Future<void> addPendingOperation(
    String userId,
    PendingQuizOperation operation,
  ) async {
    final operations = await loadPendingOperations(userId);
    operations.removeWhere((op) => op.id == operation.id);
    operations.add(operation);
    await savePendingOperations(userId, operations);
  }

  Future<void> removePendingOperation(String userId, String operationId) async {
    final operations = await loadPendingOperations(userId);
    operations.removeWhere((op) => op.id == operationId);
    await savePendingOperations(userId, operations);
  }

  Future<void> clearPendingOperations(String userId) async {
    final box = Hive.box<String>(_pendingBox);
    await box.delete(userId);
  }

  Future<void> clearUserCache(String userId) async {
    await Hive.box<String>(_quizBox).delete(userId);
    await Hive.box<String>(_userBox).delete(userId);
    await Hive.box<String>(_streakBox).delete(userId);
    await clearPendingOperations(userId);
  }
}
