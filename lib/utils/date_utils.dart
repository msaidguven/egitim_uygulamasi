// lib/utils/date_utils.dart

// Bu dosya, tarih ve hafta hesaplamaları gibi paylaşılan yardımcı fonksiyonları içerir.

import 'package:egitim_uygulamasi/constants.dart';

const List<String> aylar = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

class _BreakWeekInfo {
  final DateTime startDate;
  final DateTime endDate;
  final String title;
  final String subtitle;

  const _BreakWeekInfo({
    required this.startDate,
    required this.endDate,
    required this.title,
    required this.subtitle,
  });
}

final List<_BreakWeekInfo> _breakWeeks = academicBreakWeeks
    .map((b) => _BreakWeekInfo(
          startDate: DateTime(b.startDate.year, b.startDate.month, b.startDate.day),
          endDate: DateTime(b.endDate.year, b.endDate.month, b.endDate.day),
          title: b.title,
          subtitle: b.subtitle,
        ))
    .toList();

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

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _endOfWeek(DateTime startDate) => startDate.add(const Duration(days: 6));

bool _isWithin(DateTime date, DateTime start, DateTime end) {
  return !date.isBefore(start) && !date.isAfter(end);
}

_BreakWeekInfo? _findBreakWeekForDate(DateTime date) {
  for (final breakWeek in _breakWeeks) {
    final effectiveEnd = _endOfWeek(breakWeek.startDate);
    if (_isWithin(date, breakWeek.startDate, effectiveEnd)) {
      return breakWeek;
    }
  }
  return null;
}

int _countBreakWeeksBefore(DateTime date) {
  int count = 0;
  for (final breakWeek in _breakWeeks) {
    final effectiveEnd = _endOfWeek(breakWeek.startDate);
    if (date.isAfter(effectiveEnd)) {
      count++;
    }
  }
  return count;
}

/// Okul başlangıç tarihini döndürür (2025-2026 için 8 Eylül 2025 Pazartesi).
DateTime getSchoolStartDate() => academicYearStartDate;

/// Verilen tarih için akademik haftayı hesaplar.
int getAcademicWeekForDate(DateTime date) {
  final schoolStart = getSchoolStartDate();
  final dateOnly = _dateOnly(date);

  if (dateOnly.isBefore(schoolStart)) return 1;

  final currentCalendarWeek =
      (dateOnly.difference(schoolStart).inDays / 7).floor() + 1;

  final breaksBefore = _countBreakWeeksBefore(dateOnly);
  final breakWeek = _findBreakWeekForDate(dateOnly);

  int academicWeek = breakWeek == null
      ? currentCalendarWeek - breaksBefore
      : currentCalendarWeek - breaksBefore - 1;

  if (academicWeek <= 0) academicWeek = 1;
  return academicWeek;
}

/// Akademik hafta için tarih aralığını döndürür (Pzt-Paz).
(DateTime, DateTime) getWeekDateRangeForAcademicWeek(int curriculumWeek) {
  final schoolStart = getSchoolStartDate();
  DateTime weekStart = schoolStart;
  int academicWeek = 1;

  while (academicWeek < curriculumWeek) {
    weekStart = weekStart.add(const Duration(days: 7));
    if (_findBreakWeekForDate(weekStart) != null) {
      continue;
    }
    academicWeek++;
  }

  final weekEnd = weekStart.add(const Duration(days: 6));
  return (weekStart, weekEnd);
}

/// Tatil haftalarını UI için ekleme bilgisiyle döndürür.
List<Map<String, dynamic>> getAcademicBreakEntries() {
  return _breakWeeks.map((breakWeek) {
    final insertAfterWeek = getAcademicWeekForDate(
      breakWeek.startDate.subtract(const Duration(days: 1)),
    );
    return {
      'insert_after_week': insertAfterWeek,
      'break': {
        'type': 'break',
        'title': breakWeek.title,
        'duration': breakWeek.subtitle,
      },
    };
  }).toList();
}

/// Mevcut tarihi analiz ederek detaylı dönem bilgisini döndürür.
/// UI tarafında bunu kullanın.
PeriodInfo getCurrentPeriodInfo() {
  final now = DateTime.now();
  final dateOnly = _dateOnly(now);
  final breakWeek = _findBreakWeekForDate(dateOnly);
  final academicWeek = getAcademicWeekForDate(dateOnly);

  if (breakWeek != null) {
    return PeriodInfo(
      academicWeek: academicWeek,
      isHoliday: true,
      displayTitle: breakWeek.title,
      displaySubtitle: breakWeek.subtitle,
    );
  }

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
