import 'package:flutter/material.dart';

final _lessonDetails = {
  1: {
    'color': Color(0xFFFF8A65),
    'darkColor': Color(0xFFE64A19),
    'icon': Icons.calculate_rounded,
    'gradient': [Color(0xFFFF8A65), Color(0xFFFF5252)]
  },
  2: {
    'color': Color(0xFF64B5F6),
    'darkColor': Color(0xFF1976D2),
    'icon': Icons.translate_rounded,
    'gradient': [Color(0xFF64B5F6), Color(0xFF42A5F5)]
  },
  3: {
    'color': Color(0xFF81C784),
    'darkColor': Color(0xFF388E3C),
    'icon': Icons.science_rounded,
    'gradient': [Color(0xFF81C784), Color(0xFF66BB6A)]
  },
  4: {
    'color': Color(0xFFE57373),
    'darkColor': Color(0xFFD32F2F),
    'icon': Icons.public_rounded,
    'gradient': [Color(0xFFE57373), Color(0xFFEF5350)]
  },
  5: {
    'color': Color(0xFFBA68C8),
    'darkColor': Color(0xFF7B1FA2),
    'icon': Icons.gavel_rounded,
    'gradient': [Color(0xFFBA68C8), Color(0xFFAB47BC)]
  },
  6: {
    'color': Color(0xFF4DB6AC),
    'darkColor': Color(0xFF00796B),
    'icon': Icons.language_rounded,
    'gradient': [Color(0xFF4DB6AC), Color(0xFF26A69A)]
  },
};

class LessonCard extends StatelessWidget {
  final int lessonId;
  final String lessonName;
  final String topicTitle;
  final int? weekNo;
  final double progress;
  final double successRate;
  final VoidCallback onTap;
  final bool isNextStep;

  const LessonCard({
    super.key,
    required this.lessonId,
    required this.lessonName,
    required this.topicTitle,
    this.weekNo,
    required this.progress,
    required this.successRate,
    required this.onTap,
    this.isNextStep = false,
  });

  @override
  Widget build(BuildContext context) {
    final details = _lessonDetails[lessonId] ?? {
      'color': Colors.grey,
      'darkColor': Colors.grey.shade700,
      'icon': Icons.book_rounded,
      'gradient': [Colors.grey, Colors.grey.shade600]
    };

    final color = details['color'] as Color;
    final darkColor = details['darkColor'] as Color;
    final icon = details['icon'] as IconData;
    final gradientColors = details['gradient'] as List<Color>;

    final score = ((progress * successRate) / 100).toInt();

    return Container(
      height: 215, // Daha kompakt yükseklik
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadowColor: color.withOpacity(0.3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0), // Padding küçült
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ÜST BÖLÜM: Başlık ve ikon
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // İkon container'ı - KÜÇÜLTÜLDÜ
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              icon,
                              color: Colors.white,
                              size: 20, // İkon boyutu küçült
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Başlık alanı
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Hafta/ Ders etiketi
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isNextStep ? '$weekNo. Hafta' : lessonName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Konu başlığı
                              Text(
                                isNextStep ? lessonName : topicTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // İleri ok ikonu (sadece nextStep için)
                        if (isNextStep) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: darkColor,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ORTA BÖLÜM: İlerleme barı
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'İlerleme',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${progress.toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Progress bar
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Stack(
                            children: [
                              // İlerleme dolgusu
                              Container(
                                width: (MediaQuery.of(context).size.width - 64) * (progress / 100),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ALT BÖLÜM: İstatistikler
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Çözülen yüzde
                          _CompactInfoChip(
                            icon: Icons.check_circle_rounded,
                            value: '${progress.toInt()}%',
                            label: 'Çözülen',
                            color: color,
                          ),

                          // Ayırıcı
                          Container(
                            width: 1,
                            height: 24,
                            color: Colors.white.withOpacity(0.2),
                          ),

                          // Başarı yüzdesi
                          _CompactInfoChip(
                            icon: Icons.trending_up_rounded,
                            value: '${successRate.toInt()}%',
                            label: 'Başarı',
                            color: color,
                          ),

                          // Ayırıcı
                          Container(
                            width: 1,
                            height: 24,
                            color: Colors.white.withOpacity(0.2),
                          ),

                          // Puan
                          _CompactInfoChip(
                            icon: Icons.workspace_premium_rounded,
                            value: '$score',
                            label: 'Puan',
                            isScore: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactInfoChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;
  final bool isScore;

  const _CompactInfoChip({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.isScore = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isScore ? Colors.amber : (color ?? Colors.white),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// EN BASİT VE GARANTİLİ VERSİYON (Kesin Sığar)
class GuaranteedLessonCard extends StatelessWidget {
  final int lessonId;
  final String lessonName;
  final String topicTitle;
  final int? weekNo;
  final double progress;
  final double successRate;
  final VoidCallback onTap;
  final bool isNextStep;

  const GuaranteedLessonCard({
    super.key,
    required this.lessonId,
    required this.lessonName,
    required this.topicTitle,
    this.weekNo,
    required this.progress,
    required this.successRate,
    required this.onTap,
    this.isNextStep = false,
  });

  @override
  Widget build(BuildContext context) {
    final details = _lessonDetails[lessonId] ?? {
      'color': Colors.grey,
      'gradient': [Colors.grey, Colors.grey.shade600]
    };

    final gradientColors = details['gradient'] as List<Color>;
    final icon = details['icon'] as IconData;

    return SizedBox(
      height: 150, // Sabit ve güvenli yükseklik
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık satırı
                Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isNextStep ? '$weekNo. Hafta' : lessonName,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            isNextStep ? lessonName : topicTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isNextStep)
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 14,
                      ),
                  ],
                ),

                // İlerleme
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'İlerleme',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${progress.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      color: Colors.white,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),

                // İstatistikler
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TinyStat(
                      icon: Icons.check,
                      value: '${progress.toInt()}%',
                      label: 'Çözülen',
                    ),
                    _TinyStat(
                      icon: Icons.trending_up,
                      value: '${successRate.toInt()}%',
                      label: 'Başarı',
                    ),
                    _TinyStat(
                      icon: Icons.star,
                      value: '${((progress * successRate) / 100).toInt()}',
                      label: 'Puan',
                      isScore: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isScore;

  const _TinyStat({
    required this.icon,
    required this.value,
    required this.label,
    this.isScore = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isScore ? Colors.amber : Colors.white,
              size: 12,
            ),
            const SizedBox(width: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
