import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'common/lesson_step_card.dart';

class CategoryMatcher extends StatefulWidget {
  final Map<String, dynamic> step;
  final bool isActive;
  final VoidCallback onComplete;

  const CategoryMatcher({
    super.key,
    required this.step,
    required this.isActive,
    required this.onComplete,
  });

  @override
  State<CategoryMatcher> createState() => _CategoryMatcherState();
}

class _CategoryMatcherState extends State<CategoryMatcher> {
  final Map<String, List<String>> userCategories = {};
  final List<String> itemsLeft = [];

  List<Map<String, dynamic>> get _categories =>
      (widget.step['categories'] as List?)
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList() ??
      const <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    itemsLeft.addAll(
      (widget.step['allItems'] as List?)?.map((e) => e.toString()) ??
          const <String>[],
    );
    for (final cat in _categories) {
      final name = cat['name']?.toString();
      if (name != null) {
        userCategories[name] = <String>[];
      }
    }
  }

  void _checkAndComplete() {
    var allCorrect = true;
    for (final cat in _categories) {
      final name = cat['name']?.toString();
      if (name == null) continue;
      final correct =
          (cat['items'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[];
      final user = userCategories[name] ?? const <String>[];

      if (user.length != correct.length) {
        allCorrect = false;
        break;
      }
      for (final item in correct) {
        if (!user.contains(item)) {
          allCorrect = false;
          break;
        }
      }
    }
    if (allCorrect) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LessonStepCard(
      badge: widget.step['badge']?.toString() ?? 'Siniflandirma',
      title: widget.step['title']?.toString(),
      subtitle: widget.step['instruction']?.toString(),
      helperText: widget.step['helper']?.toString(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DragTarget<String>(
            onAcceptWithDetails: (details) {
              final data = details.data;
              setState(() {
                for (final cat in userCategories.values) {
                  cat.remove(data);
                }
                if (!itemsLeft.contains(data)) {
                  itemsLeft.insert(0, data);
                }
              });
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: candidateData.isNotEmpty
                      ? Colors.amber.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: candidateData.isNotEmpty
                        ? Colors.amber
                        : Colors.transparent,
                  ),
                ),
                child: Column(
                  children: [
                    if (itemsLeft.isNotEmpty) ...[
                      const Text(
                        'Siradaki oge:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _DraggableItem(
                        item: itemsLeft.first,
                        isActive: widget.isActive,
                      ),
                    ] else if (widget.isActive)
                      const Text(
                        'Hatali ogeyi buraya geri surukleyebilirsin.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: _categories.map((cat) {
              final name = cat['name']?.toString() ?? '';
              return Expanded(
                child: DragTarget<String>(
                  onAcceptWithDetails: (details) {
                    final data = details.data;
                    setState(() {
                      for (final otherCat in userCategories.values) {
                        otherCat.remove(data);
                      }
                      itemsLeft.remove(data);
                      if (!userCategories[name]!.contains(data)) {
                        userCategories[name]!.add(data);
                      }
                      _checkAndComplete();
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: candidateData.isNotEmpty
                            ? Colors.blue.withValues(alpha: 0.1)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.indigo.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          if (userCategories[name]!.isEmpty)
                            const Icon(
                              Icons.download_rounded,
                              color: Colors.grey,
                              size: 30,
                            )
                          else
                            ...userCategories[name]!.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: _DraggableItem(
                                  item: item,
                                  isActive: widget.isActive,
                                  isChip: true,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
  }
}

class _DraggableItem extends StatelessWidget {
  final String item;
  final bool isActive;
  final bool isChip;

  const _DraggableItem({
    required this.item,
    required this.isActive,
    this.isChip = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      return isChip
          ? Chip(label: Text(item, style: const TextStyle(fontSize: 11)))
          : _buildStaticItem();
    }

    return Draggable<String>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: _buildItemUI(isDragging: true),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildItemUI(isDimmed: true),
      ),
      child: _buildItemUI(),
    );
  }

  Widget _buildStaticItem() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        item,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildItemUI({bool isDragging = false, bool isDimmed = false}) {
    if (isChip && !isDragging) {
      return Chip(
        label: Text(item, style: const TextStyle(fontSize: 11)),
        backgroundColor: isDimmed ? Colors.grey[200] : Colors.white,
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isChip ? 12 : 20,
        vertical: isChip ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          if (!isDimmed)
            BoxShadow(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
              blurRadius: isDragging ? 12 : 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isChip ? Icons.drag_indicator : Icons.touch_app,
            color: Colors.white,
            size: isChip ? 14 : 18,
          ),
          const SizedBox(width: 8),
          Text(
            item,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: isChip ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
