import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/screens/home/widgets/pressable_card.dart';

final _lessonDetails = {
  1: {
    'icon': Icons.calculate_rounded,
    'gradient': [Color(0xFFFF8A65), Color(0xFFFF5252)],
  },
  2: {
    'icon': Icons.translate_rounded,
    'gradient': [Color(0xFF64B5F6), Color(0xFF42A5F5)],
  },
  3: {
    'icon': Icons.science_rounded,
    'gradient': [Color(0xFF81C784), Color(0xFF66BB6A)],
  },
  4: {
    'icon': Icons.public_rounded,
    'gradient': [Color(0xFFE57373), Color(0xFFEF5350)],
  },
  5: {
    'icon': Icons.gavel_rounded,
    'gradient': [Color(0xFFBA68C8), Color(0xFFAB47BC)],
  },
  6: {
    'icon': Icons.language_rounded,
    'gradient': [Color(0xFF4DB6AC), Color(0xFF26A69A)],
  },
};

class LessonCard extends StatelessWidget {
  final int lessonId;
  final String lessonName;
  final String? topicTitle;
  final String? gradeName; // Sınıf adı eklendi
  final int? curriculumWeek;
  final double progress;
  final double successRate;
  final VoidCallback onTap;
  final bool isNextStep;
  final String? lessonIcon; // Veritabanından gelen emoji ikon

  // İstatistikler
  final int? totalQuestions;
  final int? correctCount;
  final int? wrongCount;
  final int? unsolvedCount;

  const LessonCard({
    super.key,
    required this.lessonId,
    required this.lessonName,
    this.topicTitle,
    this.gradeName,
    this.curriculumWeek,
    required this.progress,
    required this.successRate,
    required this.onTap,
    this.isNextStep = false,
    this.lessonIcon,
    this.totalQuestions,
    this.correctCount,
    this.wrongCount,
    this.unsolvedCount,
  });

  @override
  Widget build(BuildContext context) {
    final details =
        _lessonDetails[lessonId] ??
        {
          'icon': Icons.book_rounded,
          'gradient': [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        };

    final gradient = details['gradient'] as List<Color>;
    final icon = details['icon'] as IconData;
    final statusColor = _statusColor(progress, successRate);

    return PressableCard(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(Colors.white, gradient.first, 0.12)!,
              Color.lerp(const Color(0xFFF4F8FF), statusColor, 0.12)!,
              const Color(0xFFF8FBFF),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: statusColor.withValues(alpha: 0.34)),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.14),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -26,
              right: -14,
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gradient.last.withValues(alpha: 0.14),
                ),
              ),
            ),
            Positioned(
              bottom: -28,
              left: -14,
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gradient.first.withValues(alpha: 0.09),
                ),
              ),
            ),
            Column(
              children: [
                // Üst Kısım: İkon ve Başlıklar
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Renkli ikon alanı
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: gradient.first.withValues(alpha: 0.26),
                              blurRadius: 7,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: lessonIcon != null
                            ? Center(
                                child: Text(
                                  lessonIcon!,
                                  style: const TextStyle(fontSize: 26),
                                ),
                              )
                            : Icon(icon, color: Colors.white, size: 26),
                      ),

                      const SizedBox(width: 12),

                      // Metin alanı
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hiyerarşi: Sınıf -> Ders -> Konu
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (gradeName != null) ...[
                                  Text(
                                    gradeName!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: Colors.grey.shade400,
                                  ),
                                ],
                                Text(
                                  lessonName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: gradient.first,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            // Ana Başlık (Konu veya Ders)
                            Text(
                              topicTitle ?? lessonName,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (curriculumWeek != null) ...[
                              const SizedBox(height: 7),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: gradient.last.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: gradient.last.withValues(
                                      alpha: 0.28,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '$curriculumWeek. hafta',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: gradient.last,
                                  ),
                                ),
                              ),
                            ],
                            if (isNextStep) ...[
                              const SizedBox(height: 7),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF2F6FE4,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF2F6FE4,
                                    ).withValues(alpha: 0.25),
                                  ),
                                ),
                                child: const Text(
                                  'Önerilen',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2F6FE4),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // İlerleme Yüzdesi (Dairesel)
                      Column(
                        children: [
                          SizedBox(
                            width: 42,
                            height: 42,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: progress / 100,
                                  strokeWidth: 4,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    statusColor,
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    '${progress.toInt()}%',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade800,
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
                ),

                // Alt Kısım: İstatistikler (Varsa)
                if (totalQuestions != null && totalQuestions! > 0) ...[
                  Container(height: 1, color: const Color(0xFFE8F0FF)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        // Toplam Soru
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF4FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD7E6FF)),
                          ),
                          child: Text(
                            '$totalQuestions Soru',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const Spacer(),

                        // Doğru
                        _buildStatItem(
                          count: correctCount ?? 0,
                          label: 'd',
                          color: const Color(0xFF10B981), // Emerald
                        ),
                        const SizedBox(width: 10),

                        // Yanlış
                        _buildStatItem(
                          count: wrongCount ?? 0,
                          label: 'y',
                          color: const Color(0xFFEF4444), // Red
                        ),
                        const SizedBox(width: 10),

                        // Çözülmedi
                        _buildStatItem(
                          count: unsolvedCount ?? 0,
                          label: 'boş',
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(double progress, double successRate) {
    if (progress >= 100 && successRate >= 80) {
      return const Color(0xFF16A34A);
    }
    if (progress >= 60 || successRate >= 60) {
      return const Color(0xFF2F6FE4);
    }
    return const Color(0xFFEF6C2F);
  }

  Widget _buildStatItem({
    required int count,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
