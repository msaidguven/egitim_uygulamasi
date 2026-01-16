// lib/features/test/data/repositories/test_repository_impl.dart

import 'dart:async';
import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:egitim_uygulamasi/features/test/domain/repositories/test_repository.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';

class TestRepositoryImpl implements TestRepository {
  final SupabaseClient _supabase;

  TestRepositoryImpl() : _supabase = Supabase.instance.client;

  // YENİ METOD: Cevaplanmış soru ID'lerini getirir.
  @override
  Future<Set<int>> getAnsweredQuestionIds(int sessionId) async {
    try {
      final response = await _supabase
          .from('test_session_answers')
          .select('question_id')
          .eq('test_session_id', sessionId);

      final answeredQuestionIds =
          (response as List).map((row) => row['question_id'] as int).toSet();
      return answeredQuestionIds;
    } catch (e) {
      log('getAnsweredQuestionIds ERROR: $e');
      return {};
    }
  }

  @override
  Future<int> startTestSession({
    required TestMode testMode,
    required int unitId,
    int? weekNo,
    String? clientId,
    String? userId,
  }) async {
    try {
      String rpcName;
      Map<String, dynamic> params;

      switch (testMode) {
        case TestMode.weekly:
          rpcName = 'start_weekly_test_session';
          params = {
            'p_user_id': userId,
            'p_unit_id': unitId,
            'p_week_no': weekNo ?? 1,
            'p_client_id': clientId,
          };
          break;
        case TestMode.wrongAnswers:
          rpcName = 'start_wrong_answers_session';
          params = {
            'p_client_id': clientId,
            'p_unit_id': unitId,
            'p_user_id': userId,
          };
          break;
        case TestMode.normal:
        default:
          rpcName = 'start_test_v2';
          params = {
            'p_client_id': clientId,
            'p_unit_id': unitId,
            'p_user_id': userId,
          };
          break;
      }

      log('TestRepositoryImpl.startTestSession: $rpcName, params: $params');

      final response = await _supabase.rpc(rpcName, params: params);

      if (response == null) {
        throw Exception('RPC $rpcName null döndü');
      }

      final sessionId = response as int;
      log('TestRepositoryImpl.startTestSession: Yeni sessionId = $sessionId');

      return sessionId;
    } catch (e, stackTrace) {
      log('TestRepositoryImpl.startTestSession ERROR: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> finishTestSession(int sessionId, TestMode testMode) async {
    try {
      final rpcName = testMode == TestMode.weekly
          ? 'finish_weekly_test'
          : 'finish_test_v2';

      log('TestRepositoryImpl.finishTestSession: $rpcName, sessionId: $sessionId');

      await _supabase.rpc(rpcName, params: {'p_session_id': sessionId});

      log('TestRepositoryImpl.finishTestSession: Session $sessionId başarıyla tamamlandı');
    } catch (e, stackTrace) {
      log('TestRepositoryImpl.finishTestSession ERROR: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getNextQuestion(int sessionId, String? userId) async {
    try {
      log('TestRepositoryImpl.getNextQuestion: sessionId=$sessionId, userId=$userId');

      final response = await _supabase.rpc(
        'get_next_question_v3',
        params: {'p_session_id': sessionId, 'p_user_id': userId},
      );

      if (response == null) {
        log('TestRepositoryImpl.getNextQuestion: Null response - muhtemelen tüm sorular tamamlandı');
        return {
          'question': null,
          'answered_count': 0,
          'correct_count': 0,
        };
      }

      final result = response as Map<String, dynamic>;
      log('TestRepositoryImpl.getNextQuestion: Soru alındı, questionId: ${result['question']?['id']}');

      return result;
    } catch (e, stackTrace) {
      log('TestRepositoryImpl.getNextQuestion ERROR: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Question>> getAllSessionQuestions(int sessionId, String? userId) async {
    try {
      log('TestRepositoryImpl.getAllSessionQuestions: sessionId=$sessionId, userId=$userId');

      final response = await _supabase.rpc(
        'get_all_session_questions',
        params: {'p_session_id': sessionId, 'p_user_id': userId},
      );

      if (response == null) {
        log('TestRepositoryImpl.getAllSessionQuestions: Null response');
        return [];
      }

      final questions = (response as List)
          .map((q) {
        try {
          return Question.fromMap(q as Map<String, dynamic>);
        } catch (e) {
          log('Question.fromMap ERROR: $e, data: $q');
          return null;
        }
      })
          .whereType<Question>()
          .toList();

      log('TestRepositoryImpl.getAllSessionQuestions: ${questions.length} soru alındı');

      return questions;
    } catch (e, stackTrace) {
      log('TestRepositoryImpl.getAllSessionQuestions ERROR: $e', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  @override
  Future<void> saveAnswer({
    required int sessionId,
    required int questionId,
    required String? userId,
    required String clientId,
    required dynamic userAnswer,
    required bool isCorrect,
    required int durationSeconds,
  }) async {
    try {
      String? selectedOptionId;
      String? answerText;

      // Soru tipine göre veriyi formatla
      if (userAnswer is String) {
        selectedOptionId = userAnswer;
        answerText = userAnswer;
      } else if (userAnswer is Map<int, dynamic>) {
        // Boşluk doldurma için
        final List<String> answers = [];
        userAnswer.forEach((key, value) {
          if (value != null) {
            answers.add(value.toString());
          }
        });
        answerText = answers.join('|');
      } else if (userAnswer is Map<String, dynamic>) {
        // Eşleştirme için
        answerText = userAnswer.entries
            .map((e) => '${e.key}:${e.value}')
            .join('|');
      } else {
        answerText = userAnswer?.toString();
      }

      final dataToInsert = {
        'test_session_id': sessionId,
        'question_id': questionId,
        'user_id': userId,
        'client_id': clientId,
        'selected_option_id': selectedOptionId,
        'answer_text': answerText,
        'is_correct': isCorrect,
        'duration_seconds': durationSeconds,
        'created_at': DateTime.now().toIso8601String(),
      };

      log('TestRepositoryImpl.saveAnswer: questionId=$questionId, isCorrect=$isCorrect, duration=$durationSeconds');

      await _supabase.from('test_session_answers').insert(dataToInsert);

      log('TestRepositoryImpl.saveAnswer: Cevap başarıyla kaydedildi');
    } catch (e, stackTrace) {
      log('TestRepositoryImpl.saveAnswer ERROR: $e', error: e, stackTrace: stackTrace);
      // Cevap kaydetme hatası kritik değil, devam edebiliriz
    }
  }

  @override
  Future<bool> resumeTestSession(int sessionId) async {
    try {
      log('TestRepositoryImpl.resumeTestSession: sessionId=$sessionId');

      final response = await _supabase
          .from('test_sessions')
          .select('id, completed_at')
          .eq('id', sessionId)
          .maybeSingle();

      if (response == null) {
        log('TestRepositoryImpl.resumeTestSession: Session bulunamadı');
        return false;
      }

      final isCompleted = response['completed_at'] != null;
      final isValid = !isCompleted;

      log('TestRepositoryImpl.resumeTestSession: Session $sessionId, isCompleted=$isCompleted, isValid=$isValid');

      return isValid;
    } catch (e, stackTrace) {
      log('TestRepositoryImpl.resumeTestSession ERROR: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // Ek metod: Haftalık test için başlangıç
  Future<int> startWeeklyTest({
    required int unitId,
    required int weekNo,
    required String? userId,
    required String clientId,
  }) async {
    return await startTestSession(
      testMode: TestMode.weekly,
      unitId: unitId,
      weekNo: weekNo,
      userId: userId,
      clientId: clientId,
    );
  }

  // Ek metod: Yanlışlar testi için başlangıç
  Future<int> startWrongAnswersTest({
    required int unitId,
    required String? userId,
    required String clientId,
  }) async {
    return await startTestSession(
      testMode: TestMode.wrongAnswers,
      unitId: unitId,
      userId: userId,
      clientId: clientId,
    );
  }

  // Ek metod: Normal test için başlangıç
  Future<int> startNormalTest({
    required int unitId,
    required String? userId,
    required String clientId,
  }) async {
    return await startTestSession(
      testMode: TestMode.normal,
      unitId: unitId,
      userId: userId,
      clientId: clientId,
    );
  }

  // Ek metod: Test oturumu detaylarını al
  Future<Map<String, dynamic>?> getSessionDetails(int sessionId) async {
    try {
      final response = await _supabase
          .from('test_sessions')
          .select('*')
          .eq('id', sessionId)
          .maybeSingle();

      return response as Map<String, dynamic>?;
    } catch (e) {
      log('TestRepositoryImpl.getSessionDetails ERROR: $e');
      return null;
    }
  }

  // Ek metod: Kullanıcının test istatistiklerini al
  Future<Map<String, dynamic>> getUserStats(int unitId, String? userId) async {
    try {
      final response = await _supabase.rpc(
        'get_user_unit_stats',
        params: {
          'p_user_id': userId,
          'p_unit_id': unitId,
        },
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      log('TestRepositoryImpl.getUserStats ERROR: $e');
      return {};
    }
  }
}