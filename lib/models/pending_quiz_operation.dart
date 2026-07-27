class PendingQuizOperation {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const PendingQuizOperation({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PendingQuizOperation.fromJson(Map<String, dynamic> data) {
    return PendingQuizOperation(
      id: data['id'] as String,
      type: data['type'] as String,
      payload: Map<String, dynamic>.from(data['payload'] as Map),
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }
}
