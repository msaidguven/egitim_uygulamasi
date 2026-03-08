import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'common/lesson_step_card.dart';

class ReflectionPromptStep extends StatefulWidget {
  final Map<String, dynamic> step;
  final bool isActive;
  final VoidCallback onComplete;

  const ReflectionPromptStep({
    super.key,
    required this.step,
    required this.isActive,
    required this.onComplete,
  });

  @override
  State<ReflectionPromptStep> createState() => _ReflectionPromptStepState();
}

class _ReflectionPromptStepState extends State<ReflectionPromptStep> {
  final TextEditingController _controller = TextEditingController();
  bool _showExpected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guidance =
        (widget.step['guidance'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    final expectedPoints =
        (widget.step['expectedPoints'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final minChars = (widget.step['minChars'] as num?)?.toInt() ?? 0;

    return LessonStepCard(
      badge: widget.step['badge']?.toString() ?? 'Kritik Dusunme',
      title: widget.step['title']?.toString(),
      subtitle: widget.step['prompt']?.toString(),
      footer: widget.isActive
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  onPressed: () =>
                      setState(() => _showExpected = !_showExpected),
                  child: Text(
                    _showExpected
                        ? 'Ornek cevap ipuclarini gizle'
                        : 'Ornek cevap ipuclarini goster',
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _controller.text.trim().length >= minChars
                      ? widget.onComplete
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    widget.step['buttonText']?.toString() ??
                        'Yanitimi Kaydet ve Devam Et',
                  ),
                ),
              ],
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (guidance.isNotEmpty) ...[
            const Text(
              'Dusunurken bunlari kullan:',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final item in guidance)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            enabled: widget.isActive,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Kisa aciklamani buraya yaz...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_showExpected && expectedPoints.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Beklenen ana noktalar:',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3730A3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final point in expectedPoints)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(child: Text(point)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.08, end: 0);
  }
}
