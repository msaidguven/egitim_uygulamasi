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
  
  String? _avatarUrl; // Avatar URL'sini state içinde tutalım
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veriler yüklenemedi: $e')));
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
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
    );

    if (imageFile == null) {
      setState(() => _isUploading = false);
      return;
    }

    try {
      final file = File(imageFile.path);
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final filePath = 'public/${_supabase.auth.currentUser!.id}/$fileName';

      // Resmi Supabase Storage'a yükle
      await _supabase.storage.from('avatars').upload(filePath, file);

      // Yüklenen resmin public URL'ini al
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

      // URL'i state'e ve veritabanına kaydet
      setState(() {
        _avatarUrl = imageUrl;
      });
      
      await _profileViewModel.updateProfile({'avatar_url': imageUrl});

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Resim yüklenemedi: $e'), backgroundColor: Colors.red));
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
      // avatar_url burada güncellenmiyor çünkü o anlık olarak _pickAndUploadAvatar içinde yapılıyor.
    };

    final success = await _profileViewModel.updateProfile(updates);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profil başarıyla güncellendi!' : 'Bir hata oluştu.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        actions: [
          if (_isSaving) const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))),
          if (!_isSaving) IconButton(icon: const Icon(Icons.save), onPressed: _saveProfile),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                          child: _avatarUrl == null ? const Icon(Icons.person, size: 60) : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: IconButton(
                              icon: _isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.camera_alt, color: Colors.white),
                              onPressed: _isUploading ? null : _pickAndUploadAvatar,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(controller: _fullNameController, decoration: const InputDecoration(labelText: 'İsim Soyisim')),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Kullanıcı Adı (Değiştirilemez)',
                      fillColor: Colors.grey.shade200,
                      filled: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(controller: _aboutController, decoration: const InputDecoration(labelText: 'Hakkında'), maxLines: 3),
                  const SizedBox(height: 16),
                  TextFormField(controller: _schoolController, decoration: const InputDecoration(labelText: 'Okul Adı')),
                  const SizedBox(height: 24),
                  
                  if (widget.profile.role == 'student') ...[
                    DropdownButtonFormField<GradeInfo>(
                      value: _selectedGrade,
                      items: _grades.map((grade) => DropdownMenuItem(value: grade, child: Text(grade.name))).toList(),
                      onChanged: (value) => setState(() => _selectedGrade = value),
                      decoration: const InputDecoration(labelText: 'Sınıf', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                  ],

                  DropdownButtonFormField<CityInfo>(
                    value: _selectedCity,
                    items: _cities.map((city) => DropdownMenuItem(value: city, child: Text(city.name))).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCity = value);
                        _fetchDistricts(value.id);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'İl', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<DistrictInfo>(
                    value: _selectedDistrict,
                    hint: Text(_selectedCity == null ? 'Önce bir il seçin' : 'İlçe seçin'),
                    items: _districts.map((district) => DropdownMenuItem(value: district, child: Text(district.name))).toList(),
                    onChanged: _selectedCity == null ? null : (value) => setState(() => _selectedDistrict = value),
                    decoration: const InputDecoration(
                      labelText: 'İlçe',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
