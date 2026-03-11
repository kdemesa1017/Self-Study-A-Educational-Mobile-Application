import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';
import 'local_storage_service.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  final _uuid = const Uuid();

  // Check if device is online
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Create a new quiz
  Future<QuizModel> createQuiz({
    required String userId,
    required String title,
    String? description,
    String? category,
  }) async {
    final quiz = QuizModel(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      description: description,
      questionIds: [],
      createdAt: DateTime.now(),
      lastModifiedAt: DateTime.now(),
      isSynced: false,
      category: category,
    );

    // Save to local storage
    await LocalStorageService.saveQuiz(quiz);

    // Try to sync to Firestore if online
    if (await isOnline()) {
      try {
        await _firestore.collection('quizzes').doc(quiz.id).set(quiz.toFirestore());
        final syncedQuiz = quiz.copyWith(isSynced: true);
        await LocalStorageService.saveQuiz(syncedQuiz);
        return syncedQuiz;
      } catch (e) {
        // Will sync later
      }
    }

    return quiz;
  }

  // Add question to quiz
  Future<QuestionModel> addQuestion({
    required String quizId,
    required String questionText,
    required List<String> options,
    required int correctAnswerIndex,
    bool isFlashcard = false,
    String? flashcardBack,
  }) async {
    final question = QuestionModel(
      id: _uuid.v4(),
      quizId: quizId,
      questionText: questionText,
      options: options,
      correctAnswerIndex: correctAnswerIndex,
      isFlashcard: isFlashcard,
      flashcardBack: flashcardBack,
      createdAt: DateTime.now(),
    );

    // Save question to local storage
    await LocalStorageService.saveQuestion(question);

    // Update quiz with new question ID
    final quiz = LocalStorageService.getQuiz(quizId);
    if (quiz != null) {
      final updatedQuestionIds = [...quiz.questionIds, question.id];
      final updatedQuiz = quiz.copyWith(
        questionIds: updatedQuestionIds,
        lastModifiedAt: DateTime.now(),
        isSynced: false,
      );
      await LocalStorageService.saveQuiz(updatedQuiz);
    }

    // Try to sync if online
    if (await isOnline()) {
      try {
        await _firestore.collection('questions').doc(question.id).set(question.toFirestore());
        await _syncQuiz(quizId);
      } catch (e) {
        // Will sync later
      }
    }

    return question;
  }

  // Update quiz
  Future<QuizModel?> updateQuiz({
    required String quizId,
    String? title,
    String? description,
    String? category,
  }) async {
    final quiz = LocalStorageService.getQuiz(quizId);
    if (quiz == null) return null;

    final updatedQuiz = quiz.copyWith(
      title: title ?? quiz.title,
      description: description ?? quiz.description,
      category: category ?? quiz.category,
      lastModifiedAt: DateTime.now(),
      isSynced: false,
    );

    await LocalStorageService.saveQuiz(updatedQuiz);

    // Try to sync if online
    if (await isOnline()) {
      try {
        await _syncQuiz(quizId);
      } catch (e) {
        // Will sync later
      }
    }

    return updatedQuiz;
  }

  // Update question
  Future<QuestionModel?> updateQuestion({
    required String questionId,
    String? questionText,
    List<String>? options,
    int? correctAnswerIndex,
    bool? isFlashcard,
    String? flashcardBack,
  }) async {
    final question = LocalStorageService.getQuestion(questionId);
    if (question == null) return null;

    final updatedQuestion = question.copyWith(
      questionText: questionText ?? question.questionText,
      options: options ?? question.options,
      correctAnswerIndex: correctAnswerIndex ?? question.correctAnswerIndex,
      isFlashcard: isFlashcard ?? question.isFlashcard,
      flashcardBack: flashcardBack ?? question.flashcardBack,
    );

    await LocalStorageService.saveQuestion(updatedQuestion);

    // Mark quiz as unsynced
    final quiz = LocalStorageService.getQuiz(question.quizId);
    if (quiz != null) {
      final updatedQuiz = quiz.copyWith(
        lastModifiedAt: DateTime.now(),
        isSynced: false,
      );
      await LocalStorageService.saveQuiz(updatedQuiz);
    }

    // Try to sync if online
    if (await isOnline()) {
      try {
        await _firestore.collection('questions').doc(questionId).update(updatedQuestion.toFirestore());
        await _syncQuiz(question.quizId);
      } catch (e) {
        // Will sync later
      }
    }

    return updatedQuestion;
  }

  // Delete question
  Future<void> deleteQuestion(String questionId) async {
    final question = LocalStorageService.getQuestion(questionId);
    if (question == null) return;

    // Remove from quiz
    final quiz = LocalStorageService.getQuiz(question.quizId);
    if (quiz != null) {
      final updatedQuestionIds = quiz.questionIds.where((id) => id != questionId).toList();
      final updatedQuiz = quiz.copyWith(
        questionIds: updatedQuestionIds,
        lastModifiedAt: DateTime.now(),
        isSynced: false,
      );
      await LocalStorageService.saveQuiz(updatedQuiz);
    }

    // Delete from local storage
    await LocalStorageService.deleteQuestion(questionId);

    // Try to sync if online
    if (await isOnline()) {
      try {
        await _firestore.collection('questions').doc(questionId).delete();
        await _syncQuiz(question.quizId);
      } catch (e) {
        // Will sync later
      }
    }
  }

  // Delete quiz
  Future<void> deleteQuiz(String quizId) async {
    await LocalStorageService.deleteQuiz(quizId);

    // Try to sync if online
    if (await isOnline()) {
      try {
        await _firestore.collection('quizzes').doc(quizId).delete();
      } catch (e) {
        // Will sync later
      }
    }
  }

  // Get user's quizzes
  List<QuizModel> getUserQuizzes(String userId) {
    return LocalStorageService.getUserQuizzes(userId);
  }

  // Get quiz with questions
  (QuizModel?, List<QuestionModel>) getQuizWithQuestions(String quizId) {
    final quiz = LocalStorageService.getQuiz(quizId);
    if (quiz == null) return (null, []);

    final questions = LocalStorageService.getQuestionsForQuiz(quizId);
    return (quiz, questions);
  }

  // Sync all unsynced data
  Future<void> syncAllData(String userId) async {
    if (!await isOnline()) return;

    try {
      // Get all unsynced quizzes
      final unsyncedQuizzes = LocalStorageService.getUnsyncedQuizzes();

      for (final quiz in unsyncedQuizzes) {
        await _syncQuiz(quiz.id);
      }

      // Fetch quizzes from Firestore
      final snapshot = await _firestore
          .collection('quizzes')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        final firestoreQuiz = QuizModel.fromFirestore(doc.data());
        final localQuiz = LocalStorageService.getQuiz(firestoreQuiz.id);

        // Use Firestore data if it's newer
        if (localQuiz == null || 
            (firestoreQuiz.lastModifiedAt != null && 
             (localQuiz.lastModifiedAt == null || 
              firestoreQuiz.lastModifiedAt!.isAfter(localQuiz.lastModifiedAt!)))) {
          await LocalStorageService.saveQuiz(firestoreQuiz.copyWith(isSynced: true));

          // Fetch questions for this quiz
          final questionsSnapshot = await _firestore
              .collection('questions')
              .where('quizId', isEqualTo: firestoreQuiz.id)
              .get();

          for (final qDoc in questionsSnapshot.docs) {
            final question = QuestionModel.fromFirestore(qDoc.data());
            await LocalStorageService.saveQuestion(question);
          }
        }
      }

      await LocalStorageService.saveLastSyncTime(DateTime.now());
    } catch (e) {
      // Sync failed, will try again later
    }
  }

  // Sync a single quiz
  Future<void> _syncQuiz(String quizId) async {
    final quiz = LocalStorageService.getQuiz(quizId);
    if (quiz == null) return;

    try {
      await _firestore.collection('quizzes').doc(quizId).set(quiz.toFirestore());
      
      // Sync all questions for this quiz
      final questions = LocalStorageService.getQuestionsForQuiz(quizId);
      for (final question in questions) {
        await _firestore.collection('questions').doc(question.id).set(question.toFirestore());
      }

      final syncedQuiz = quiz.copyWith(isSynced: true);
      await LocalStorageService.saveQuiz(syncedQuiz);
    } catch (e) {
      // Will sync later
    }
  }

  // Update quiz statistics after study session
  Future<void> updateQuizStats(String quizId, int score, int totalQuestions) async {
    final quiz = LocalStorageService.getQuiz(quizId);
    if (quiz == null) return;

    final newStudyCount = (quiz.studyCount ?? 0) + 1;
    final scorePercentage = score / totalQuestions;
    final newAverageScore = ((quiz.averageScore ?? 0) * (newStudyCount - 1) + scorePercentage) / newStudyCount;

    final updatedQuiz = quiz.copyWith(
      studyCount: newStudyCount,
      averageScore: newAverageScore,
      lastModifiedAt: DateTime.now(),
      isSynced: false,
    );

    await LocalStorageService.saveQuiz(updatedQuiz);

    if (await isOnline()) {
      try {
        await _syncQuiz(quizId);
      } catch (e) {
        // Will sync later
      }
    }
  }

  // Search quizzes
  List<QuizModel> searchQuizzes(String query, String userId) {
    final quizzes = LocalStorageService.getUserQuizzes(userId);
    final lowerQuery = query.toLowerCase();

    return quizzes.where((quiz) {
      return quiz.title.toLowerCase().contains(lowerQuery) ||
          (quiz.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          (quiz.category?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}
