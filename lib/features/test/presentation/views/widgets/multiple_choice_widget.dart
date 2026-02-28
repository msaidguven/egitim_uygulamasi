import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:egitim_uygulamasi/features/test/data/models/test_question.dart';
import 'package:egitim_uygulamasi/widgets/question_text.dart';

class MultipleChoiceWidget extends StatelessWidget {
  final TestQuestion testQuestion;
  final ValueChanged<dynamic> onAnswered;

  const MultipleChoiceWidget({
    super.key,
    required this.testQuestion,
    required this.onAnswered,
  });

  @override
  Widget build(BuildContext context) {
    final question = testQuestion.question;
    final isChecked = testQuestion.isChecked;
    final isNarrow = MediaQuery.of(context).size.width < 700;

    final choices = testQuestion.shuffledChoices;

    return ListView.separated(
      itemCount: choices.length,
      separatorBuilder: (_, __) => SizedBox(height: isNarrow ? 12 : 16),
      itemBuilder: (context, index) {
        final choice = choices[index];
        bool isSelected = (testQuestion.userAnswer == choice.id);
        
        Color bgColor = Colors.white;
        Color borderColor = const Color(0xFFE2E8F0);
        Color textColor = Colors.black87;
        Widget? trailingIcon;
        bool shouldAnimateReaction = false;

        if (isChecked) {
          if (choice.isCorrect) {
            // Doğru cevap rengi ve animasyonu
            bgColor = const Color(0xFFECFDF5); // Açık yeşil
            borderColor = const Color(0xFF10B981); // Zümrüt yeşili
            textColor = const Color(0xFF065F46);
            trailingIcon = Icon(Icons.stars_rounded, color: borderColor, size: 28)
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 400.ms);
            shouldAnimateReaction = true;
          } else if (isSelected) {
            // Yanlış seçilmiş cevap rengi ve animasyonu
            bgColor = const Color(0xFFFEF2F2); // Açık kırmızı
            borderColor = const Color(0xFFEF4444); // Kırmızı
            textColor = const Color(0xFF991B1B);
            trailingIcon = Icon(Icons.cancel_rounded, color: borderColor, size: 28);
            shouldAnimateReaction = true;
          } else {
            // İşaretlenmemiş yanlış seçenekler soluklaşsın
            bgColor = Colors.grey.shade50;
            borderColor = Colors.grey.shade300;
            textColor = Colors.grey.shade500;
          }
        } else if (isSelected) {
          // Seçili hali ama henüz kontrol edilmedi
          bgColor = const Color(0xFFEFF6FF); // Açık mavi
          borderColor = const Color(0xFF3B82F6); // Mavi
          textColor = const Color(0xFF1E3A8A);
          trailingIcon = Icon(Icons.radio_button_checked_rounded, color: borderColor);
        } else {
          // Boş, seçilebilir hali
          bgColor = Colors.white;
          borderColor = const Color(0xFFCBD5E1);
          textColor = Colors.black87;
          trailingIcon = Icon(Icons.radio_button_unchecked_rounded, color: Colors.grey.shade300);
        }

        Widget choiceContainer = GestureDetector(
          onTap: isChecked ? null : () => onAnswered(choice.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 16 : 20,
              vertical: isNarrow ? 16 : 20,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(
                color: borderColor,
                width: isSelected || isChecked ? 3.0 : 2.0, // Kalın, çizgi roman tarzı border
              ),
              borderRadius: BorderRadius.circular(20), // Daha yuvarlak hatlar
              boxShadow: [
                BoxShadow(
                  color: borderColor.withOpacity(isSelected || isChecked ? 0.3 : 0.1),
                  blurRadius: isSelected || isChecked ? 8 : 4,
                  offset: const Offset(0, 4), // Belirgin alt gölge
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: QuestionText(
                    text: choice.text,
                    fontSize: isNarrow ? 16 : 18,
                    textColor: textColor,
                    fractionColor: textColor,
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 12),
                  trailingIcon,
                ],
              ],
            ),
          ),
        );

        // Giriş animasyonu
        Widget animatedChoice = choiceContainer.animate(delay: (index * 100).ms)
            .slideX(begin: 0.2, end: 0, curve: Curves.easeOutQuad, duration: 400.ms)
            .fadeIn(duration: 400.ms);

        // Doğru/yanlış reaksiyonu eklenecekse ekle
        if (isChecked && shouldAnimateReaction) {
          if (choice.isCorrect) {
            animatedChoice = animatedChoice.animate()
                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.elasticOut, duration: 800.ms)
                .tint(color: Colors.green.withOpacity(0.2), duration: 400.ms);
          } else if (isSelected) {
            animatedChoice = animatedChoice.animate()
                .shake(hz: 4, curve: Curves.easeInOutCubic, duration: 400.ms) // Kafa sallama animasyonu
                .tint(color: Colors.red.withOpacity(0.1), duration: 300.ms);
          }
        }

        return animatedChoice;
      },
    );
  }
}
