import 'package:egitim_uygulamasi/viewmodels/profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egitim_uygulamasi/providers.dart';

import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/features/test/presentation/viewmodels/test_view_model.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/widgets/question_card.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/components/test_progress_bar.dart';
import 'package:egitim_uygulamasi/features/test/presentation/views/components/test_bottom_nav.dart';
import 'package:egitim_uygulamasi/widgets/ad_banner_widget.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuestionsScreen extends ConsumerStatefulWidget {
  final int unitId;
  final TestMode testMode;
  final int? sessionId;

  const QuestionsScreen({
    super.key,
    required this.unitId,
    this.testMode = TestMode.normal,
    this.sessionId,
  });

  @override
  ConsumerState<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends ConsumerState<QuestionsScreen> {
  bool _isInitializing = true;
  String? _initializationError;
  bool _isStartingNewTest = false;
  bool _didCleanup = false;
  double _textScale = 1.0;
  double get _maxScale => kIsWeb ? 4.0 : 1.3;
  Timer? _ticker;
  int _remainingSeconds = TestViewModel.questionTimeLimitSeconds;
  int? _activeQuestionId;
  int? _timeUpQuestionId;
  bool _isHypePlaying = false;
  final AudioPlayer _hypePlayer = AudioPlayer();
  bool _soundEnabled = false;
  bool _useBeepSound = true;
  int? _lastBeepSecond;

  static const String _prefSoundEnabled = 'test_timer_sound_enabled';
  static const String _prefUseBeepSound = 'test_timer_use_beep';

  void _increaseTextScale() {
    setState(() {
      _textScale = (_textScale + 0.1).clamp(0.9, _maxScale);
    });
  }

  void _decreaseTextScale() {
    setState(() {
      _textScale = (_textScale - 0.1).clamp(0.9, _maxScale);
    });
  }

  @override
  void initState() {
    super.initState();
    debugPrint("QuestionsScreen: initState - Test başlatılıyor...");
    _loadSoundPrefs();
    _startTicker();
    Future.microtask(() => _initializeTest());
  }

  @override
  void deactivate() {
    if (!_didCleanup) {
      final userProfile = ref.read(profileViewModelProvider).profile;
      if (userProfile != null) {
        ref.invalidate(unfinishedSessionsProvider);
      }
      if (widget.testMode == TestMode.srs) {
        ref.invalidate(srsDueCountProvider);
      }
      ref.read(testViewModelProvider.notifier).reset();
      _didCleanup = true;
    }
    super.deactivate();
  }

  @override
  void dispose() {
    debugPrint(
      "QuestionsScreen: dispose - Ekran kapatılıyor ve TestViewModel sıfırlanıyor.",
    );
    _ticker?.cancel();
    _stopHypeAudio();
    _hypePlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSoundPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _soundEnabled = prefs.getBool(_prefSoundEnabled) ?? false;
      _useBeepSound = prefs.getBool(_prefUseBeepSound) ?? true;
    });
  }

  Future<void> _saveSoundPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSoundEnabled, _soundEnabled);
    await prefs.setBool(_prefUseBeepSound, _useBeepSound);
  }

  void _showSoundSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Süre uyarı sesi'),
                    subtitle: const Text('Son 5 saniyede sesli uyarı'),
                    value: _soundEnabled,
                    onChanged: (value) {
                      setModalState(() => _soundEnabled = value);
                      setState(() => _soundEnabled = value);
                      _saveSoundPrefs();
                      if (!value) _stopHypeAudio();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Kısa bip kullan'),
                    subtitle: const Text('Müzik yerine kısa bip sesi'),
                    value: _useBeepSound,
                    onChanged: _soundEnabled
                        ? (value) {
                            setModalState(() => _useBeepSound = value);
                            setState(() => _useBeepSound = value);
                            _saveSoundPrefs();
                            _stopHypeAudio();
                          }
                        : null,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      final viewModel = ref.read(testViewModelProvider);
      final currentQuestion = viewModel.currentTestQuestion;
      if (currentQuestion == null) {
        if (_remainingSeconds != viewModel.timeLimitSeconds) {
          setState(() {
            _remainingSeconds = viewModel.timeLimitSeconds;
          });
        }
        _stopHypeAudio();
        return;
      }

      final questionId = currentQuestion.question.id;
      if (_activeQuestionId != questionId) {
        _activeQuestionId = questionId;
        _timeUpQuestionId = null;
        _stopHypeAudio();
      }

      final remaining = viewModel.remainingSeconds;
      if (remaining != _remainingSeconds) {
        setState(() {
          _remainingSeconds = remaining;
        });
      }

      if (currentQuestion.isChecked) {
        _stopHypeAudio();
        return;
      }

      if (remaining <= 5 && remaining > 0) {
        if (_soundEnabled) {
          if (_useBeepSound) {
            _playBeep(remaining);
          } else {
            _playHypeAudio();
          }
        }
      } else {
        _stopHypeAudio();
        _lastBeepSecond = null;
      }

      if (remaining == 0 && _timeUpQuestionId != questionId) {
        _timeUpQuestionId = questionId;
        _handleTimeExpired();
      }
    });
  }

  Future<void> _playHypeAudio() async {
    if (!_soundEnabled || _isHypePlaying) return;
    _isHypePlaying = true;
    try {
      await _hypePlayer.setReleaseMode(ReleaseMode.loop);
      await _hypePlayer.play(AssetSource('audio/timer_hurry.mp3'));
    } catch (_) {
      _isHypePlaying = false;
    }
  }

  Future<void> _playBeep(int remainingSeconds) async {
    if (_lastBeepSecond == remainingSeconds) return;
    _lastBeepSecond = remainingSeconds;
    _isHypePlaying = false;
    try {
      await _hypePlayer.setReleaseMode(ReleaseMode.stop);
      await _hypePlayer.play(AssetSource('audio/timer_beep.mp3'));
    } catch (_) {}
  }

  Future<void> _stopHypeAudio() async {
    if (!_isHypePlaying) return;
    _isHypePlaying = false;
    try {
      await _hypePlayer.stop();
    } catch (_) {}
  }

  Future<void> _handleTimeExpired() async {
    final viewModel = ref.read(testViewModelProvider.notifier);
    await viewModel.handleTimeExpired();
    _stopHypeAudio();
  }

  Future<void> _initializeTest() async {
    debugPrint("QuestionsScreen: _initializeTest başladı.");
    try {
      if (!mounted) {
        debugPrint(
          "QuestionsScreen: _initializeTest - Widget artık mount edilmemiş, işlem iptal edildi.",
        );
        return;
      }
      setState(() {
        _isInitializing = true;
        _initializationError = null;
      });

      final viewModel = ref.read(testViewModelProvider.notifier);
      final userProfile = ref.read(profileViewModelProvider).profile;
      final userId = userProfile?.id;

      final clientIdAsync = await ref.read(clientIdProvider.future);

      if (clientIdAsync.isEmpty) {
        throw Exception('Cihaz kimliği alınamadı.');
      }
      debugPrint("QuestionsScreen: Client ID alındı: $clientIdAsync");

      final routeArgs = ModalRoute.of(context)?.settings.arguments;
      int? curriculumWeek;
      int? topicId;
      List<int>? outcomeIds;
      if (routeArgs is int) {
        curriculumWeek = routeArgs;
      } else if (routeArgs is Map) {
        curriculumWeek = routeArgs['curriculum_week'] as int?;
        topicId = routeArgs['topic_id'] as int?;
        final rawOutcomeIds = routeArgs['outcome_ids'];
        if (rawOutcomeIds is List) {
          outcomeIds = rawOutcomeIds.whereType<int>().toList();
        }
      }

      if (widget.sessionId == null && userId == null) {
        if (widget.testMode == TestMode.weekly) {
          debugPrint(
            'QuestionsScreen: Yeni misafir haftalık testi başlatılıyor...',
          );
          if (curriculumWeek == null) {
            throw Exception(
              "Haftalık misafir testi için hafta bilgisi bulunamadı.",
            );
          }
          await viewModel.startGuestTest(
            unitId: widget.unitId,
            curriculumWeek: curriculumWeek,
            topicId: topicId,
            outcomeIds: outcomeIds,
          );
        } else if (widget.testMode == TestMode.normal) {
          debugPrint(
            'QuestionsScreen: Yeni misafir ünite testi başlatılıyor...',
          );
          await viewModel.startGuestUnitTest(unitId: widget.unitId);
        }
      } else if (widget.sessionId != null && widget.testMode != TestMode.srs) {
        debugPrint(
          'QuestionsScreen: Mevcut teste devam ediliyor: sessionId=${widget.sessionId}',
        );
        await viewModel.resumeTest(
          sessionId: widget.sessionId!,
          userId: userId,
          clientId: clientIdAsync,
        );
      } else if (widget.testMode == TestMode.srs && widget.sessionId != null) {
        debugPrint(
          'QuestionsScreen: SRS testi başlatılıyor: sessionId=${widget.sessionId}',
        );
        await viewModel.startSrsTest(
          sessionId: widget.sessionId!,
          userId: userId ?? '',
          clientId: clientIdAsync,
        );
      } else {
        debugPrint(
          'QuestionsScreen: Yeni test başlatılıyor: unitId=${widget.unitId}, testMode=${widget.testMode}, userId=$userId',
        );
        _isStartingNewTest = true;

        if (widget.testMode == TestMode.weekly) {
          debugPrint(
            "QuestionsScreen: Haftalık test için curriculumWeek: $curriculumWeek",
          );
        }

        await viewModel.startNewTest(
          testMode: widget.testMode,
          unitId: widget.unitId,
          userId: userId,
          clientId: clientIdAsync,
          curriculumWeek: widget.testMode == TestMode.weekly
              ? curriculumWeek
              : null,
          topicId: widget.testMode == TestMode.weekly ? topicId : null,
          outcomeIds: widget.testMode == TestMode.weekly ? outcomeIds : null,
        );
        _isStartingNewTest = false;
      }

      debugPrint('QuestionsScreen: Test başarıyla başlatıldı/devam ettirildi.');
    } catch (e, stackTrace) {
      debugPrint(
        'QuestionsScreen: Test başlatma sırasında bir hata oluştu: $e',
      );
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _initializationError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        debugPrint(
          "QuestionsScreen: _initializeTest tamamlandı, _isInitializing false olarak ayarlandı.",
        );
      }
    }
  }

  void _refreshSrsDueCountIfNeeded() {
    if (widget.testMode == TestMode.srs) {
      ref.invalidate(srsDueCountProvider);
    }
  }

  // _refreshTest metodu kaldırıldı.

  Future<bool> _onWillPop() async {
    debugPrint("QuestionsScreen: _onWillPop çağrıldı.");
    final viewModel = ref.read(testViewModelProvider);
    final userProfile = ref.read(profileViewModelProvider).profile;

    if (_isStartingNewTest) {
      debugPrint(
        "QuestionsScreen: _onWillPop - Yeni test başlatılırken geri gitme engellendi.",
      );
      return false;
    }

    if (userProfile == null) {
      debugPrint(
        "QuestionsScreen: _onWillPop - Misafir kullanıcı, uyarı göstermeden çıkabilir.",
      );
      return true;
    }

    if (viewModel.sessionId == null || viewModel.currentTestQuestion == null) {
      debugPrint(
        "QuestionsScreen: _onWillPop - Test oturumu veya soru yok, çıkış serbest.",
      );
      return true;
    }

    debugPrint(
      "QuestionsScreen: _onWillPop - Kullanıcıya çıkış onayı gösteriliyor.",
    );
    final shouldExit =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Testten Çıkış'),
            content: const Text(
              'Testi bitirmeden çıkarsanız ilerlemeniz kaydedilecek. Daha sonra devam edebilirsiniz.',
            ),
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
        ) ??
        false;

    if (shouldExit && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Devam etmek için kaydedildi.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return shouldExit;
  }

  String _getAppBarTitle() {
    switch (widget.testMode) {
      case TestMode.weekly:
        return 'Haftalık Test';
      case TestMode.srs:
        return 'Tekrar Testi';
      case TestMode.normal:
      default:
        return 'Ünite Testi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(testViewModelProvider);
    final isWide = MediaQuery.of(context).size.width >= 900;
    debugPrint("QuestionsScreen: build metodu çalıştı.");

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: isWide
              ? _buildWideAppBarTitle(viewModel)
              : Text(_getAppBarTitle()),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: isWide ? _buildWideAppBarBottom(viewModel) : null,
          actions: [
            TextButton(
              onPressed: _decreaseTextScale,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: const Text(
                'A-',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: _increaseTextScale,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: const Text(
                'A+',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              onPressed: _showSoundSettings,
              icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
              tooltip: 'Ses Ayarları',
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
    if (_isInitializing ||
        (viewModel.isLoading && viewModel.currentTestQuestion == null)) {
      debugPrint("QuestionsScreen: _buildBody - Yükleme ekranı gösteriliyor.");
      return _buildLoadingView();
    }

    if (_initializationError != null) {
      debugPrint(
        "QuestionsScreen: _buildBody - Başlatma hatası ekranı gösteriliyor: $_initializationError",
      );
      return _buildErrorView(
        _initializationError!,
        isInitializationError: true,
      );
    }

    if (viewModel.error != null) {
      debugPrint(
        "QuestionsScreen: _buildBody - Test hatası ekranı gösteriliyor: ${viewModel.error}",
      );
      return _buildErrorView(viewModel.error!, isInitializationError: false);
    }

    if (viewModel.currentTestQuestion == null) {
      debugPrint("QuestionsScreen: _buildBody - Sonuç ekranı gösteriliyor.");
      return _buildResultsView(viewModel);
    }

    debugPrint(
      "QuestionsScreen: _buildBody - Soru kartı gösteriliyor: Soru ID ${viewModel.currentTestQuestion!.question.id}",
    );
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                children: [
                  if (MediaQuery.of(context).size.width < 900)
                    TestProgressBar(
                      currentQuestion: viewModel.answeredCount + 1,
                      totalQuestions: viewModel.totalQuestions,
                      score: viewModel.score,
                      incorrectCount: viewModel.incorrectCount,
                      remainingSeconds: _remainingSeconds,
                      totalSeconds: viewModel.timeLimitSeconds,
                    ),
                  Expanded(
                    child: MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaleFactor: _textScale),
                      child: QuestionCard(
                        key: ValueKey(
                          viewModel.currentTestQuestion!.question.id,
                        ),
                        testQuestion: viewModel.currentTestQuestion!,
                        onAnswered: (answer) {
                          debugPrint(
                            "QuestionsScreen: onAnswered - Kullanıcı cevap verdi.",
                          );
                          ref
                              .read(testViewModelProvider.notifier)
                              .updateUserAnswer(answer);
                        },
                      ),
                    ),
                  ),
                  TestBottomNav(
                    isChecked: viewModel.currentTestQuestion!.isChecked,
                    canCheck: viewModel.currentTestQuestion!.userAnswer != null,
                    isLastQuestion: viewModel.questionQueue.isEmpty,
                    isSaving: viewModel.isSaving,
                    onCheckPressed: () async {
                      debugPrint(
                        "QuestionsScreen: onCheckPressed - Cevap kontrol ediliyor.",
                      );
                      await ref
                          .read(testViewModelProvider.notifier)
                          .checkAnswer();
                      _refreshSrsDueCountIfNeeded();
                    },
                    onNextPressed: () {
                      debugPrint(
                        "QuestionsScreen: onNextPressed - Sonraki soruya geçiliyor.",
                      );
                      ref.read(testViewModelProvider.notifier).nextQuestion();
                    },
                    onFinishPressed: () async {
                      debugPrint(
                        "QuestionsScreen: onFinishPressed - Test bitiriliyor.",
                      );
                      await ref
                          .read(testViewModelProvider.notifier)
                          .finishTest();
                      _refreshSrsDueCountIfNeeded();
                    },
                  ),
                  const SizedBox(height: 8),
                  const AdBannerWidget(margin: EdgeInsets.only(bottom: 8)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWideAppBarTitle(TestViewModel viewModel) {
    final currentQuestion = viewModel.currentTestQuestion == null
        ? viewModel.answeredCount
        : viewModel.answeredCount + 1;
    final totalQuestions = viewModel.totalQuestions;
    final remaining = _remainingSeconds;
    final score = viewModel.score;
    final wrong = viewModel.incorrectCount;

    return Row(
      children: [
        Text(
          _getAppBarTitle(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Soru $currentQuestion/$totalQuestions',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: remaining <= 5
                ? Colors.redAccent.withOpacity(0.25)
                : Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '00:${remaining.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'D: $score  Y: $wrong',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildWideAppBarBottom(TestViewModel viewModel) {
    final currentQuestion = viewModel.currentTestQuestion == null
        ? viewModel.answeredCount
        : viewModel.answeredCount + 1;
    final totalQuestions = viewModel.totalQuestions;
    final progressValue = totalQuestions > 0
        ? currentQuestion / totalQuestions
        : 0.0;
    final timeProgressValue = viewModel.timeLimitSeconds > 0
        ? _remainingSeconds / viewModel.timeLimitSeconds
        : 0.0;

    return PreferredSize(
      preferredSize: const Size.fromHeight(10),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progressValue.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
          ),
          LinearProgressIndicator(
            value: timeProgressValue.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: Colors.white.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(
              _remainingSeconds <= 5
                  ? Colors.redAccent
                  : Colors.lightBlueAccent,
            ),
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
          const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
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
              style: TextStyle(fontSize: 14, color: Colors.white70),
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
                style: const TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () =>
                      _initializeTest(), // Hata durumunda yeniden başlatma
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
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
    } else if (error.contains('auth') ||
        error.contains('login') ||
        error.contains('giriş')) {
      return 'Oturumunuz sonlandırılmış. Lütfen tekrar giriş yapın.';
    } else if (error.contains('device') || error.contains('cihaz')) {
      return 'Cihaz kimliği alınamadı. Lütfen uygulamayı yeniden başlatın.';
    } else if (error.contains('no questions') || error.contains('soru')) {
      return 'Bu ünitede çözülebilecek soru bulunamadı.';
    } else {
      return 'Bir hata oluştu: ${error.length > 100 ? '${error.substring(0, 100)}...' : error}';
    }
  }

  Widget _buildResultsView(TestViewModel viewModel) {
    final userProfile = ref.read(profileViewModelProvider).profile;
    final bool isGuest = userProfile == null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isGuest ? Icons.check_circle_outline : Icons.celebration_rounded,
            size: 100,
            color: Colors.white,
          ),
          const SizedBox(height: 24),
          Text(
            isGuest ? 'Teste Göz Attın!' : 'Test Tamamlandı!',
            style: const TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Doğru: ${viewModel.correctCount}  Yanlış: ${viewModel.incorrectCount}',
            style: const TextStyle(
              fontSize: 22,
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (viewModel.totalQuestions > 0)
            Text(
              'Başarı Oranı: ${viewModel.successPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          const SizedBox(height: 8),
          if (viewModel.totalQuestions > 0)
            Text(
              'Çözülen Soru: ${viewModel.answeredCount}/${viewModel.totalQuestions}',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          const SizedBox(height: 10),
          if (isGuest)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'İlerlemeni kalıcı kaydetmek ve istatistiklerini görmek için giriş yap.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: Text(isGuest ? 'Geri Dön' : 'Üniteye Dön'),
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
