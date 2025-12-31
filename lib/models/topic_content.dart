import 'package:flutter/foundation.dart';

class TopicContent {
  final int? id;
  final int? topicId;
  final String title;
  final String content;
  final int order;

  TopicContent({
    this.id,
    this.topicId,
    required this.title,
    required this.content,
    required this.order,
  });

  factory TopicContent.fromJson(Map<String, dynamic> json) {
    return TopicContent(
      id: json['id'] as int?,
      topicId: json['topic_id'] as int?,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      order: json['order_no'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (topicId != null) 'topic_id': topicId,
      'title': title,
      'content': content,
      'order_no': order,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is TopicContent &&
      other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
