import 'package:supabase_flutter/supabase_flutter.dart';
import 'NumberCompareQuestion.dart';
import 'NumberCompositionQuestion.dart';

class QuestionService {
  final supabase = Supabase.instance.client;

  // Artık puan alıp yeni fonksiyonu çağırıyor
  Future<NumberCompareQuestion?> getCompareQuestionByScore(int score) async {
    final response = await supabase.rpc(
      'get_compare_question_by_score',
      params: {'p_score': score},
    );
    if (response == null || response.isEmpty) return null;
    return NumberCompareQuestion.fromJson(response[0]);
  }

  // Artık puan alıp yeni fonksiyonu çağırıyor
  Future<NumberCompositionQuestion?> getCompositionQuestionByScore(int score) async {
    final response = await supabase.rpc(
      'get_composition_question_by_score',
      params: {'p_score': score},
    );
    if (response == null || response.isEmpty) return null;
    return NumberCompositionQuestion.fromJson(response[0]);
  }
}
