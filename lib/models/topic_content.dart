import 'package:egitim_uygulamasi/models/question_model.dart';

class TopicContent {
  final int? id;
  final int? topicId;
  final String title;
  final String content;
  final int order;
  final List<Question> miniQuizQuestions; // YENİ ALAN

  TopicContent({
    this.id,
    this.topicId,
    required this.title,
    required this.content,
    required this.order,
    this.miniQuizQuestions = const [], // YENİ ALAN
  });

  factory TopicContent.fromJson(Map<String, dynamic> json) {
    // Gelen mini quiz sorularını güvenli bir şekilde parse et
    final questionsData = json['mini_quiz_questions'] as List<dynamic>?;
    final questions = questionsData != null
        ? questionsData.map((q) => Question.fromMap(q as Map<String, dynamic>)).toList()
        : <Question>[];

    return TopicContent(
      id: json['id'] as int?,
      topicId: json['topic_id'] as int?,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      order: json['order_no'] as int? ?? 0,
      miniQuizQuestions: questions, // YENİ ALAN
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (topicId != null) 'topic_id': topicId,
      'title': title,
      'content': content,
      'order_no': order,
      // toJson'a eklemek şimdilik gerekli değil, çünkü bu veriyi geri göndermiyoruz.
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
