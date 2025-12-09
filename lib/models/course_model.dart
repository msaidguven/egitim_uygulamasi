// lib/models/course_model.dart

class Course {
  final int id;
  final String name;
  final String description;

  Course({required this.id, required this.name, required this.description});

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
    );
  }
}
