// lib/utils/date_utils.dart

// Bu dosya, tarih ve hafta hesaplamaları gibi paylaşılan yardımcı fonksiyonları içerir.

const List<String> aylar = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

/// Akademik takvimdeki tatil haftalarını tanımlar.
/// `after_week`: Bu haftadan sonra tatil başlar.
/// `weeks`: Tatilin kaç hafta sürdüğünü belirtir.
final List<Map<String, dynamic>> academicBreaks = [
  {'after_week': 9, 'weeks': [{'type': 'break', 'title': 'Ara Tatil', 'duration': '1. DÖNEM ARA TATİLİ: 10 - 14 Kasım'}]},
  {'after_week': 18, 'weeks': [{'type': 'break', 'title': 'Yarıyıl Tatili', 'duration': '1. Hafta (19 Ocak - 25 Ocak)'}, {'type': 'break', 'title': 'Yarıyıl Tatili', 'duration': '2. Hafta (26 Ocak - 1 Şubat)'}]},
  {'after_week': 26, 'weeks': [{'type': 'break', 'title': 'Ara Tatil', 'duration': '2. DÖNEM ARA TATİLİ'}]},
];

// lib/utils/date_utils.dart

// ... (diğer kodlar aynı kalacak) ...

/// Mevcut akademik haftayı, tatilleri hesaba katarak hesaplar.
int calculateCurrentAcademicWeek() {
  final now = DateTime.now();
  // Okul başlangıç tarihini mevcut akademik yıla göre belirle (Eylül ayını baz alarak).
  final schoolStart = DateTime(now.month < 9 ? now.year - 1 : now.year, 9, 8);

  // Okul başlangıcından bu yana geçen takvim haftası sayısı.
  final calendarWeek = (now.difference(schoolStart).inDays / 7).floor() + 1;

  // Geçmiş tatil haftalarının toplam sayısı.
  int weeksToSubtract = 0;
  for (final breakInfo in academicBreaks) {
    final int breakDuration = (breakInfo['weeks'] as List).length;
    // Tatilin bittiği hafta numarası (bu haftadan sonra tatil bitmiş olur).
    // Örneğin, after_week 9 ve duration 1 ise, tatil 10. haftadan sonra biter.
    // after_week 18 ve duration 2 ise, tatil 20. haftadan sonra biter.
    final int breakEndsAfterWeek = breakInfo['after_week'] + breakDuration;

    // Eğer mevcut takvim haftası, tatilin tamamen bitiş haftasından sonraysa,
    // o tatilin süresini çıkarılacak haftalara ekle.
    if (calendarWeek > breakEndsAfterWeek) {
      weeksToSubtract += breakDuration;
    }
  }

  // Akademik hafta = Takvim haftası - Geçmiş tatil haftaları
  return calendarWeek - weeksToSubtract;
}



/*

/// Mevcut akademik haftayı, tatilleri hesaba katarak hesaplar.
int calculateCurrentAcademicWeek() {
  final now = DateTime.now();
  // Okul başlangıç tarihini mevcut akademik yıla göre belirle (Eylül ayını baz alarak).
  final schoolStart = DateTime(now.month < 9 ? now.year - 1 : now.year, 9, 8);

  // Okul başlangıcından bu yana geçen takvim haftası sayısı.
  final calendarWeek = (now.difference(schoolStart).inDays / 7).floor() + 1;

  // Geçmiş tatil haftalarının toplam sayısı.
  int weeksToSubtract = 0;
  for (final breakInfo in academicBreaks) {
    // Eğer mevcut takvim haftası, bir tatilin başlangıç haftasından sonraysa,
    // o tatilin süresini çıkarılacak haftalara ekle.
    if (calendarWeek > breakInfo['after_week']) {
      weeksToSubtract += (breakInfo['weeks'] as List).length;
    }
  }

  // Akademik hafta = Takvim haftası - Geçmiş tatil haftaları
  return calendarWeek - weeksToSubtract;
}
*/