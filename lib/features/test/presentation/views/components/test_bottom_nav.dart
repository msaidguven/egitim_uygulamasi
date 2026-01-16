import 'package:flutter/material.dart';

class TestBottomNav extends StatelessWidget {
  final bool isChecked;
  final bool canCheck;
  final bool isLastQuestion;
  final VoidCallback? onCheckPressed;
  final VoidCallback? onNextPressed;
  final VoidCallback? onFinishPressed;

  const TestBottomNav({
    super.key,
    required this.isChecked,
    required this.canCheck,
    required this.isLastQuestion,
    this.onCheckPressed,
    this.onNextPressed,
    this.onFinishPressed,
  });

  @override
  Widget build(BuildContext context) {
    final String buttonText = !isChecked
        ? 'Kontrol Et'
        : (isLastQuestion ? 'Testi Bitir' : 'Sonraki Soru');

    final VoidCallback? onPressedAction = !isChecked
        ? (canCheck ? onCheckPressed : null)
        : (isLastQuestion ? onFinishPressed : onNextPressed);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: onPressedAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: isChecked ? Colors.green : Colors.amber,
                foregroundColor: isChecked ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 4,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}