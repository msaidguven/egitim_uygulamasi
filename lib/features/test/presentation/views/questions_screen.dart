import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/features/test/presentation/viewmodels/test_view_model.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/widgets/question_card.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/components/test_progress_bar.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/components/test_bottom_nav.dart';
import 'package:egitim_uygulamasi/features/test/data/repositories/test_repository_impl.dart';

// ========== YENİ CALLBACK TANIMI ==========
typedef AnswerSaveCallback = Future<void> Function({
  required int sessionId,
  required int questionId,
  required dynamic userAnswer,
  required bool isCorrect,
  required int duration,
});
// ==========================================

// ========== RIVERPOD PROVIDER TANIMLARI ==========

final clientIdProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  String? clientId = prefs.getString('client_id');

  if (clientId == null) {
    clientId = const Uuid().v4();
    await prefs.setString('client_id', clientId);
  }

  return clientId;
});

final userIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

final testRepositoryProvider = Provider<TestRepositoryImpl>((ref) {
  return TestRepositoryImpl();
});

final testViewModelProvider = ChangeNotifierProvider.autoDispose<TestViewModel>((ref) {
  final repository = ref.watch(testRepositoryProvider);
  return TestViewModel(repository);
});

// =================================================

class QuestionsScreen extends ConsumerStatefulWidget {
  final int unitId;
  final TestMode testMode;
  final int? sessionId;
  final AnswerSaveCallback? onSave; // YENİ PARAMETRE

  const QuestionsScreen({
    super.key,
    required this.unitId,
    this.testMode = TestMode.normal,
    this.sessionId,
    this.onSave, // YENİ PARAMETRE
  });

  @override
  ConsumerState<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends ConsumerState<QuestionsScreen> {
  bool _isInitializing = true;
  String? _initializationError;
  bool _isStartingNewTest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTest();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(testViewModelProvider.notifier).reset();
      }
    });
    super.dispose();
  }

  Future<void> _initializeTest() async {
    try {
      setState(() {
        _isInitializing = true;
        _initializationError = null;
      });

      final viewModel = ref.read(testViewModelProvider.notifier);

      // YENİ: onSave callback'ini ViewModel'e iletiyoruz.
      if (widget.onSave != null) {
        viewModel.setExternalSaveCallback(widget.onSave!);
      }

      final userId = ref.read(userIdProvider);
      final clientIdAsync = await ref.read(clientIdProvider.future);

      if (userId == null || userId.isEmpty) {
        throw Exception('Kullanıcı girişi yapılmamış. Lütfen tekrar giriş yapın.');
      }

      if (clientIdAsync.isEmpty) {
        throw Exception('Cihaz kimliği alınamadı.');
      }

      if (widget.sessionId != null) {
        debugPrint('Mevcut teste devam ediliyor: sessionId=${widget.sessionId}');
        await viewModel.resumeTest(
          sessionId: widget.sessionId!,
          userId: userId,
          clientId: clientIdAsync,
        );
      } else {
        debugPrint('Yeni test başlatılıyor: unitId=${widget.unitId}, testMode=${widget.testMode}');
        _isStartingNewTest = true;

        // curriculumWeek'i arguments'tan al
        final curriculumWeek = ModalRoute.of(context)?.settings.arguments as int?;

        await viewModel.startNewTest(
          testMode: widget.testMode,
          unitId: widget.unitId,
          userId: userId,
          clientId: clientIdAsync,
          curriculumWeek: widget.testMode == TestMode.weekly ? curriculumWeek : null,
        );
        _isStartingNewTest = false;
      }

      debugPrint('Test başarıyla başlatıldı');
    } catch (e, stackTrace) {
      debugPrint('Test başlatma hatası: $e');
      debugPrint('Stack trace: $stackTrace');

      _initializationError = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _refreshTest() async {
    ref.invalidate(testViewModelProvider);
    await _initializeTest();
  }

  Future<bool> _onWillPop() async {
    final viewModel = ref.read(testViewModelProvider);

    if (_isStartingNewTest) {
      return false;
    }

    if (viewModel.sessionId == null || viewModel.currentTestQuestion == null) {
      return true;
    }

    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Testten Çıkış'),
        content: const Text('Testi bitirmeden çıkarsanız ilerlemeniz kaydedilecek. Daha sonra devam edebilirsiniz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hayır'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Evet'),
          ),
        ],
      ),
    ) ?? false;
  }

  String _getAppBarTitle() {
    switch (widget.testMode) {
      case TestMode.weekly:
        return 'Haftalık Test';
      case TestMode.wrongAnswers:
        return 'Yanlışlar Testi';
      case TestMode.normal:
      default:
        return 'Ünite Testi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(testViewModelProvider);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getAppBarTitle()),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (!_isInitializing && viewModel.error == null && _initializationError == null)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshTest,
                tooltip: 'Yenile',
              ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Colors.blue.shade300],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: _buildBody(viewModel),
        ),
      ),
    );
  }

  Widget _buildBody(TestViewModel viewModel) {
    if (_isInitializing) {
      return _buildLoadingView();
    }

    if (_initializationError != null) {
      return _buildErrorView(_initializationError!, isInitializationError: true);
    }

    if (viewModel.error != null) {
      return _buildErrorView(viewModel.error!, isInitializationError: false);
    }

    if (viewModel.currentTestQuestion == null) {
      return _buildResultsView(viewModel);
    }

    return SafeArea(
      child: Column(
        children: [
          TestProgressBar(
            currentQuestion: viewModel.answeredCount + 1,
            totalQuestions: viewModel.totalQuestions,
            score: viewModel.score,
          ),
          Expanded(
            child: QuestionCard(
              key: ValueKey(viewModel.currentTestQuestion!.question.id),
              testQuestion: viewModel.currentTestQuestion!,
              onAnswered: (answer) {
                ref.read(testViewModelProvider.notifier).updateUserAnswer(answer);
              },
            ),
          ),
          TestBottomNav(
            isChecked: viewModel.currentTestQuestion!.isChecked,
            canCheck: viewModel.currentTestQuestion!.userAnswer != null,
            isLastQuestion: viewModel.questionQueue.isEmpty,
            onCheckPressed: () {
              ref.read(testViewModelProvider.notifier).checkAnswer();
            },
            onNextPressed: () {
              ref.read(testViewModelProvider.notifier).nextQuestion();
            },
            onFinishPressed: () async {
              await ref.read(testViewModelProvider.notifier).finishTest();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            _isStartingNewTest ? 'Test başlatılıyor...' : 'Test yükleniyor...',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          if (_isStartingNewTest)
            const Text(
              'Lütfen bekleyin...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error, {required bool isInitializationError}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isInitializationError ? Icons.error_outline : Icons.warning,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              isInitializationError ? 'Başlatma Hatası' : 'Test Hatası',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _getUserFriendlyErrorMessage(error),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _refreshTest,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 15),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Geri Dön',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
            if (error.contains('network') || error.contains('internet'))
              const SizedBox(height: 15),
            if (error.contains('network') || error.contains('internet'))
              const Text(
                'İnternet bağlantınızı kontrol edin',
                style: TextStyle(color: Colors.amber, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  String _getUserFriendlyErrorMessage(String error) {
    if (error.contains('network') || error.contains('internet')) {
      return 'İnternet bağlantınızı kontrol edin. Sorunu çözdükten sonra tekrar deneyin.';
    } else if (error.contains('auth') || error.contains('login') || error.contains('giriş')) {
      return 'Oturumunuz sonlandırılmış. Lütfen tekrar giriş yapın.';
    } else if (error.contains('device') || error.contains('cihaz')) {
      return 'Cihaz kimliği alınamadı. Lütfen uygulamayı yeniden başlatın.';
    } else if (error.contains('no questions') || error.contains('soru')) {
      return 'Bu ünitede çözülebilecek soru bulunamadı.';
    } else {
      return 'Bir hata oluştu: ${error.length > 100 ? error.substring(0, 100) + '...' : error}';
    }
  }

  Widget _buildResultsView(TestViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 100, color: Colors.white),
          const SizedBox(height: 24),
          const Text(
            'Test Tamamlandı!',
            style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Toplam Puan: ${viewModel.score}',
            style: const TextStyle(fontSize: 24, color: Colors.amber, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (viewModel.totalQuestions > 0)
            Text(
              'Başarı Oranı: ${((viewModel.score / viewModel.totalQuestions) * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          const SizedBox(height: 8),
          if (viewModel.totalQuestions > 0)
            Text(
              'Çözülen Soru: ${viewModel.answeredCount}/${viewModel.totalQuestions}',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Üniteye Dön'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
