// lib/models/outcome_model.dart

class Outcome {
  final int id;
  final String description;
  final int topicId;
  final int orderIndex;

  Outcome({
    required this.id,
    required this.description,
    required this.topicId,
    required this.orderIndex,
  });

  factory Outcome.fromMap(Map<String, dynamic> map) {
    return Outcome(
      id: map['id'] as int,
      description: map['description'] as String? ?? map['text'] as String,
      topicId: map['topic_id'] as int,
      orderIndex: map['order_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'topic_id': topicId,
      'order_index': orderIndex,
    };
  }
}
