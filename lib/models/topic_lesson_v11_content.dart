class TopicLessonV11Content {
  final int id;
  final int topicId;
  final int lessonId;
  final int versionNo;
  final String? title;
  final Map<String, dynamic> payload;
  final String source;
  final bool isPublished;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TopicLessonV11Content({
    required this.id,
    required this.topicId,
    required this.lessonId,
    required this.versionNo,
    required this.title,
    required this.payload,
    required this.source,
    required this.isPublished,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TopicLessonV11Content.fromMap(Map<String, dynamic> map) {
    return TopicLessonV11Content(
      id: map['id'] as int,
      topicId: map['topic_id'] as int,
      lessonId: map['lesson_id'] as int,
      versionNo: map['version_no'] as int? ?? 1,
      title: map['title'] as String?,
      payload: Map<String, dynamic>.from(
        map['payload'] as Map<String, dynamic>? ?? const {},
      ),
      source: map['source'] as String? ?? 'lesson_v11_ai',
      isPublished: map['is_published'] as bool? ?? false,
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'topic_id': topicId,
      'lesson_id': lessonId,
      'version_no': versionNo,
      'title': title,
      'payload': payload,
      'source': source,
      'is_published': isPublished,
      'created_by': createdBy,
    };
  }
}
