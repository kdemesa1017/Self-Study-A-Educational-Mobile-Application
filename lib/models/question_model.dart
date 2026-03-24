class QuestionModel {
  final String id;
  final String quizId;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final bool isFlashcard;
  final String? flashcardBack;
  final DateTime createdAt;

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
