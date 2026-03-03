import 'package:flutter/material.dart';

enum ConquestState { notStarted, inProgress, conquered, locked }

extension ConquestStateX on ConquestState {
  String get label {
    switch (this) {
      case ConquestState.notStarted:
        return 'Başlanmadı';
      case ConquestState.inProgress:
        return 'Devam Ediyor';
      case ConquestState.conquered:
        return 'Fethedildi';
      case ConquestState.locked:
        return 'Kilitli';
    }
  }

  Color borderColor(Color accent) {
    switch (this) {
      case ConquestState.notStarted:
        return const Color(0xFFCBD5E1);
      case ConquestState.inProgress:
        return accent;
      case ConquestState.conquered:
        return const Color(0xFFD4AF37);
      case ConquestState.locked:
        return const Color(0xFF94A3B8);
    }
  }
}

class ClassMapData {
  final int gradeId;
  final String gradeName;
  final List<SubjectNodeData> subjects;

  const ClassMapData({
    required this.gradeId,
    required this.gradeName,
    required this.subjects,
  });

  int get conqueredCount =>
      subjects.where((s) => s.state == ConquestState.conquered).length;

  double get completionRate {
    if (subjects.isEmpty) return 0;
    final sum = subjects.fold<double>(0, (acc, s) => acc + s.progressRate);
    return (sum / subjects.length).clamp(0, 1);
  }
}

class SubjectNodeData {
  final int lessonId;
  final String lessonName;
  final int unitsTotal;
  final int unitsConquered;
  final int totalQuestions;
  final int solvedQuestions;
  final double progressRate;
  final ConquestState state;

  const SubjectNodeData({
    required this.lessonId,
    required this.lessonName,
    required this.unitsTotal,
    required this.unitsConquered,
    required this.totalQuestions,
    required this.solvedQuestions,
    required this.progressRate,
    required this.state,
  });
}

class SubjectMapData {
  final int lessonId;
  final String lessonName;
  final int gradeId;
  final List<UnitNodeData> units;

  const SubjectMapData({
    required this.lessonId,
    required this.lessonName,
    required this.gradeId,
    required this.units,
  });

  int get conqueredCount =>
      units.where((u) => u.state == ConquestState.conquered).length;

  double get completionRate {
    if (units.isEmpty) return 0;
    return conqueredCount / units.length;
  }
}

class UnitNodeData {
  final int unitId;
  final String title;
  final int orderNo;
  final int startWeek;
  final int endWeek;
  final int totalQuestions;
  final int solvedQuestions;
  final int topicsTotal;
  final int topicsCompleted;
  final bool isCurrentWeek;
  final ConquestState state;

  const UnitNodeData({
    required this.unitId,
    required this.title,
    required this.orderNo,
    required this.startWeek,
    required this.endWeek,
    required this.totalQuestions,
    required this.solvedQuestions,
    required this.topicsTotal,
    required this.topicsCompleted,
    required this.isCurrentWeek,
    required this.state,
  });

  double get progressRate {
    if (topicsTotal > 0) {
      return (topicsCompleted / topicsTotal).clamp(0, 1);
    }
    if (totalQuestions <= 0) return 0;
    return (solvedQuestions / totalQuestions).clamp(0, 1);
  }

  UnitNodeData copyWith({
    int? topicsCompleted,
    int? solvedQuestions,
    ConquestState? state,
  }) {
    return UnitNodeData(
      unitId: unitId,
      title: title,
      orderNo: orderNo,
      startWeek: startWeek,
      endWeek: endWeek,
      totalQuestions: totalQuestions,
      solvedQuestions: solvedQuestions ?? this.solvedQuestions,
      topicsTotal: topicsTotal,
      topicsCompleted: topicsCompleted ?? this.topicsCompleted,
      isCurrentWeek: isCurrentWeek,
      state: state ?? this.state,
    );
  }
}

class TopicNodeData {
  final int topicId;
  final int unitId;
  final String title;
  final int weekIndex;
  final int gainOrder;
  final int totalQuestions;
  final int solvedQuestions;
  final bool isCompleted;
  final bool isInProgress;

  const TopicNodeData({
    required this.topicId,
    required this.unitId,
    required this.title,
    required this.weekIndex,
    required this.gainOrder,
    required this.totalQuestions,
    required this.solvedQuestions,
    required this.isCompleted,
    required this.isInProgress,
  });

  ConquestState get state {
    if (isCompleted) return ConquestState.conquered;
    if (isInProgress) return ConquestState.inProgress;
    return ConquestState.notStarted;
  }

  double get progressRate {
    if (totalQuestions <= 0) return 0;
    return (solvedQuestions / totalQuestions).clamp(0, 1);
  }
}
