import 'dart:math';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/questions_screen.dart';

class UnitSummaryScreen extends StatefulWidget {
  final int unitId;

  const UnitSummaryScreen({super.key, required this.unitId});

  @override
  State<UnitSummaryScreen> createState() => _UnitSummaryScreenState();
}

class _UnitSummaryScreenState extends State<UnitSummaryScreen> {
  late Future<Map<String, dynamic>> _summaryFuture;
  Map<String, dynamic>? _summaryData;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
  }

  Future<Map<String, dynamic>> _loadSummary() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    if (userId == null) {
      setState(() {
        _isGuest = true;
      });
      // Misafir kullanıcı için varsayılan bir yapı döndür,
      // böylece arayüzde butonlar gösterilebilir.
      final unitData = await client.from('units').select('title').eq('id', widget.unitId).single();
      return {
        'unit_name': unitData['title'] ?? 'Ünite Testi',
        'total_questions': 0,
        'unique_solved_count': 0,
        'correct_count': 0,
        'incorrect_count': 0,
        'success_rate': 0.0,
        'active_session': null,
        'available_question_count': 10, // Testi başlatma butonunu göstermek için
      };
    }

    final prefs = await SharedPreferences.getInstance();
    final clientId = prefs.getString('client_id');

    final response = await client.rpc(
      'get_unit_summary',
      params: {
        'p_user_id': userId,
        'p_unit_id': widget.unitId,
        'p_client_id': clientId,
      },
    );
    _summaryData = Map<String, dynamic>.from(response);
    return _summaryData!;
  }

  void _refreshSummary() {
    // Misafir kullanıcılar için yenileme işlemi yapmaya gerek yok.
    if (_isGuest) return;
    setState(() {
      _summaryFuture = _loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ünite Özeti'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final activeSession = data['active_session'];
          final hasIncorrect = (data['incorrect_count'] ?? 0) > 0;
          final totalQuestions = data['total_questions'] ?? 0;
          final uniqueSolved = data['unique_solved_count'] ?? 0;
          final progress = totalQuestions > 0 ? uniqueSolved / totalQuestions : 0.0;
          final availableQuestionCount = data['available_question_count'] ?? 0;
          final questionsInNextSession = min(availableQuestionCount, 10);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  data['unit_name'] ?? 'Ünite',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                if (!_isGuest) ...[
                  _buildProgressCircle(progress, data['success_rate']),
                  const SizedBox(height: 24),
                  if (activeSession != null) _buildActiveSessionCard(activeSession),
                  _buildStatsGrid(data),
                  const SizedBox(height: 32),
                ] else ...[
                  // Misafir için bilgilendirme kartı
                  Card(
                    color: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'İlerlemeni ve istatistiklerini görmek için giriş yapmalısın. Misafir testleri sadece göz atmak içindir ve kaydedilmez.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blue.shade800, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Kayıtlı kullanıcı için devam etme butonu
                if (!_isGuest && activeSession != null)
                  _buildButton(
                    label: 'Teste Devam Et',
                    icon: Icons.play_circle_fill,
                    color: Colors.green.shade600,
                    onPressed: () => _navigateToTest(
                      testMode: TestMode.normal,
                      sessionId: activeSession['id'],
                    ),
                  )
                // Kayıtlı kullanıcı için yeni test butonu
                else if (!_isGuest && availableQuestionCount > 0) ...[
                  if (availableQuestionCount > 10) _buildInfoCard(availableQuestionCount),
                  _buildButton(
                    label: 'Teste Başla ($questionsInNextSession Soru)',
                    icon: Icons.add_task,
                    onPressed: () => _navigateToTest(testMode: TestMode.normal),
                  ),
                ]
                // Misafir kullanıcı için test butonu
                else if (_isGuest)
                  _buildButton(
                    label: 'Ünite Testine Göz At',
                    icon: Icons.visibility,
                    onPressed: () => _navigateToTest(testMode: TestMode.normal),
                  ),

                // Kayıtlı kullanıcı için tüm sorular bitti mesajı
                if (!_isGuest && totalQuestions > 0 && uniqueSolved == totalQuestions)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                      child: Text(
                        'Bu ünitedeki tüm soruları tamamladın. Tekrar zamanı gelen yeni soru bulunmuyor. Harika iş!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                // Sadece kayıtlı kullanıcılar için yanlışları çöz butonu
                if (!_isGuest)
                  _buildButton(
                    label: 'Sadece Yanlışları Çöz',
                    icon: Icons.error_outline,
                    color: Colors.orange.shade600,
                    onPressed: hasIncorrect ? () => _navigateToTest(testMode: TestMode.wrongAnswers) : null,
                  ),

              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(int availableCount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 14),
                  children: [
                    const TextSpan(text: 'Bu ünitede çözülmeye hazır toplam '),
                    TextSpan(
                      text: '$availableCount soru',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' var. Testler 10 soruluk oturumlar halinde sunulur.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCircle(double progress, dynamic successRate) {
    final color = progress < 0.5 ? Colors.orange : Colors.green;
    return CircularPercentIndicator(
      radius: 80.0,
      lineWidth: 12.0,
      percent: progress,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 36.0),
          ),
          const Text("Tamamlandı", style: TextStyle(fontSize: 14.0))
        ],
      ),
      footer: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Text(
          'Genel Başarı Oranı: ${successRate.toStringAsFixed(1)}%',
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
        ),
      ),
      circularStrokeCap: CircularStrokeCap.round,
      progressColor: color,
      backgroundColor: Colors.grey.shade300,
    );
  }

  Widget _buildActiveSessionCard(Map<String, dynamic> session) {
    double progress = session['answered'] / session['total'];
    return Card(
      color: Colors.blue.shade50,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.blue.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Yarım Kalan Testin Var!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress, backgroundColor: Colors.white, color: Colors.blue, minHeight: 8, borderRadius: BorderRadius.circular(8)),
            const SizedBox(height: 8),
            Text('${session['total']} sorudan ${session['answered']} tanesini çözdün.', style: TextStyle(color: Colors.blue.shade800)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: [
        _statCard('Toplam Soru', data['total_questions'], Colors.blue),
        _statCard('Çözülen (Benzersiz)', data['unique_solved_count'], Colors.purple),
        _statCard('Doğru Cevap', data['correct_count'], Colors.green),
        _statCard('Yanlış Cevap', data['incorrect_count'], Colors.red),
      ],
    );
  }

  Widget _statCard(String label, dynamic value, Color color) {
    final textColor = color.withOpacity(1.0);
    final labelColor = color.withOpacity(0.8);

    return Card(
      elevation: 0,
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: labelColor), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildButton({required String label, required IconData icon, Color? color, VoidCallback? onPressed}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
    );
  }

  void _navigateToTest({required TestMode testMode, int? sessionId}) async {
    // Misafir kullanıcı için sessionId her zaman null olmalı
    final guestSessionId = _isGuest ? null : sessionId;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuestionsScreen(
        unitId: widget.unitId,
        testMode: testMode,
        sessionId: guestSessionId,
      )),
    );
    _refreshSummary();
  }
}
