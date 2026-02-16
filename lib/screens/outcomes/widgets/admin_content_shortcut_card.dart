import 'package:flutter/material.dart';

class AdminContentShortcutCard extends StatelessWidget {
  final int curriculumWeek;
  final VoidCallback? onTapAdd;
  final VoidCallback? onTapUpdate;

  const AdminContentShortcutCard({
    super.key,
    required this.curriculumWeek,
    this.onTapAdd,
    this.onTapUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isAddEnabled = onTapAdd != null;
    final isUpdateEnabled = onTapUpdate != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F7F3), Color(0xFFF1FBF8)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFE9DE)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF16A085).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.note_add_rounded,
              color: Color(0xFF16A085),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Hızlı İşlem',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$curriculumWeek. hafta içerik işlemleri',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F6B59),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: onTapAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A085),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(isAddEnabled ? 'Ekle' : 'Seçim'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onTapUpdate,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF16A085),
                  disabledForegroundColor: Colors.grey.shade600,
                  side: BorderSide(
                    color: isUpdateEnabled
                        ? const Color(0xFF16A085)
                        : Colors.grey.shade400,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Güncelle'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
