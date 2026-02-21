import 'dart:async';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_session.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';

abstract class TestRepository {
  // Test oturumu işlemleri
  Future<int> startTestSession({
    required TestMode testMode,
    required int unitId,
    int? curriculumWeek,
    int? topicId,
    List<int>? outcomeIds,
    String? clientId,
    String? userId,
  });

  Future<void> finishTestSession(int sessionId, TestMode testMode);

  // Soru işlemleri
  Future<Map<String, dynamic>> getNextQuestion(int sessionId, String? userId);
  Future<List<Question>> getAllSessionQuestions(int sessionId, String? userId);
  Future<Set<int>> getAnsweredQuestionIds(int sessionId);

  // Misafir haftalık testi için soruları getiren metot
  Future<List<Question>> startGuestTest({
    required int unitId,
    required int curriculumWeek,
    int? topicId,
    List<int>? outcomeIds,
  });

  // YENİ: Misafir ünite testi için soruları getiren metot
  Future<List<Question>> startGuestUnitTest({required int unitId});

  // Cevap işlemleri
  Future<void> saveAnswer({
    required int sessionId,
    required int questionId,
    required String? userId,
    required String clientId,
    required dynamic userAnswer,
    required bool isCorrect,
    required int durationSeconds,
  });

  // Oturum yönetimi
  Future<bool> resumeTestSession(int sessionId);

  // Home: kullanıcının yarım kalan test oturumları
  Future<List<TestSession>> getUnfinishedSessions(String userId);

  // SRS: Zamanı gelen tekrar sorularının sayısını getir
  Future<int> getSrsDueCount(String userId);

  // SRS: Tekrar testi başlat
  Future<int> startSrsTestSession({
    required String userId,
    required String clientId,
  });
}
