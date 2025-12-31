// lib/models/lesson_model.dart

class Lesson {
  final int id;
  final String name;

  Lesson({required this.id, required this.name});

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}
