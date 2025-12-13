// lib/models/lesson_model.dart

class Lesson {
  final int id;
  final String name;
  final String? icon;
  final String? description;
  final int orderNo;

  Lesson({
    required this.id,
    required this.name,
    this.icon,
    this.description,
    required this.orderNo,
  });

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'] as int,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      description: map['description'] as String?,
      orderNo: map['order_no'] as int,
    );
  }
}
