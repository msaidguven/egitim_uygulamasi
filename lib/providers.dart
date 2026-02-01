import 'package:egitim_uygulamasi/features/test/data/repositories/test_repository_impl.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_session.dart';
import 'package:egitim_uygulamasi/features/test/presentation/viewmodels/test_view_model.dart';
import 'package:egitim_uygulamasi/repositories/auth_repository.dart';
import 'package:egitim_uygulamasi/viewmodels/auth_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:egitim_uygulamasi/main.dart'; // supabase için

// 0. Main Screen Navigation
final mainScreenIndexProvider = StateProvider<int>((ref) => 0);

// 1. Client ID Provider
final clientIdProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  String? clientId = prefs.getString('client_id');

  if (clientId == null) {
    clientId = const Uuid().v4();
    await prefs.setString('client_id', clientId);
  }

  return clientId;
});

// 2. User ID Provider
final userIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

// Auth State Change listener (provider invalidation için)
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// 3. Test Modülü Provider'ları
final testRepositoryProvider = Provider<TestRepositoryImpl>((ref) {
  return TestRepositoryImpl();
});

final testViewModelProvider = ChangeNotifierProvider.autoDispose<TestViewModel>((ref) {
  final repository = ref.watch(testRepositoryProvider);
  return TestViewModel(repository);
});

// Kullanıcının yarım kalan test oturumları
final unfinishedSessionsProvider = FutureProvider<List<TestSession>>((ref) async {
  // auth değişince yeniden fetch et
  ref.watch(authStateProvider);

  final userId = ref.watch(userIdProvider);
  if (userId == null) return <TestSession>[];

  final repository = ref.watch(testRepositoryProvider);
  return repository.getUnfinishedSessions(userId);
});

// 4. Auth Modülü Provider'ları
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // main.dart'taki global supabase nesnesini kullanıyoruz
  return AuthRepository(supabase);
});

final authViewModelProvider = ChangeNotifierProvider<AuthViewModel>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthViewModel(repository);
});
