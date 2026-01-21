import 'dart:async';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';

abstract class TestRepository {
  // Test oturumu işlemleri
  Future<int> startTestSession({
    required TestMode testMode,
    required int unitId,
    int? curriculumWeek,
    String? clientId,
    String? userId,
  });

  Future<void> finishTestSession(int sessionId, TestMode testMode);

  // Soru işlemleri
  Future<Map<String, dynamic>> getNextQuestion(int sessionId, String? userId);
  Future<List<Question>> getAllSessionQuestions(int sessionId, String? userId);
  
  // YENİ: Cevaplanmış soru ID'lerini getiren metodun imzası eklendi.
  Future<Set<int>> getAnsweredQuestionIds(int sessionId);

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
}