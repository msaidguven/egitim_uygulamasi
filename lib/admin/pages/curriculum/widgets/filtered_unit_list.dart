import 'package:egitim_uygulamasi/admin/pages/units/unit_form_dialog.dart';
import 'package:egitim_uygulamasi/models/unit_model.dart';
import 'package:egitim_uygulamasi/services/unit_service.dart';
import 'package:egitim_uygulamasi/main.dart'; // Supabase client'a erişim için
import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/models/topic_model.dart'; // Import Topic model
import 'package:egitim_uygulamasi/services/topic_service.dart'; // Import TopicService

class FilteredUnitList extends StatefulWidget {
  final String gradeId;
  final String lessonId;

  const FilteredUnitList({
    super.key,
    required this.gradeId,
    required this.lessonId,
  });

  @override
  State<FilteredUnitList> createState() => _FilteredUnitListState();
}

class _FilteredUnitListState extends State<FilteredUnitList> {
  final UnitService _unitService = UnitService();
  TopicService? _topicService; // Make it nullable

  List<Unit> _units = [];
  bool _isUnitsLoading = false;
  String? _unitsError;

  Map<int, List<Topic>> _unitTopics = {}; // To store fetched topics per unit
  Map<int, bool> _unitExpandedState = {}; // To manage expansion state

  @override
  void initState() {
    super.initState();
    _topicService = TopicService(); // Initialize here
    _loadUnitsForLesson();
  }

  @override
  void didUpdateWidget(covariant FilteredUnitList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gradeId != oldWidget.gradeId || widget.lessonId != oldWidget.lessonId) {
      _loadUnitsForLesson();
    }
  }

  Future<void> _loadUnitsForLesson() async {
    setState(() {
      _isUnitsLoading = true;
      _unitsError = null;
      _units = [];
      _unitTopics = {}; // Clear topics when units are reloaded
      _unitExpandedState = {}; // Clear expanded state
    });

    final int? gradeIdInt = int.tryParse(widget.gradeId);
    final int? lessonIdInt = int.tryParse(widget.lessonId);

    if (gradeIdInt == null || lessonIdInt == null) {
      setState(() {
        _unitsError = "Geçersiz sınıf veya ders kimliği.";
        _isUnitsLoading = false;
      });
      return;
    }

    try {
      final response = await supabase.rpc(
        'get_units_by_lesson_and_grade',
        params: {'lid': lessonIdInt, 'gid': gradeIdInt},
      );

      final units = (response as List)
          .map((data) => Unit.fromMap(data as Map<String, dynamic>))
          .toList();

      setState(() {
        _isUnitsLoading = false;
        _units = units;
      });
    } catch (e) {
      setState(() {
        _unitsError = "Üniteler yüklenemedi: $e";
        _isUnitsLoading = false;
      });
    }
  }

  Future<void> _loadTopicsForUnit(int unitId) async {
    // Add null check before using _topicService
    if (_topicService == null) {
      debugPrint('TopicService is null');
      // Optionally, you could set an error state here as well
      return;
    }

    if (_unitTopics.containsKey(unitId) && _unitTopics[unitId]!.isNotEmpty) {
      return; // Topics already loaded for this unit
    }
    try {
      final topics = await _topicService!.getTopicsForUnit(unitId); // Use bang operator as we've checked for null
      setState(() {
        _unitTopics[unitId] = topics;
      });
    } catch (e) {
      debugPrint('Failed to load topics for unit $unitId: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Konular yüklenemedi: $e')),
        );
      }
    }
  }

  void _refreshUnitList() {
    _loadUnitsForLesson();
  }

  void _showFormDialog({Unit? unit}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UnitFormPage(unit: unit, onSave: _refreshUnitList),
      ),
    );
  }

  Future<void> _deleteUnit(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Üniteyi Sil'),
        content: const Text('Bu üniteyi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _unitService.deleteUnit(id);
        _refreshUnitList();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isUnitsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_unitsError != null) {
      return Center(child: Text(_unitsError!));
    }
    if (_units.isEmpty) {
      return const Center(child: Text('Bu derse ait ünite bulunamadı.'));
    }

    return ListView.builder(
      itemCount: _units.length,
      itemBuilder: (context, index) {
        final unit = _units[index];
        final isExpanded = _unitExpandedState[unit.id] ?? false;
        final topics = _unitTopics[unit.id] ?? [];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: ExpansionTile(
            key: PageStorageKey(unit.id), // Preserve expansion state across widget rebuilds
            initiallyExpanded: isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _unitExpandedState[unit.id] = expanded;
              });
              if (expanded && topics.isEmpty) {
                _loadTopicsForUnit(unit.id);
              }
            },
            title: Text('Ünite: ${unit.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(unit.description ?? 'Açıklama yok'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showFormDialog(unit: unit),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteUnit(unit.id),
                ),
              ],
            ),
            children: [
              if (topics.isEmpty && isExpanded)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Konu bulunamadı veya yükleniyor...'),
                ),
              ...topics.map((topic) => ListTile(
                title: Text(topic.title),
                subtitle: Text('Sıra No: ${topic.orderNo}'),
                // Add actions for topic if needed (e.g., edit/delete topic)
              )),
            ],
          ),
        );
      },
    );
  }
}
