import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Belirli bir konunun işlendiği haftayı temsil eden veri modeli.
class TopicWeekInfo {
  final int id;
  final int startWeek;
  final int? outcomeId; // Kazanım ID'si, şimdilik opsiyonel

  TopicWeekInfo({
    required this.id,
    required this.startWeek,
    this.outcomeId,
  });

  factory TopicWeekInfo.fromJson(Map<String, dynamic> json) {
    return TopicWeekInfo(
      id: json['id'] as int,
      startWeek: json['start_week'] as int,
      outcomeId: json['outcome_id'] as int?,
    );
  }
}

/// Bir topicId'ye göre o konunun işlendiği haftaları getiren FutureProvider.
/// .family değiştiricisi, provider'a dışarıdan bir parametre (topicId) geçmemizi sağlar.
final weeksForTopicProvider =
    FutureProvider.family<List<TopicWeekInfo>, int>((ref, topicId) async {
  final supabase = Supabase.instance.client;

  try {
    // Supabase'deki RPC'yi çağırıyoruz.
    final response = await supabase.rpc(
      'get_weeks_for_topic',
      params: {'p_topic_id': topicId},
    );

    // Gelen veri bir liste değilse hata fırlat.
    if (response is! List) {
      throw Exception('Beklenmedik veri formatı: RPC sonucu bir liste değil.');
    }

    // Gelen JSON listesini TopicWeekInfo nesnelerine dönüştür.
    final weeks = response
        .map((item) => TopicWeekInfo.fromJson(item as Map<String, dynamic>))
        .toList();
        
    return weeks;
  } catch (e) {
    // Hata durumunda konsola yazdır ve hatayı yeniden fırlat.
    // Riverpod bu hatayı yakalayıp AsyncValue.error durumuna geçirecektir.
    print('Haftalık kazanımlar getirilirken hata: $e');
    rethrow;
  }
});
