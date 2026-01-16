// lib/models/profile_model.dart

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
  
  // GÜNCELLENEN ALANLAR
  final int? gradeId;
  final String? schoolName;
  final String? branch;
  final bool isVerified;
  final String? title;
  final int? cityId;
  final int? districtId;

  // İlişkili veriler (bunlar join ile geldiğinde doldurulur)
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
    this.gradeId,
    this.schoolName,
    this.branch,
    this.isVerified = false,
    this.title,
    this.cityId,
    this.districtId,
    this.grade,
    this.city,
    this.district,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
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
      
      // GÜNCELLENEN ALANLAR
      gradeId: map['grade_id'],
      schoolName: map['school_name'],
      branch: map['branch'],
      isVerified: map['is_verified'] ?? false,
      title: map['title'],
      cityId: map['city_id'],
      districtId: map['district_id'],
      
      // İlişkili veriler
      grade: gradeData != null ? GradeInfo(id: gradeData['id'], name: gradeData['name']) : null,
      city: cityData != null ? CityInfo(id: cityData['id'], name: cityData['name']) : null,
      district: districtData != null ? DistrictInfo(id: districtData['id'], name: districtData['name']) : null,
    );
  }
}
