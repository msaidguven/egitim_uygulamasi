// lib/models/lesson_model.dart

class Lesson {
  final int id;
  final String name;
  final int? gradeId; // Sınıf ID'si null olabilir.
  final String? gradeName; // Görüntüleme için JOIN ile gelen sınıf adı

  Lesson({required this.id, required this.name, this.gradeId, this.gradeName});

  // Supabase'den gelen veriyi Lesson nesnesine dönüştürür.
  // 'grades' alanı, 'grade_id' üzerinden yapılan bir JOIN sorgusunun sonucudur.
  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'] as int,
      name: map['name'] as String,
      gradeId: map['grade_id'] as int?, // Null olabileceğini belirtiyoruz.
      // 'grades' alanı bir Map ise ve 'name' anahtarını içeriyorsa gradeName'i al.
      // Değilse null ata. Bu, 'grades' null olduğunda veya beklenen yapıda olmadığında
      // çökmesini engeller.
      gradeName: (map['grades'] is Map)
          ? map['grades']['name'] as String?
          : null,
    );
  }

  // Lesson nesnesini Supabase'e göndermek için Map'e dönüştürür.
  Map<String, dynamic> toMap() {
    // 'grade_id' alanı 'lessons' tablosunda bulunmuyor.
    // Bu yüzden sadece 'lessons' tablosuna ait alanları gönderiyoruz.
    // Sınıf ilişkisi 'lesson_grades' tablosu üzerinden ayrıca yönetilmelidir.
    return {'name': name};
  }
}
