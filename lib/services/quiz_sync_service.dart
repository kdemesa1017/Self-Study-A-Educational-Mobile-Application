import 'package:uuid/uuid.dart';
import '../models/pending_quiz_operation.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';
import 'connectivity_service.dart';
import 'local_quiz_store.dart';
import 'quiz_service.dart';

/// Pushes locally saved quiz changes to Firestore when connectivity returns.
class QuizSyncService {
  QuizSyncService({
    required QuizService quizService,
    required LocalQuizStore localStore,
    required ConnectivityService connectivity,
  })  : _quizService = quizService,
        _localStore = localStore,
        _connectivity = connectivity;

  final QuizService _quizService;
  final LocalQuizStore _localStore;
  final ConnectivityService _connectivity;
  final _uuid = const Uuid();

  Future<bool> get isOnline => _connectivity.isOnline;

  Future<void> syncPendingOperations(String userId) async {
    if (!await isOnline) return;

    final pending = await _localStore.loadPendingOperations(userId);
    if (pending.isEmpty) return;

    for (final operation in pending) {
      try {
        await _applyOperation(operation);
        await _localStore.removePendingOperation(userId, operation.id);
      } catch (_) {
        // Stop at the first failure so ordering stays intact.
        break;
      }
    }
  }

  Future<void> queueOrSync({
    required String userId,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    if (await isOnline) {
      try {
        await _applyOperation(
          PendingQuizOperation(
            id: _uuid.v4(),
            type: type,
            payload: payload,
            createdAt: DateTime.now(),
          ),
        );
        return;
      } catch (_) {
        // Fall through to queue when Firestore is unreachable.
      }
    }

    await _localStore.addPendingOperation(
      userId,
      PendingQuizOperation(
        id: _uuid.v4(),
        type: type,
        payload: payload,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _applyOperation(PendingQuizOperation operation) async {
    switch (operation.type) {
      case 'createQuiz':
        await _quizService.saveQuiz(
          QuizModel.fromFirestore(operation.payload),
        );
      case 'addQuestion':
        final question = QuestionModel.fromFirestore(operation.payload);
        await _quizService.saveQuestion(question);
      case 'updateQuiz':
        await _quizService.updateQuiz(
          quizId: operation.payload['quizId'] as String,
          title: operation.payload['title'] as String?,
          description: operation.payload['description'] as String?,
          category: operation.payload['category'] as String?,
        );
      case 'updateQuestion':
        await _quizService.updateQuestion(
          questionId: operation.payload['questionId'] as String,
          questionText: operation.payload['questionText'] as String?,
          options: operation.payload['options'] != null
              ? List<String>.from(operation.payload['options'] as List)
              : null,
          correctAnswerIndex: operation.payload['correctAnswerIndex'] as int?,
          isFlashcard: operation.payload['isFlashcard'] as bool?,
          flashcardBack: operation.payload['flashcardBack'] as String?,
        );
      case 'deleteQuestion':
        await _quizService.deleteQuestion(
          operation.payload['questionId'] as String,
        );
      case 'deleteQuiz':
        await _quizService.deleteQuiz(operation.payload['quizId'] as String);
      case 'updateStats':
        await _quizService.updateQuizStats(
          operation.payload['quizId'] as String,
          operation.payload['score'] as int,
          operation.payload['totalQuestions'] as int,
        );
      default:
        throw UnsupportedError('Unknown pending operation: ${operation.type}');
    }
  }
}
