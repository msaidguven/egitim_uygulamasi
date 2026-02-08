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
