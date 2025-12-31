// lib/models/unit_with_topics_model.dart

import 'package:egitim_uygulamasi/models/topic_model.dart';
import 'package:egitim_uygulamasi/models/unit_model.dart';

/// A data class to hold the nested structure for the curriculum's right panel.
class UnitWithTopics {
  final Unit unit;
  final List<Topic> topics;

  UnitWithTopics(this.unit, this.topics);
}
