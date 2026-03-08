class LessonStepModel {
  final String id;
  final String type;
  final String title;
  final Map<String, dynamic> content;
  final Map<String, dynamic> interaction;
  final int xp;

  const LessonStepModel({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.interaction,
    required this.xp,
  });

  factory LessonStepModel.fromJson(Map<String, dynamic> json) {
    return LessonStepModel(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: Map<String, dynamic>.from(
        (json['content'] as Map<String, dynamic>?) ??
            (json['data'] as Map<String, dynamic>?) ??
            const <String, dynamic>{},
      ),
      interaction: Map<String, dynamic>.from(
        (json['interaction'] as Map<String, dynamic>?) ??
            (json['completion'] as Map<String, dynamic>?) ??
            const <String, dynamic>{},
      ),
      xp: (json['xp'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'content': content,
        'interaction': interaction,
        'xp': xp,
      };
}
