// lib/models/outcome_model.dart

class Outcome {
  final int id;
  final String text;
  final int topicId;

  Outcome({required this.id, required this.text, required this.topicId});

  factory Outcome.fromMap(Map<String, dynamic> map) {
    return Outcome(
      id: map['id'] as int,
      text: map['text'] as String,
      topicId: map['topic_id'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {'text': text, 'topic_id': topicId};
  }
}
