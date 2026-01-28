// lib/features/test/data/repositories/test_repository_impl.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:egitim_uygulamasi/models/question_blank_option.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:egitim_uygulamasi/features/test/domain/repositories/test_repository.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_session.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';

class TestRepositoryImpl implements TestRepository {
  final SupabaseClient _supabase;

  TestRepositoryImpl() : _supabase = Supabase.instance.client;

  @override
  Future<List<Question>> startGuestTest({
    required int unitId,
    required int curriculumWeek,
  }) async {
    try {
      log(
        'TestRepositoryImpl.startGuestTest (weekly): unitId=$unitId, curriculumWeek=$curriculumWeek',
      );

      final response = await _supabase.rpc(
        'start_guest_test',
        params: {
          'p_unit_id': unitId,
          'p_type': 'weekly',
          'p_curriculum_week': curriculumWeek,
        },
      );

      if (response == null) {
        log('TestRepositoryImpl.startGuestTest (weekly): Null response');
        return [];
      }

      final questions = (response as List)
          .map((q) => Question.fromMap(q as Map<String, dynamic>))
          .toList();

      log(
        'TestRepositoryImpl.startGuestTest (weekly): ${questions.length} misafir sorusu alındı',
      );
      return questions;
    } catch (e, stackTrace) {
      log(
        'TestRepositoryImpl.startGuestTest (weekly) ERROR: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<Question>> startGuestUnitTest({required int unitId}) async {
    try {
      log('TestRepositoryImpl.startGuestUnitTest: unitId=$unitId');

      final response = await _supabase.rpc(
        'start_guest_test',
        params: {'p_unit_id': unitId, 'p_type': 'unit'},
      );

      if (response == null) {
        log('TestRepositoryImpl.startGuestUnitTest: Null response');
        return [];
      }

      final questions = (response as List)
          .map((q) => Question.fromMap(q as Map<String, dynamic>))
          .toList();

      log(
        'TestRepositoryImpl.startGuestUnitTest: ${questions.length} misafir sorusu alındı',
      );
      return questions;
    } catch (e, stackTrace) {
      log(
        'TestRepositoryImpl.startGuestUnitTest ERROR: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // YENİ METOD: Cevaplanmış soru ID'lerini getirir.
  @override
  Future<Set<int>> getAnsweredQuestionIds(int sessionId) async {
    try {
      final response = await _supabase
          .from('test_session_answers')
          .select('question_id')
          .eq('test_session_id', sessionId);

      final answeredQuestionIds = (response as List)
          .map((row) => row['question_id'] as int)
          .toSet();
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
    int? curriculumWeek,
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
            'p_curriculum_week': curriculumWeek ?? 1,
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
          rpcName = 'start_unit_test';
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
      log(
        'TestRepositoryImpl.startTestSession ERROR: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> finishTestSession(int sessionId, TestMode testMode) async {
    try {
      log('--- TEST BİTİRİLİYOR --- Test Modu: $testMode');
      log(
        'TestRepositoryImpl.finishTestSession: public.finish_test_session RPC çağrılıyor, sessionId: $sessionId',
      );

      // Test modundan bağımsız olarak tek bir merkezi RPC çağrılıyor.
      // Tüm özetleme/güncelleme mantığı veritabanı trigger'ları tarafından yönetilecek.
      await _supabase.rpc(
        'finish_test_session',
        params: {'p_session_id': sessionId},
      );

      log(
        'TestRepositoryImpl.finishTestSession: Session $sessionId başarıyla tamamlandı (merkezi RPC ile)',
      );
    } catch (e, stackTrace) {
      log(
        'TestRepositoryImpl.finishTestSession ERROR: $e',
        error: e,
        stackTrace: stackTrace,
      );
      // Hata mesajlarını konsola daha belirgin bir şekilde yazdır
      log("**************************************************");
      log("HATA: TEST BİTİRME RPC ÇAĞRISI BAŞARISIZ OLDU");
      log("**************************************************");
      log("Oturum ID: $sessionId");
      log("Test Modu: $testMode");
      log("Hata Detayı: $e");
      log("Stack Trace: $stackTrace");
      if (e is PostgrestException) {
        log("Postgrest Mesajı: ${e.message}");
        log("Postgrest Detayları: ${e.details}");
        log("Postgrest İpucu: ${e.hint}");
      }
      log("**************************************************");
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getNextQuestion(
    int sessionId,
    String? userId,
  ) async {
    try {
      log(
        'TestRepositoryImpl.getNextQuestion: sessionId=$sessionId, userId=$userId',
      );

      final response = await _supabase.rpc(
        'get_next_question_v3',
        params: {'p_session_id': sessionId, 'p_user_id': userId},
      );

      if (response == null) {
        log(
          'TestRepositoryImpl.getNextQuestion: Null response - muhtemelen tüm sorular tamamlandı',
        );
        return {'question': null, 'answered_count': 0, 'correct_count': 0};
      }

      final result = response as Map<String, dynamic>;
      log(
        'TestRepositoryImpl.getNextQuestion: Soru alındı, questionId: ${result['question']?['id']}',
      );

      return result;
    } catch (e, stackTrace) {
      log(
        'TestRepositoryImpl.getNextQuestion ERROR: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<Question>> getAllSessionQuestions(
    int sessionId,
    String? userId,
  ) async {
    try {
      log(
        'TestRepositoryImpl.getAllSessionQuestions: sessionId=$sessionId, userId=$userId',
      );

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

      log(
        'TestRepositoryImpl.getAllSessionQuestions: ${questions.length} soru alındı',
      );

      return questions;
    } catch (e, stackTrace) {
      log(
        'TestRepositoryImpl.getAllSessionQuestions ERROR: $e',
        error: e,
        stackTrace: stackTrace,
      );
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
      dynamic encodableAnswer = userAnswer;

      if (userAnswer is Map && userAnswer.values.isNotEmpty) {
        final firstValue = userAnswer.values.first;

        if (firstValue is MatchingPair) {
          final Map<String, String> serializableMap = {};
          userAnswer.forEach((key, value) {
            if (key is String && value is MatchingPair) {
              serializableMap[key] = value.right_text;
            }
          });
          encodableAnswer = serializableMap;
          log(
            'TestRepositoryImpl.saveAnswer: MatchingPair answer converted to serializable map.',
          );
        } else if (firstValue is QuestionBlankOption) {
          final Map<String, String> serializableMap = {};
          userAnswer.forEach((key, value) {
            if (value is QuestionBlankOption) {
              // HATA DÜZELTMESİ: 'value.text' yerine 'value.optionText' kullanıldı.
              serializableMap[key.toString()] = value.optionText;
            }
          });
          encodableAnswer = serializableMap;
          log(
            'TestRepositoryImpl.saveAnswer: QuestionBlankOption answer converted to serializable map.',
          );
        }
      }

      final dataToInsert = {
        'test_session_id': sessionId,
        'question_id': questionId,
        'user_id': userId,
        'client_id': clientId,
        'answer_text': jsonEncode(
          encodableAnswer,
        ), // Dönüştürülmüş cevabı JSON olarak kodla
        'is_correct': isCorrect,
        'duration_seconds': durationSeconds,
        'created_at': DateTime.now().toIso8601String(),
      };

      log(
        'TestRepositoryImpl.saveAnswer: Inserting into test_session_answers with data: $dataToInsert',
      );

      await _supabase.from('test_session_answers').insert(dataToInsert);

      log('TestRepositoryImpl.saveAnswer: Insert successful.');
    } catch (e, stackTrace) {
      log(
        'TestRepositoryImpl.saveAnswer: INSERT FAILED. Rethrowing error.',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
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

      log(
        'TestRepositoryImpl.resumeTestSession: Session $sessionId, isCompleted=$isCompleted, isValid=$isValid',
      );

      return isValid;
    } catch (e, stackTrace) {
      log(
        'TestRepositoryImpl.resumeTestSession ERROR: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<List<TestSession>> getUnfinishedSessions(String userId) async {
    try {
      final response = await _supabase
          .from('test_sessions')
          .select(
            'id, user_id, unit_id, created_at, completed_at, settings, question_ids, client_id, lesson_id, grade_id, '
            'units(title, lessons(name)), '
            'lessons(name)',
          )
          .eq('user_id', userId)
          .isFilter('completed_at', null)
          .order('created_at', ascending: false)
          .limit(10);

      return (response as List)
          .whereType<Map<String, dynamic>>()
          .map((row) => TestSession.fromMap(row))
          .toList();
    } catch (e, stackTrace) {
      log(
        'TestRepositoryImpl.getUnfinishedSessions ERROR: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return <TestSession>[];
    }
  }

  // Ek metod: Haftalık test için başlangıç
  Future<int> startWeeklyTest({
    required int unitId,
    required int curriculumWeek,
    required String? userId,
    required String clientId,
  }) async {
    return await startTestSession(
      testMode: TestMode.weekly,
      unitId: unitId,
      curriculumWeek: curriculumWeek,
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

      return response;
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
        params: {'p_user_id': userId, 'p_unit_id': unitId},
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      log('TestRepositoryImpl.getUserStats ERROR: $e');
      return {};
    }
  }
}
