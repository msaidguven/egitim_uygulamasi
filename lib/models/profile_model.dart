// lib/models/profile_model.dart

// İlişkili tablolardan gelen verileri tutmak için yardımcı sınıflar
class GradeInfo {
  final int id;
  final String name;
  GradeInfo({required this.id, required this.name});
}

class CityInfo {
  final int id;
  final String name;
  CityInfo({required this.id, required this.name});
}

class DistrictInfo {
  final int id;
  final String name;
  DistrictInfo({required this.id, required this.name});
}


class Profile {
  final String id;
  final String? fullName;
  final String? username;
  final String? gender;
  final DateTime? birthDate;
  final String? about;
  final String? role;
  final String? avatarUrl;
  final String? coverPhotoUrl;
  final String? schoolName;
  final String? branch;
  final bool isVerified;
  final String? title;

  // İlişkili veriler
  final GradeInfo? grade;
  final CityInfo? city;
  final DistrictInfo? district;

  Profile({
    required this.id,
    this.fullName,
    this.username,
    this.gender,
    this.birthDate,
    this.about,
    this.role,
    this.avatarUrl,
    this.coverPhotoUrl,
    this.schoolName,
    this.branch,
    this.isVerified = false,
    this.title,
    this.grade,
    this.city,
    this.district,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    // İlişkili tabloların null olup olmadığını kontrol et
    final gradeData = map['grades'];
    final cityData = map['cities'];
    final districtData = map['districts'];

    return Profile(
      id: map['id'],
      fullName: map['full_name'],
      username: map['username'],
      gender: map['gender'],
      birthDate: map['birth_date'] != null ? DateTime.tryParse(map['birth_date']) : null,
      about: map['about'],
      role: map['role'],
      avatarUrl: map['avatar_url'],
      coverPhotoUrl: map['cover_photo_url'],
      schoolName: map['school_name'],
      branch: map['branch'],
      isVerified: map['is_verified'] ?? false,
      title: map['title'],
      
      // Null kontrolü yaparak ilişkili verileri ata
      grade: gradeData != null ? GradeInfo(id: gradeData['id'], name: gradeData['name']) : null,
      city: cityData != null ? CityInfo(id: cityData['id'], name: cityData['name']) : null,
      district: districtData != null ? DistrictInfo(id: districtData['id'], name: districtData['name']) : null,
    );
  }
}
