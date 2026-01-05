// lib/models/lesson_model.dart

class Lesson {
  final int id;
  final String name;
  final String? icon; // Eksik olan icon alanı eklendi

  Lesson({
    required this.id,
    required this.name,
    this.icon, // Constructor'a eklendi
  });

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'] as int,
      name: map['name'] as String,
      icon: map['icon'] as String?, // fromMap metoduna eklendi
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon, // toMap metoduna eklendi
    };
  }
}
