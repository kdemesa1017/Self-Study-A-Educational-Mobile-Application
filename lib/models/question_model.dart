import 'package:hive/hive.dart';

part 'question_model.g.dart';

@HiveType(typeId: 1)
class QuestionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String quizId;

  @HiveField(2)
  String questionText;

  @HiveField(3)
  List<String> options;

  @HiveField(4)
  int correctAnswerIndex;

  @HiveField(5)
  bool isFlashcard;

  @HiveField(6)
  String? flashcardBack;

  @HiveField(7)
  DateTime createdAt;

  QuestionModel({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    this.isFlashcard = false,
    this.flashcardBack,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'quizId': quizId,
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'isFlashcard': isFlashcard,
      'flashcardBack': flashcardBack,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory QuestionModel.fromFirestore(Map<String, dynamic> data) {
    return QuestionModel(
      id: data['id'] as String,
      quizId: data['quizId'] as String,
      questionText: data['questionText'] as String,
      options: List<String>.from(data['options'] as List),
      correctAnswerIndex: data['correctAnswerIndex'] as int,
      isFlashcard: data['isFlashcard'] as bool? ?? false,
      flashcardBack: data['flashcardBack'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }

  QuestionModel copyWith({
    String? id,
    String? quizId,
    String? questionText,
    List<String>? options,
    int? correctAnswerIndex,
    bool? isFlashcard,
    String? flashcardBack,
    DateTime? createdAt,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      isFlashcard: isFlashcard ?? this.isFlashcard,
      flashcardBack: flashcardBack ?? this.flashcardBack,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
