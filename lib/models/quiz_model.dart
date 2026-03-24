class QuizModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final List<String> questionIds;
  final DateTime createdAt;
  final DateTime? lastModifiedAt;
  final String? category;
  final int? studyCount;
  final double? averageScore;

  QuizModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.questionIds,
    required this.createdAt,
    this.lastModifiedAt,
    this.category,
    this.studyCount = 0,
    this.averageScore = 0.0,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'questionIds': questionIds,
      'createdAt': createdAt.toIso8601String(),
      'lastModifiedAt': lastModifiedAt?.toIso8601String(),
      'category': category,
      'studyCount': studyCount,
      'averageScore': averageScore,
    };
  }

  factory QuizModel.fromFirestore(Map<String, dynamic> data) {
    return QuizModel(
      id: data['id'] as String,
      userId: data['userId'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      questionIds: List<String>.from(data['questionIds'] as List),
      createdAt: DateTime.parse(data['createdAt'] as String),
      lastModifiedAt: data['lastModifiedAt'] != null
          ? DateTime.parse(data['lastModifiedAt'] as String)
          : null,
      category: data['category'] as String?,
      studyCount: data['studyCount'] as int? ?? 0,
      averageScore: (data['averageScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  QuizModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    List<String>? questionIds,
    DateTime? createdAt,
    DateTime? lastModifiedAt,
    String? category,
    int? studyCount,
    double? averageScore,
  }) {
    return QuizModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      questionIds: questionIds ?? this.questionIds,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      category: category ?? this.category,
      studyCount: studyCount ?? this.studyCount,
      averageScore: averageScore ?? this.averageScore,
    );
  }
}
