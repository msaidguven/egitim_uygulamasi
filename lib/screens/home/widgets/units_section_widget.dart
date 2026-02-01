import 'package:flutter/material.dart';

class UnitsSectionWidget extends StatelessWidget {
  const UnitsSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Üniteler',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Text(
                        'Tümü',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFF6366F1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Unit Cards
        const UnitCard(
          title: 'Sayı Sistemi ve İşlemler',
          subtitle: '3. Hafta • 12 Konu • 45 Soru',
          status: UnitStatus.active,
          progress: 0.65,
        ),
        const UnitCard(
          title: 'Geometrik Şekiller',
          subtitle: '2. Hafta • Tamamlandı',
          status: UnitStatus.completed,
          progress: 1.0,
          successRate: 92,
        ),
        const UnitCard(
          title: 'Olasılık',
          subtitle: '4. Hafta • Kilitli',
          status: UnitStatus.locked,
          progress: 0.0,
        ),
      ],
    );
  }
}

enum UnitStatus { active, completed, locked }

class UnitCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final UnitStatus status;
  final double progress;
  final int? successRate;

  const UnitCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.progress,
    this.successRate,
  });

  @override
  Widget build(BuildContext context) {
    // Colors
    const Color primaryColor = Color(0xFF6366F1);
    const Color successColor = Color(0xFF22C55E);
    const Color lockedColor = Color(0xFF94A3B8);
    const Color surfaceColor = Colors.white;

    Color statusColor;
    String statusText;
    IconData? statusIcon;
    Color badgeBgColor;
    Color badgeTextColor;
    List<Color> gradientColors;

    switch (status) {
      case UnitStatus.active:
        statusColor = primaryColor;
        statusText = 'Devam Ediyor';
        statusIcon = Icons.play_circle_outline_rounded;
        badgeBgColor = primaryColor.withOpacity(0.1);
        badgeTextColor = primaryColor;
        gradientColors = [primaryColor, const Color(0xFF818CF8)];
        break;
      case UnitStatus.completed:
        statusColor = successColor;
        statusText = 'Bitti';
        statusIcon = Icons.check_circle_outline_rounded;
        badgeBgColor = successColor.withOpacity(0.1);
        badgeTextColor = successColor;
        gradientColors = [successColor, const Color(0xFF4ADE80)];
        break;
      case UnitStatus.locked:
        statusColor = lockedColor;
        statusText = 'Kilitli';
        statusIcon = Icons.lock_outline_rounded;
        badgeBgColor = Colors.grey.shade100;
        badgeTextColor = lockedColor;
        gradientColors = [lockedColor, Colors.grey];
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Left Colored Strip
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 6,
            child: Container(
              decoration: BoxDecoration(
                color: statusColor,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 14,
                            color: badgeTextColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: badgeTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Progress Section
                if (status != UnitStatus.locked) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        status == UnitStatus.completed ? 'Başarı Oranı' : 'İlerleme',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        status == UnitStatus.completed ? '$successRate%' : '%${(progress * 100).toInt()}',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                   // Locked State
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: Colors.grey.shade50,
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: Colors.grey.shade200),
                     ),
                     child: Row(
                       children: [
                         Icon(Icons.lock_clock_outlined, size: 16, color: Colors.grey.shade500),
                         const SizedBox(width: 8),
                         Text(
                           'Bu üniteyi açmak için öncekini tamamla',
                           style: TextStyle(
                             fontFamily: 'Plus Jakarta Sans',
                             fontSize: 12,
                             color: Colors.grey.shade500,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                       ],
                     ),
                   ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
