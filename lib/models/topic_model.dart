// lib/models/topic_model.dart

class Topic {
  final int id;
  final int unitId;
  final String title;
  final String? slug;
  final int orderNo;
  final bool isActive;
  final DateTime? createdAt;

  Topic({
    required this.id,
    required this.unitId,
    required this.title,
    this.slug,
    required this.orderNo,
    required this.isActive,
    this.createdAt,
  });

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['id'] as int,
      unitId: map['unit_id'] as int,
      title: map['title'] as String? ?? '',
      slug: map['slug'] as String?,
      orderNo: map['order_no'] as int? ?? 0,
      isActive: map['is_active'] as bool? ?? false,
      createdAt: map['created_at'] == null ? null : DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'unit_id': unitId,
      'title': title,
      'slug': slug,
      'order_no': orderNo,
      'is_active': isActive,
    };
  }

  // Add equals and hashCode to allow for object comparison in Sets.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Topic &&
      other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
