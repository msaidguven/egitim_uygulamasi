import 'package:egitim_uygulamasi/features/test/presentation/views/questions_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeeklyTestScreen extends StatefulWidget {
  final int topicId;
  final int weekNo;

  const WeeklyTestScreen({
    super.key,
    required this.topicId,
    required this.weekNo,
  });

  @override
  State<WeeklyTestScreen> createState() => _WeeklyTestScreenState();
}

class _WeeklyTestScreenState extends State<WeeklyTestScreen> {
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _startTestAndNavigate();
  }

  Future<void> _startTestAndNavigate() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        throw 'Kullanıcı oturumu bulunamadı.';
      }

      // RPC'yi çağır, ancak .single() kullanma. Bu, ham yanıtı almamızı sağlar.
      final response = await supabase.rpc(
        'start_weekly_test',
        params: {
          'p_user_id': currentUser.id,
          'p_topic_id': widget.topicId,
          'p_week': widget.weekNo,
        },
      );

      // Gelen yanıtın (response) kendisini kontrol et.
      // Yeni RPC bir satır ve iki sütun döndürür: [{'session_id': 1, 'unit_id': 2}]
      // Eski RPC sadece bir değer döndürür: 1
      if (response is List && response.isNotEmpty && response.first is Map<String, dynamic>) {
        // Beklenen durum: Yanıt bir Map listesi ise (yeni RPC versiyonu)
        final data = response.first as Map<String, dynamic>;
        final unitId = data['unit_id'] as int?;

        if (unitId == null) {
          throw 'Test için gerekli unit_id alınamadı.';
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => QuestionsScreen(
                unitId: unitId,
              ),
            ),
          );
        }
      } else if (response is int) {
        // Eski RPC versiyonu hala devrede. Kullanıcıyı uyar.
        throw 'Veritabanı fonksiyonu güncel değil. Lütfen `0035_create_start_weekly_test_rpc.sql` dosyasındaki değişiklikleri veritabanına uygulayın. Fonksiyonun (session_id, unit_id) döndürmesi gerekirken sadece bir sayı (session_id) döndürüyor.';
      }
      else {
        // Beklenmedik bir durum
        throw 'Veritabanından beklenmedik bir formatta yanıt alındı. Gelen veri: "$response"';
      }

    } catch (e) {
      setState(() {
        _error = e;
        _isLoading = false;
      });
      debugPrint("Haftalık test başlatılırken ve yönlendirilirken hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Başlatılıyor...'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Test yüklenemedi:\n$_error',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _startTestAndNavigate,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
