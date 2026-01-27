import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'NumberCompareQuestion.dart';
import 'QuestionService.dart';
import 'package:egitim_uygulamasi/screens/anasinifi/tts_service.dart';

class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> with SingleTickerProviderStateMixin {
  NumberCompareQuestion? question;
  bool? isCorrect;
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
      loadQuestion();
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
      _score = prefs.getInt('compare_score') ?? 0;
    });
  }

  Future<void> _updateScore(bool correct) async {
    final prefs = await SharedPreferences.getInstance();
    int newScore = _score;
    if (correct) {
      newScore += 3; // Puan +3 olarak güncellendi
      _animationController.forward(from: 0.0);
    } else {
      newScore = (_score - 1).clamp(0, 9999);
    }
    setState(() {
      _score = newScore;
    });
    await prefs.setInt('compare_score', newScore);
  }

  Future<void> loadQuestion() async {
    setState(() {
      question = null;
      isCorrect = null;
    });

    var q = await QuestionService().getCompareQuestionByScore(_score);

    if (q != null && mounted) {
      if (Random().nextBool()) {
        q = NumberCompareQuestion(
          id: q.id,
          questionSpeech: q.questionSpeech,
          leftDisplay: q.rightDisplay,
          leftSpeech: q.rightSpeech,
          rightDisplay: q.leftDisplay,
          rightSpeech: q.leftSpeech,
          correctSide: q.correctSide == 'left' ? 'right' : 'left',
          level: q.level,
        );
      }

      setState(() {
        question = q;
      });

      TtsService.speak(q.questionSpeech);
    }
  }

  void onSelect(String side) {
    if (isCorrect != null) return;

    final correct = side == question!.correctSide;
    final selectedSpeech = side == 'left' ? question!.leftSpeech : question!.rightSpeech;

    _updateScore(correct);
    setState(() => isCorrect = correct);

    if (correct) {
      TtsService.speak("Evet. $selectedSpeech daha büyüktür.");
    } else {
      TtsService.speak("$selectedSpeech. Tekrar deneyelim.");
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => isCorrect = null);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hangisi Daha Büyük?"),
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (question == null) const CircularProgressIndicator(),
          if (question != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                numberCard(
                  text: question!.leftDisplay,
                  onTap: () => onSelect('left'),
                  isCorrect: isCorrect,
                  isThisCardCorrect: question!.correctSide == 'left',
                  isLeftCard: true,
                ),
                numberCard(
                  text: question!.rightDisplay,
                  onTap: () => onSelect('right'),
                  isCorrect: isCorrect,
                  isThisCardCorrect: question!.correctSide == 'right',
                  isLeftCard: false,
                ),
              ],
            ),
            const SizedBox(height: 30),
            AnimatedOpacity(
              opacity: isCorrect != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Column(
                children: [
                  Text(
                    isCorrect == true ? "🎉 Aferin!" : "🙂 Bir daha dene",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isCorrect == true)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Sonraki'),
                      onPressed: loadQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget numberCard({
    required String text,
    required VoidCallback onTap,
    required bool? isCorrect,
    required bool isThisCardCorrect,
    required bool isLeftCard,
  }) {
    Color? cardColor;
    if (isCorrect != null) {
      if (isCorrect && isThisCardCorrect) {
        cardColor = Colors.green;
      } else if (!isCorrect && !isThisCardCorrect) {
        cardColor = Colors.red;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: cardColor ?? (isLeftCard ? Colors.blueAccent : Colors.redAccent),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (isCorrect == true && isThisCardCorrect)
              BoxShadow(
                color: Colors.green.withOpacity(0.7),
                blurRadius: 15,
                spreadRadius: 5,
              ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 48,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
