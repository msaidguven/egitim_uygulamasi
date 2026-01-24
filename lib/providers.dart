// lib/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:egitim_uygulamasi/features/test/data/repositories/test_repository_impl.dart';
import 'package:egitim_uygulamasi/features/test/presentation/viewmodels/test_view_model.dart'; // GEREKLİ IMPORT

// 1. Client ID Provider - SharedPreferences'ten clientId alır
final clientIdProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  String? clientId = prefs.getString('client_id');

  if (clientId == null) {
    clientId = const Uuid().v4();
    await prefs.setString('client_id', clientId);
  }

  return clientId;
});

// 2. User ID Provider - Supabase'ten kullanıcı ID'sini alır
final userIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

// 3. Test Repository Provider
final testRepositoryProvider = Provider<TestRepositoryImpl>((ref) {
  return TestRepositoryImpl();
});

// 4. Test ViewModel Provider - YENİ EKLENDİ
final testViewModelProvider = ChangeNotifierProvider.autoDispose<TestViewModel>((ref) {
  final repository = ref.watch(testRepositoryProvider);
  return TestViewModel(repository);
});
