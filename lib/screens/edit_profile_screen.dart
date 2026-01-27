// lib/screens/edit_profile_screen.dart

import 'dart:io';
import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _profileViewModel = ProfileViewModel();

  late final TextEditingController _fullNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _aboutController;
  late final TextEditingController _schoolController;

  List<CityInfo> _cities = [];
  List<DistrictInfo> _districts = [];
  List<GradeInfo> _grades = [];

  CityInfo? _selectedCity;
  DistrictInfo? _selectedDistrict;
  GradeInfo? _selectedGrade;

  String? _avatarUrl;
  bool _isUploading = false;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.profile.fullName);
    _usernameController = TextEditingController(text: widget.profile.username);
    _aboutController = TextEditingController(text: widget.profile.about);
    _schoolController = TextEditingController(text: widget.profile.schoolName);
    _avatarUrl = widget.profile.avatarUrl;

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final citiesFuture = _fetchCities();
      final gradesFuture = _fetchGrades();
      await Future.wait([citiesFuture, gradesFuture]);

      if (widget.profile.city != null) {
        _selectedCity = _cities.firstWhere((c) => c.id == widget.profile.city!.id, orElse: () => _cities.first);
        await _fetchDistricts(_selectedCity!.id);
        if (widget.profile.district != null) {
          _selectedDistrict = _districts.firstWhere((d) => d.id == widget.profile.district!.id, orElse: () => _districts.first);
        }
      }

      if (widget.profile.grade != null) {
        _selectedGrade = _grades.firstWhere((g) => g.id == widget.profile.grade!.id, orElse: () => _grades.first);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veriler yüklenemedi: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCities() async {
    final response = await _supabase.from('cities').select('id, name').order('name', ascending: true);
    _cities = (response as List).map((e) => CityInfo(id: e['id'], name: e['name'])).toList();
  }

  Future<void> _fetchGrades() async {
    final response = await _supabase.from('grades').select('id, name').order('order_no');
    _grades = (response as List).map((e) => GradeInfo(id: e['id'], name: e['name'])).toList();
  }

  Future<void> _fetchDistricts(int cityId) async {
    final response = await _supabase.from('districts').select('id, name').eq('city_id', cityId).order('name', ascending: true);
    if (mounted) {
      setState(() {
        _districts = (response as List).map((e) => DistrictInfo(id: e['id'], name: e['name'])).toList();
        _selectedDistrict = null;
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    setState(() => _isUploading = true);
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 300, maxHeight: 300);

    if (imageFile == null) {
      setState(() => _isUploading = false);
      return;
    }

    try {
      final file = File(imageFile.path);
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final filePath = 'public/${_supabase.auth.currentUser!.id}/$fileName';

      await _supabase.storage.from('avatars').upload(filePath, file);
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

      setState(() => _avatarUrl = imageUrl);
      await _profileViewModel.updateProfile({'avatar_url': imageUrl});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resim yüklenemedi: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updates = {
      'full_name': _fullNameController.text,
      'about': _aboutController.text,
      'school_name': _schoolController.text,
      'grade_id': _selectedGrade?.id,
      'city_id': _selectedCity?.id,
      'district_id': _selectedDistrict?.id,
    };

    final success = await _profileViewModel.updateProfile(updates);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profil başarıyla güncellendi!' : 'Bir hata oluştu.'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      if (success) Navigator.of(context).pop(true);
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Avatar Section
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _avatarUrl != null
                          ? ClipOval(
                        child: Image.network(
                          _avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar(isDarkMode);
                          },
                        ),
                      )
                          : _buildDefaultAvatar(isDarkMode),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploading ? null : _pickAndUploadAvatar,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDarkMode ? Colors.black : Colors.white,
                              width: 3,
                            ),
                          ),
                          child: _isUploading
                              ? Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                              : Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Text(
                  'Profil Fotoğrafı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 32),

                // Full Name
                _buildTextField(
                  label: 'İsim Soyisim',
                  controller: _fullNameController,
                  icon: Icons.person_outline_rounded,
                  isDarkMode: isDarkMode,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen isim ve soyisim girin';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Username (read-only)
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: _usernameController,
                    readOnly: true,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    decoration: InputDecoration(
                      labelText: 'Kullanıcı Adı',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      prefixIcon: Icon(
                        Icons.alternate_email_rounded,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      suffixIcon: Icon(
                        Icons.lock_outline,
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        size: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // About
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: _aboutController,
                    maxLines: 3,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Hakkında (İsteğe Bağlı)',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      prefixIcon: Icon(
                        Icons.edit_note_outlined,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // School
                _buildTextField(
                  label: 'Okul Adı',
                  controller: _schoolController,
                  icon: Icons.school_outlined,
                  isDarkMode: isDarkMode,
                ),

                const SizedBox(height: 24),

                // Grade (for students only)
                if (widget.profile.role == 'student') ...[
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<GradeInfo>(
                      initialValue: _selectedGrade,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Sınıf',
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        prefixIcon: Icon(
                          Icons.class_outlined,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
                      items: _grades.map((grade) {
                        return DropdownMenuItem<GradeInfo>(
                          value: grade,
                          child: Text(grade.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGrade = value;
                        });
                      },
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // City
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<CityInfo>(
                    initialValue: _selectedCity,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Şehir',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      prefixIcon: Icon(
                        Icons.location_city_outlined,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
                    items: _cities.map((city) {
                      return DropdownMenuItem<CityInfo>(
                        value: city,
                        child: Text(city.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCity = value;
                        });
                        _fetchDistricts(value.id);
                      }
                    },
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // District
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<DistrictInfo>(
                    initialValue: _selectedDistrict,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'İlçe',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      prefixIcon: Icon(
                        Icons.place_outlined,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
                    items: _districts.map((district) {
                      return DropdownMenuItem<DistrictInfo>(
                        value: district,
                        child: Text(district.name),
                      );
                    }).toList(),
                    onChanged: _selectedCity == null ? null : (value) {
                      setState(() {
                        _selectedDistrict = value;
                      });
                    },
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    hint: Text(
                      'Şehir seçiniz',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Profili Kaydet'),
                  ),
                ),

                const SizedBox(height: 20),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                        width: 1,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: const Text('İptal'),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isDarkMode,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          fontSize: 16,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          prefixIcon: Icon(
            icon,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      ),
      child: Icon(
        Icons.person_rounded,
        size: 60,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}