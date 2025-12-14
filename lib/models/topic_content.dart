// lib/models/topic_content.dart

/// Represents a single piece of content related to a topic.
///
/// This model is immutable and includes `fromJson` and `toJson` methods
/// for seamless conversion between Dart objects and JSON, respecting
/// the snake_case to camelCase naming convention for Supabase.
class TopicContent {
  final int topicId;
  final String title;
  final String content;
  final int orderNo;
  final String sectionType;
  final int? displayWeek;

  const TopicContent({
    required this.topicId,
    required this.title,
    required this.content,
    required this.orderNo,
    required this.sectionType,
    this.displayWeek,
  });

  /// Creates a [TopicContent] instance from a JSON map.
  factory TopicContent.fromJson(Map<String, dynamic> json) {
    return TopicContent(
      topicId: json['topic_id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      orderNo: json['order_no'] as int,
      sectionType: json['section_type'] as String,
      displayWeek: json['display_week'] as int?,
    );
  }

  /// Converts the [TopicContent] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'topic_id': topicId,
      'title': title,
      'content': content,
      'order_no': orderNo,
      'section_type': sectionType,
      'display_week': displayWeek,
    };
  }
}
