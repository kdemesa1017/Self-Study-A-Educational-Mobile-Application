import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';

class LocalStorageService {
  static const String userBoxName = 'users';
  static const String quizBoxName = 'quizzes';
  static const String questionBoxName = 'questions';
  static const String settingsBoxName = 'settings';

  static Box<UserModel>? _userBox;
  static Box<QuizModel>? _quizBox;
  static Box<QuestionModel>? _questionBox;
  static Box<dynamic>? _settingsBox;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(QuizModelAdapter());
    Hive.registerAdapter(QuestionModelAdapter());

    // Open boxes
    _userBox = await Hive.openBox<UserModel>(userBoxName);
    _quizBox = await Hive.openBox<QuizModel>(quizBoxName);
    _questionBox = await Hive.openBox<QuestionModel>(questionBoxName);
    _settingsBox = await Hive.openBox(settingsBoxName);
  }

  // User methods
  static Future<void> saveUser(UserModel user) async {
    await _userBox?.put(user.id, user);
  }

  static UserModel? getUser(String userId) {
    return _userBox?.get(userId);
  }

  static UserModel? getCurrentUser() {
    final currentUserId = _settingsBox?.get('currentUserId') as String?;
    if (currentUserId != null) {
      return _userBox?.get(currentUserId);
    }
    return null;
  }

  static Future<void> setCurrentUser(String userId) async {
    await _settingsBox?.put('currentUserId', userId);
  }

  static Future<void> clearCurrentUser() async {
    await _settingsBox?.delete('currentUserId');
  }

  // Quiz methods
  static Future<void> saveQuiz(QuizModel quiz) async {
    await _quizBox?.put(quiz.id, quiz);
  }

  static Future<void> deleteQuiz(String quizId) async {
    // Delete associated questions first
    final quiz = _quizBox?.get(quizId);
    if (quiz != null) {
      for (final questionId in quiz.questionIds) {
        await _questionBox?.delete(questionId);
      }
    }
    await _quizBox?.delete(quizId);
  }

  static QuizModel? getQuiz(String quizId) {
    return _quizBox?.get(quizId);
  }

  static List<QuizModel> getAllQuizzes() {
    return _quizBox?.values.toList() ?? [];
  }

  static List<QuizModel> getUserQuizzes(String userId) {
    return _quizBox?.values.where((quiz) => quiz.userId == userId).toList() ?? [];
  }

  static List<QuizModel> getUnsyncedQuizzes() {
    return _quizBox?.values.where((quiz) => !quiz.isSynced).toList() ?? [];
  }

  // Question methods
  static Future<void> saveQuestion(QuestionModel question) async {
    await _questionBox?.put(question.id, question);
  }

  static Future<void> saveQuestions(List<QuestionModel> questions) async {
    final Map<String, QuestionModel> questionMap = {
      for (var q in questions) q.id: q
    };
    await _questionBox?.putAll(questionMap);
  }

  static QuestionModel? getQuestion(String questionId) {
    return _questionBox?.get(questionId);
  }

  static List<QuestionModel> getQuestionsForQuiz(String quizId) {
    return _questionBox?.values.where((q) => q.quizId == quizId).toList() ?? [];
  }

  static Future<void> deleteQuestion(String questionId) async {
    await _questionBox?.delete(questionId);
  }

  // Settings methods
  static Future<void> setOfflineMode(bool isOffline) async {
    await _settingsBox?.put('isOfflineMode', isOffline);
  }

  static bool getOfflineMode() {
    return _settingsBox?.get('isOfflineMode') ?? false;
  }

  static Future<void> saveLastSyncTime(DateTime time) async {
    await _settingsBox?.put('lastSyncTime', time.toIso8601String());
  }

  static DateTime? getLastSyncTime() {
    final timeStr = _settingsBox?.get('lastSyncTime') as String?;
    if (timeStr != null) {
      return DateTime.parse(timeStr);
    }
    return null;
  }

  // Clear all data
  static Future<void> clearAllData() async {
    await _userBox?.clear();
    await _quizBox?.clear();
    await _questionBox?.clear();
    await _settingsBox?.clear();
  }
}
