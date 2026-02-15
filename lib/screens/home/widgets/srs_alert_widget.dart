import 'package:flutter/material.dart';

class SrsAlertWidget extends StatelessWidget {
  final int questionCount;
  final VoidCallback onReviewTap;
  final bool showActionButton;
  final String? guestMessage;

  const SrsAlertWidget({
    super.key,
    this.questionCount = 5,
    required this.onReviewTap,
    this.showActionButton = true,
    this.guestMessage,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDue = questionCount > 0;
    final Color accentColor = hasDue
        ? const Color(0xFF0EA5E9)
        : const Color(0xFF22C55E);
    final Color accentWarm = hasDue
        ? const Color(0xFFF97316)
        : const Color(0xFF06B6D4);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFEFF9FF), Color(0xFFF7FCFF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasDue ? const Color(0xFFD0ECFF) : const Color(0xFFCDEFD7),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -26,
            right: -18,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBEE8FF).withValues(alpha: 0.35),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.18),
                      accentWarm.withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('🧠', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Zamanı Gelen Tekrarlar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      showActionButton
                          ? (questionCount > 0
                                ? '$questionCount soru için tekrar zamanı geldi. Öğrendiklerini tazele.'
                                : 'Şu an tekrar etmen gereken soru yok. Harika gidiyorsun.')
                          : (guestMessage ??
                                'Zamanı gelen soruları çözmek için giriş yapın.'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (showActionButton && questionCount > 0)
                      FilledButton.icon(
                        onPressed: onReviewTap,
                        icon: const Icon(Icons.bolt_rounded, size: 16),
                        label: const Text('Şimdi Tekrar Et'),
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
