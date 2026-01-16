import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:egitim_uygulamasi/screens/anasinifi/tts_service.dart';
import 'QuestionService.dart';
import 'NumberCompositionQuestion.dart';

class NumberCompositionPage extends StatefulWidget {
  const NumberCompositionPage({super.key});

  @override
  State<NumberCompositionPage> createState() => _NumberCompositionPageState();
}

class _NumberCompositionPageState extends State<NumberCompositionPage> with SingleTickerProviderStateMixin {
  NumberCompositionQuestion? _question;
  List<String?>? _answerSlots;
  String? _feedbackMessage;
  bool _isCorrect = false;
  int _score = 0;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _loadScore().then((_) {
      _loadQuestion();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _score = prefs.getInt('composition_score') ?? 0;
    });
  }

  Future<void> _saveScore(int newScore) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('composition_score', newScore);
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _question = null;
      _feedbackMessage = null;
      _isCorrect = false;
    });

    var q = await QuestionService().getCompositionQuestionByScore(_score);

    if (q != null && mounted) {
      setState(() {
        _question = q;
        _answerSlots = List.filled(q.correctAnswer.length, null);
      });
      TtsService.speak(q.questionSpeech);
    }
  }

  void _onNumberDrop(int index, String number) {
    if (_answerSlots![index] == null) {
      setState(() {
        _answerSlots![index] = number;
        _feedbackMessage = null;
      });
    }

    if (!_answerSlots!.contains(null)) {
      _checkAnswer();
    }
  }

  void _checkAnswer() {
    final userAnswer = _answerSlots!.join('');
    final isAnswerCorrect = userAnswer == _question!.correctAnswer;
    int newScore = _score;

    if (isAnswerCorrect) {
      newScore += 3; // Puan +3 olarak güncellendi
      _animationController.forward(from: 0.0);
      TtsService.speak('Evet, doğru bildin!');
    } else {
      newScore = (_score - 1).clamp(0, 9999);
      TtsService.speak('Olmadı, tekrar deneyelim.');
    }
    
    _saveScore(newScore);
    setState(() {
      _score = newScore;
      _isCorrect = isAnswerCorrect;
      _feedbackMessage = isAnswerCorrect ? '🎉 Aferin!' : '🙂 Tekrar deneyelim';
    });

    if (!isAnswerCorrect) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _answerSlots = List.filled(_question!.correctAnswer.length, null);
            _feedbackMessage = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sayıyı Oluştur'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Chip(
                backgroundColor: Colors.amber,
                avatar: ScaleTransition(
                  scale: _scaleAnimation,
                  child: const Icon(Icons.star, color: Colors.white),
                ),
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: Text(
                    '$_score',
                    key: ValueKey<int>(_score),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _question == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_up, size: 40, color: Colors.blue),
                        onPressed: () => TtsService.speak(_question!.questionSpeech),
                      ),
                      const SizedBox(height: 20),
                      _buildAnswerSlots(),
                      const SizedBox(height: 30),
                      _buildFeedback(),
                    ],
                  ),
                ),
                _buildNumberPad(),
              ],
            ),
    );
  }

  Widget _buildAnswerSlots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_answerSlots!.length, (index) {
        return DragTarget<String>(
          builder: (context, candidateData, rejectedData) {
            return Container(
              width: 80,
              height: 100,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: _answerSlots![index] != null ? Colors.indigo.shade100 : Colors.grey.shade200,
                border: Border.all(
                  color: candidateData.isNotEmpty ? Colors.green : Colors.grey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _answerSlots![index] != null
                  ? Center(
                      child: Text(
                        _answerSlots![index]!,
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                    )
                  : null,
            );
          },
          onWillAccept: (data) => _answerSlots![index] == null,
          onAccept: (data) {
            _onNumberDrop(index, data);
          },
        );
      }),
    );
  }

  Widget _buildFeedback() {
    return AnimatedOpacity(
      opacity: _feedbackMessage != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: [
          Text(
            _feedbackMessage ?? '',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (_isCorrect)
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Sonraki'),
              onPressed: _loadQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            )
          else
            const SizedBox(height: 58),
        ],
      ),
    );
  }

  Widget _buildNumberPad() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: GridView.count(
        crossAxisCount: 5,
        shrinkWrap: true,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(10, (index) {
          final number = '$index';
          final isUsed = _answerSlots?.contains(number) ?? false;
          return Draggable<String>(
            data: number,
            feedback: _buildNumberChip(number, isDragging: true),
            childWhenDragging: _buildNumberChip(number, isDragging: false, isUsed: true),
            child: _buildNumberChip(number, isUsed: isUsed),
          );
        }),
      ),
    );
  }

  Widget _buildNumberChip(String number, {bool isDragging = false, bool isUsed = false}) {
    return Material(
      elevation: isDragging ? 8 : 2,
      borderRadius: BorderRadius.circular(100),
      color: isUsed ? Colors.grey.shade400 : Colors.blue.shade300,
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
