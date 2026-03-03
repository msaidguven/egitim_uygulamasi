import 'package:egitim_uygulamasi/screens/home/map/models/map_progress_models.dart';
import 'package:flutter/material.dart';

class TimelineComponent extends StatelessWidget {
  const TimelineComponent({
    super.key,
    required this.scrollController,
    required this.nodes,
    required this.keys,
    required this.accent,
    required this.onTopicTap,
  });

  final ScrollController scrollController;
  final List<TopicNodeData> nodes;
  final List<GlobalKey> keys;
  final Color accent;
  final ValueChanged<TopicNodeData> onTopicTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          bottom: 0,
          left: MediaQuery.of(context).size.width / 2 - 1,
          child: Container(width: 2, color: const Color(0xFFE2E8F0)),
        ),
        ListView.builder(
          key: const PageStorageKey<String>('unit_timeline_scroll'),
          controller: scrollController,
          itemCount: nodes.length,
          padding: const EdgeInsets.only(top: 24, bottom: 120),
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final topic = nodes[index];
            final isLeft = topic.weekIndex.isOdd;
            final state = topic.state;
            final isDone = state == ConquestState.conquered;
            final isProgress = state == ConquestState.inProgress;
            final fillColor = isDone || isProgress ? accent : Colors.white;

            return InkWell(
              key: keys[index],
              onTap: () => onTopicTap(topic),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: isLeft
                            ? Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: _TopicText(topic: topic, alignRight: true),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: fillColor,
                        shape: isDone ? BoxShape.rectangle : BoxShape.circle,
                        borderRadius: isDone ? BorderRadius.circular(7) : null,
                        border: Border.all(
                          color: isDone || isProgress ? accent : const Color(0xFF94A3B8),
                          width: 2.8,
                        ),
                        boxShadow: isDone || isProgress
                            ? [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.28),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                            : isProgress
                                ? const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16)
                                : const SizedBox.shrink(),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: !isLeft
                            ? Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: _TopicText(topic: topic, alignRight: false),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TopicText extends StatelessWidget {
  const _TopicText({required this.topic, required this.alignRight});

  final TopicNodeData topic;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          topic.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Hafta ${topic.weekIndex}  ·  %${(topic.progressRate * 100).round()}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
