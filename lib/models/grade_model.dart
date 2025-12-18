// lib/models/grade_model.dart

class Grade {
  final int? id;
  final String name;
  final int orderNo;

  Grade({this.id, required this.name, required this.orderNo});

  factory Grade.fromMap(Map<String, dynamic> map) {
    return Grade(
      id: map['id'] as int,
      name: map['name'] as String,
      orderNo:
          map['order_no']
              as int, // Supabase'de genellikle 'order_no' kullanılır
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // Oluşturma sırasında id null olabilir, bu yüzden göndermiyoruz.
      // Güncelleme sırasında ise gereklidir.
      'name': name,
      'order_no': orderNo,
    };
  }
}
