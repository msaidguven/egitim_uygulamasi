import 'package:flutter/material.dart';

class WeekScrollWidget extends StatelessWidget {
  final int currentWeek;
  final Function(int) onWeekSelected;

  const WeekScrollWidget({
    super.key,
    required this.currentWeek,
    required this.onWeekSelected,
  });

  @override
  Widget build(BuildContext context) {
    // CSS variables mapping
    const Color primaryColor = Color(0xFF6366F1);
    const Color surfaceColor = Colors.white;
    const Color textPrimaryColor = Color(0xFF1E293B);
    const Color textSecondaryColor = Color(0xFF64748B);
    
    // Sample data based on the HTML snippet
    // In a real app, this would probably be generated dynamically
    final List<Map<String, dynamic>> weeks = [
      {'number': 2, 'label': 'Geçen', 'status': 'past'},
      {'number': 33, 'label': 'Şimdi', 'status': 'active'},
      {'number': 4, 'label': 'Gelecek', 'status': 'future'},
      {'number': 5, 'label': 'Gelecek', 'status': 'future'},
      {'number': 6, 'label': 'Kilitli', 'status': 'locked'},
    ];

    return Container(
      height: 100, // Adjust height as needed
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: weeks.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final week = weeks[index];
          final int weekNumber = week['number'];
          final String label = week['label'];
          final String status = week['status'];
          
          final bool isActive = status == 'active'; // Or weekNumber == currentWeek
          final bool isLocked = status == 'locked';

          return GestureDetector(
            onTap: isLocked ? null : () => onWeekSelected(weekNumber),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 75,
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 7),
              decoration: BoxDecoration(
                color: isActive ? primaryColor : surfaceColor,
                gradient: isActive 
                    ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: isActive ? Colors.transparent : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                          spreadRadius: -2,
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$weekNumber',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isActive ? Colors.white : textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: isActive 
                          ? Colors.white.withOpacity(0.9) 
                          : textSecondaryColor.withOpacity(0.8),
                    ),
                  ),
                  if (isLocked) ...[
                     // Optional: Add lock icon if needed, though not in HTML text content
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
