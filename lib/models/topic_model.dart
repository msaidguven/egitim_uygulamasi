// lib/models/topic_model.dart

class Topic {
  final int id;
  final String name;
  final int unitId;

  Topic({required this.id, required this.name, required this.unitId});

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['id'] as int,
      name: map['name'] as String,
      unitId: map['unit_id'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'unit_id': unitId};
  }
}
