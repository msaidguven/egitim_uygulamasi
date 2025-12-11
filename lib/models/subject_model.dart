// lib/models/subject_model.dart

class Subject {
  final int id;
  final int? gradeId;
  final String name;
  final String? icon;
  final String? description;
  final int orderNo;

  Subject({
    required this.id,
    this.gradeId,
    required this.name,
    this.icon,
    this.description,
    required this.orderNo,
  });

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as int,
      gradeId: map['grade_id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      description: map['description'] as String?,
      orderNo: map['order_no'] as int,
    );
  }
}
