// lib/constants.dart

import 'package:flutter/foundation.dart' show kIsWeb;

// Supabase varsayilan degerleri. Web build'de --dart-define ile override edilebilir.
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://pwzbjhgrhkcdyowknmhe.supabase.co',
);
const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB3emJqaGdyaGtjZHlvd2tubWhlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyOTgwNTYsImV4cCI6MjA4MDg3NDA1Nn0.rCrirZxjXSNDO5R5NPur3ac_153Z4FIvd85jEz-uXKY',
);

// Auth redirect URL for password reset deep links
const String _authRedirectUrlMobile = 'net.derstakip.egitim://login-callback';
const String _authRedirectUrlWeb = 'https://derstakip.net/login-callback';

String get authRedirectUrl => kIsWeb ? _authRedirectUrlWeb : _authRedirectUrlMobile;

// Default grade id for Google sign-in when no selection is provided
const int defaultGoogleGradeId = 5;

// AdMob IDs can be overridden with --dart-define in release builds.
const String admobAndroidBannerUnitId = String.fromEnvironment(
  'ADMOB_ANDROID_BANNER_UNIT_ID',
  defaultValue: 'ca-app-pub-3940256099942544/6300978111',
);
const String admobIosBannerUnitId = String.fromEnvironment(
  'ADMOB_IOS_BANNER_UNIT_ID',
  defaultValue: 'ca-app-pub-3940256099942544/2934735716',
);

// Akademik yıl ayarları (2025-2026)
class AcademicBreakWeek {
  final DateTime startDate;
  final DateTime endDate;
  final String title;
  final String subtitle;

  const AcademicBreakWeek({
    required this.startDate,
    required this.endDate,
    required this.title,
    required this.subtitle,
  });
}

final DateTime academicYearStartDate = DateTime(2025, 9, 8);

final List<AcademicBreakWeek> academicBreakWeeks = [
  AcademicBreakWeek(
    startDate: DateTime(2025, 11, 10),
    endDate: DateTime(2025, 11, 14),
    title: 'Ara Tatil',
    subtitle: '1. DÖNEM ARA TATİLİ: 10 - 14 Kasım',
  ),
  AcademicBreakWeek(
    startDate: DateTime(2026, 1, 19),
    endDate: DateTime(2026, 1, 25),
    title: 'Yarıyıl Tatili',
    subtitle: '1. Hafta (19 Ocak - 25 Ocak)',
  ),
  AcademicBreakWeek(
    startDate: DateTime(2026, 1, 26),
    endDate: DateTime(2026, 2, 1),
    title: 'Yarıyıl Tatili',
    subtitle: '2. Hafta (26 Ocak - 1 Şubat)',
  ),
  AcademicBreakWeek(
    startDate: DateTime(2026, 3, 30),
    endDate: DateTime(2026, 4, 5),
    title: 'Ara Tatil',
    subtitle: '2. DÖNEM ARA TATİLİ',
  ),
];
