import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'questions_screen.dart';

class UnitSummaryScreen extends StatefulWidget {
  final int unitId;

  const UnitSummaryScreen({super.key, required this.unitId});

  @override
  State<UnitSummaryScreen> createState() => _UnitSummaryScreenState();
}

class _UnitSummaryScreenState extends State<UnitSummaryScreen> {
  late Future<Map<String, dynamic>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    final prefs = await SharedPreferences.getInstance();
    final clientId = prefs.getString('client_id');

    setState(() {
      _summaryFuture = client.rpc(
        'get_unit_summary',
        params: {
          'p_user_id': userId,
          'p_unit_id': widget.unitId,
          'p_client_id': clientId,
        },
      ).then((data) => Map<String, dynamic>.from(data));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ünite Özeti'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
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

                if (activeSession != null) _buildActiveSessionCard(activeSession),

                _buildStatsGrid(data),

                const SizedBox(height: 32),

                if (activeSession != null)
                  _buildButton(
                    label: 'Teste Devam Et',
                    icon: Icons.play_circle_fill,
                    color: Colors.green,
                    onPressed: () => _navigateToTest(),
                  ),
                
                _buildButton(
                  label: activeSession == null ? 'Teste Başla' : 'Yeni Test Başlat',
                  icon: Icons.add_task,
                  onPressed: () => _navigateToTest(),
                ),

                _buildButton(
                  label: 'Sadece Yanlışları Çöz',
                  icon: Icons.error_outline,
                  color: Colors.orange,
                  onPressed: hasIncorrect ? () => _navigateToTest() : null,
                ),

                _buildButton(
                  label: 'Tüm Soruları Tekrar Çöz',
                  icon: Icons.refresh,
                  color: Colors.grey,
                  onPressed: () => _navigateToTest(),
                ),
              ],
            ),
          );
        },
      ),
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
      childAspectRatio: 1.5,
      children: [
        _statCard('Toplam Soru', data['total_questions'], Colors.blue),
        _statCard('Çözülen', data['solved_questions'], Colors.purple),
        _statCard('Doğru', data['correct_count'], Colors.green),
        _statCard('Yanlış', data['incorrect_count'], Colors.red),
      ],
    );
  }

  Widget _statCard(String label, dynamic value, Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withOpacity(0.2))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
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
          backgroundColor: color,
          foregroundColor: color != null ? Colors.white : null,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _navigateToTest() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuestionsScreen(unitId: widget.unitId)),
    );
    _loadSummary();
  }
}
