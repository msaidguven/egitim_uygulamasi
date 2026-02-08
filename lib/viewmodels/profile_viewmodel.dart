import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/models/profile_model.dart';
import 'package:egitim_uygulamasi/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileViewModelProvider = ChangeNotifierProvider((ref) => ProfileViewModel());

class ProfileViewModel extends ChangeNotifier {
  bool _isLoading = false;
  Profile? _profile;
  String? _errorMessage;

  // İstatistik Değişkenleri
  int _totalQuestionsSolved = 0;
  double _successRate = 0.0;
  String _totalDurationFormatted = "0h";
  double _progressPercentage = 0.0;
  int _totalCorrectAnswers = 0;
  int _totalWrongAnswers = 0;

  bool get isLoading => _isLoading;
  Profile? get profile => _profile;
  String? get errorMessage => _errorMessage;

  // İstatistik Getter'ları
  int get totalQuestionsSolved => _totalQuestionsSolved;
  double get successRate => _successRate;
  String get totalDurationFormatted => _totalDurationFormatted;
  double get progressPercentage => _progressPercentage;
  int get totalCorrectAnswers => _totalCorrectAnswers;
  int get totalWrongAnswers => _totalWrongAnswers;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        _profile = null;
        _resetStats();
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Profil bilgilerini çek
      const query = '''
        *,
        grades ( id, name, question_count ),
        cities ( id, name ),
        districts ( id, name )
      ''';

      var data = await supabase
          .from('profiles')
          .select(query)
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        // Profil henüz oluşmadıysa kısa bir gecikmeyle bir kez daha dene
        await Future.delayed(const Duration(milliseconds: 500));
        data = await supabase
            .from('profiles')
            .select(query)
            .eq('id', user.id)
            .maybeSingle();
      }
          
      if (data == null) {
        // Profil yoksa (ör. web OAuth sonrası) otomatik oluşturmayı dene
        final fullName = user.userMetadata?['full_name'] ?? 'Google User';
        final email = user.email ?? '';
        final username = email.isNotEmpty ? email.split('@').first : 'user';

        await supabase.from('profiles').insert({
          'id': user.id,
          'full_name': fullName,
          'username': username,
          'grade_id': defaultGoogleGradeId,
        });

        data = await supabase
            .from('profiles')
            .select(query)
            .eq('id', user.id)
            .maybeSingle();
      }

      if (data == null) {
        _profile = null;
        _resetStats();
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _profile = Profile.fromMap(data);
      
      // Profil geldikten sonra istatistikleri çek
      await _fetchUserStats(user.id);
      
      _errorMessage = null;

    } catch (e) {
      _errorMessage = "Profil bilgileri yüklenirken bir hata oluştu: $e";
      _profile = null;
      _resetStats();
      debugPrint('Profil Hatası: $_errorMessage');
    }

    _isLoading = false;
    notifyListeners();
  }

  // İstatistikleri Sıfırla
  void _resetStats() {
    _totalQuestionsSolved = 0;
    _successRate = 0.0;
    _totalDurationFormatted = "0h";
    _progressPercentage = 0.0;
    _totalCorrectAnswers = 0;
    _totalWrongAnswers = 0;
  }

  // Veritabanından İstatistikleri Çek (Hibrit Yaklaşım)
  Future<void> _fetchUserStats(String userId) async {
    try {
      // 1. SÜRE BİLGİSİ (user_time_based_stats)
      // Süre bilgisi özet tabloda olmadığı için buradan alıyoruz.
      final timeData = await supabase
          .from('user_time_based_stats')
          .select('total_duration_seconds')
          .eq('user_id', userId)
          .eq('period_type', 'academic_year')
          .maybeSingle();

      if (timeData != null) {
        final durationSec = timeData['total_duration_seconds'] as int? ?? 0;
        final durationHours = durationSec / 3600;
        if (durationHours < 1 && durationHours > 0) {
           _totalDurationFormatted = "${(durationSec / 60).toStringAsFixed(0)}m";
        } else {
           _totalDurationFormatted = "${durationHours.toStringAsFixed(1)}h";
        }
      } else {
        _totalDurationFormatted = "0h";
      }

      // 2. SORU SAYILARI VE BAŞARI (user_unit_summary)
      // Benzersiz soru sayısı ve başarı oranı için özet tablodan toplama yapıyoruz.
      // Not: Supabase Flutter SDK'sında doğrudan .sum() metodu kısıtlı olabilir.
      // Bu yüzden veriyi çekip Dart tarafında toplamak veya rpc kullanmak gerekebilir.
      // Küçük veri seti için Dart tarafında toplamak güvenlidir.
      
      final summaryData = await supabase
          .from('user_unit_summary')
          .select('solved_question_count, correct_count, wrong_count')
          .eq('user_id', userId);

      int totalSolvedUnique = 0;
      int totalCorrect = 0;
      int totalWrong = 0;

      if (summaryData != null) {
        for (var row in (summaryData as List)) {
          totalSolvedUnique += (row['solved_question_count'] as int? ?? 0);
          totalCorrect += (row['correct_count'] as int? ?? 0);
          totalWrong += (row['wrong_count'] as int? ?? 0);
        }
      }

      _totalQuestionsSolved = totalSolvedUnique;
      _totalCorrectAnswers = totalCorrect;
      _totalWrongAnswers = totalWrong;

      // Başarı Oranı Hesapla (Toplam Doğru / Toplam Cevaplama Sayısı)
      final totalAttempts = totalCorrect + totalWrong;
      if (totalAttempts > 0) {
        _successRate = (totalCorrect / totalAttempts) * 100;
      } else {
        _successRate = 0.0;
      }

      // 3. İLERLEME ORANI (Çözülen Benzersiz / Sınıf Toplamı)
      if (_profile?.grade?.id != null) {
         final gradeData = await supabase
             .from('grades')
             .select('question_count')
             .eq('id', _profile!.grade!.id)
             .single();
         
         final totalGradeQuestions = gradeData['question_count'] as int? ?? 0;

         if (totalGradeQuestions > 0) {
           _progressPercentage = _totalQuestionsSolved / totalGradeQuestions;
           if (_progressPercentage > 1.0) _progressPercentage = 1.0; // %100'ü geçmesin
         } else {
           _progressPercentage = 0.0;
         }
      }

    } catch (e) {
      debugPrint('İstatistik çekme hatası: $e');
    }
  }

  Future<bool> isAdmin() async {
    try {
      if (supabase.auth.currentUser == null) return false;
      if (_profile == null) await fetchProfile();
      return _profile?.role == 'admin';
    } catch (e) {
      debugPrint('Admin kontrolünde hata: $e');
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('profiles').update(data).eq('id', userId);
      await fetchProfile();
      return true;
    } catch (e) {
      _errorMessage = "Profil güncellenirken bir hata oluştu: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
