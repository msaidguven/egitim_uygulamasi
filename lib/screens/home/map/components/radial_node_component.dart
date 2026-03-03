import 'package:egitim_uygulamasi/screens/home/map/models/map_progress_models.dart';
import 'package:flutter/material.dart';

class RadialNodeComponent extends StatelessWidget {
  const RadialNodeComponent({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.state,
    required this.accent,
    required this.onTap,
    this.isCurrent = false,
    this.size = 82,
  });

  final String title;
  final String subtitle;
  final double progress;
  final ConquestState state;
  final Color accent;
  final VoidCallback onTap;
  final bool isCurrent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final borderColor = state.borderColor(accent);
    final isConquered = state == ConquestState.conquered;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: size,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: isConquered ? 2.4 : 2),
                  boxShadow: [
                    BoxShadow(
                      color: isConquered
                          ? const Color(0xFFD4AF37).withValues(alpha: 0.22)
                          : accent.withValues(alpha: 0.14),
                      blurRadius: isCurrent ? 16 : 10,
                      spreadRadius: isCurrent ? 1 : 0,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: size - 26,
                        child: LinearProgressIndicator(
                          value: progress.clamp(0, 1),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(8),
                          backgroundColor: const Color(0xFFE2E8F0),
                          color: isConquered ? const Color(0xFFD4AF37) : accent,
                        ),
                      ),
                    ),
                    if (isConquered)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Icon(Icons.outlined_flag_rounded, size: size * 0.16, color: const Color(0xFFD4AF37)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  height: 1.1,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 9,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
