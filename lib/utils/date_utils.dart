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

/// Haftanın durumunu tutan model
class PeriodInfo {
  final int academicWeek; // Veritabanı sorguları için hafta numarası
  final bool isHoliday;   // Şu an tatil mi?
  final String displayTitle; // Ekranda görünecek ana başlık
  final String? displaySubtitle; // Ekranda görünecek alt başlık

  PeriodInfo({
    required this.academicWeek,
    required this.isHoliday,
    required this.displayTitle,
    this.displaySubtitle,
  });
}

/// Mevcut tarihi analiz ederek detaylı dönem bilgisini döndürür.
/// UI tarafında bunu kullanın.
PeriodInfo getCurrentPeriodInfo() {
  final now = DateTime.now();
  // Okul başlangıç: 9 Eylül 2024 Pazartesi
  final schoolStart = DateTime(now.month < 9 ? now.year - 1 : now.year, 9, 9);
  
  // Ham takvim haftası
  int currentCalendarWeek = (now.difference(schoolStart).inDays / 7).floor() + 1;

  int weeksToSubtract = 0;

  for (final breakInfo in academicBreaks) {
    final int breakStartWeek = breakInfo['after_week'] as int;
    final List weeks = breakInfo['weeks'] as List;
    final int breakDuration = weeks.length;

    int breakCalendarStart = breakStartWeek + 1 + weeksToSubtract;
    int breakCalendarEnd = breakCalendarStart + breakDuration - 1;

    // DURUM 1: Tatil İçindeyiz
    if (currentCalendarWeek >= breakCalendarStart && currentCalendarWeek <= breakCalendarEnd) {
      // Kaçıncı tatil haftası olduğunu bul (0-indexli)
      int holidayIndex = currentCalendarWeek - breakCalendarStart;
      var weekInfo = weeks[holidayIndex];
      
      return PeriodInfo(
        academicWeek: breakStartWeek, // Tatil boyunca son akademik haftada kalır
        isHoliday: true,
        displayTitle: weekInfo['title'] ?? 'Tatil',
        displaySubtitle: weekInfo['duration'] ?? '${holidayIndex + 1}. Hafta',
      );
    }

    // DURUM 2: Tatil Geçti
    if (currentCalendarWeek > breakCalendarEnd) {
      weeksToSubtract += breakDuration;
    }
  }

  // Tatil değilse normal akademik hafta
  int academicWeek = currentCalendarWeek - weeksToSubtract;
  if (academicWeek <= 0) academicWeek = 1;

  return PeriodInfo(
    academicWeek: academicWeek,
    isHoliday: false,
    displayTitle: '$academicWeek. Hafta',
    displaySubtitle: 'Akademik Dönem',
  );
}

/// Geriye dönük uyumluluk için sadece int döndüren fonksiyon
int calculateCurrentAcademicWeek() {
  return getCurrentPeriodInfo().academicWeek;
}
