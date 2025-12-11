// lib/models/profile_model.dart

class Profile {
  final String id;
  final String fullName;
  final String username;
  final String? gender;
  final DateTime? birthDate;

  Profile({
    required this.id,
    required this.fullName,
    required this.username,
    this.gender,
    this.birthDate,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      fullName: map['full_name'],
      username: map['username'],
      gender: map['gender'],
      birthDate: map['birth_date'] != null
          ? DateTime.tryParse(map['birth_date'])
          : null,
    );
  }
}
