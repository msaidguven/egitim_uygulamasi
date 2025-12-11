// lib/models/grade_model.dart

class Grade {
  final int id;
  final String name;
  final int orderNo;

  Grade({required this.id, required this.name, required this.orderNo});

  factory Grade.fromMap(Map<String, dynamic> map) {
    return Grade(
      id: map['id'] as int,
      name: map['name'] as String,
      orderNo: map['order_no'] as int,
    );
  }
}
