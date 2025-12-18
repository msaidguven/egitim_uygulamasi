// lib/models/unit_model.dart

class Unit {
  final int id;
  final String title;
  final String? description;
  final int orderNo;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? lessonId;
  final String? lessonName;
  final int? gradeId;
  final String? gradeName;

  Unit({
    required this.id,
    required this.title,
    this.description,
    required this.orderNo,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lessonId,
    this.lessonName,
    this.gradeId,
    this.gradeName,
  });

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      orderNo: map['order_no'] as int,
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lessonId: map['lesson_id'] as int?,
      lessonName: (map['lessons'] is Map)
          ? map['lessons']['name'] as String?
          : null,
      gradeId: map['grade_id'] as int?, // Bu alan RPC'den gelmeyebilir
      gradeName: (map['grades'] is Map)
          ? map['grades']['name'] as String?
          : null, // Bu alan RPC'den gelmeyebilir
    );
  }

  Map<String, dynamic> toMap() {
    // İlişki tablosu kullanıldığı için toMap'te gradeId göndermeye gerek yok.
    return {'title': title, 'description': description, 'lesson_id': lessonId};
  }
}
