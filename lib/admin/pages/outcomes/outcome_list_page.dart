// lib/admin/pages/outcomes/outcome_list_page.dart

import 'package:egitim_uygulamasi/admin/pages/outcomes/outcome_form_dialog.dart';
import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/models/outcome_model.dart';
import 'package:egitim_uygulamasi/models/topic_model.dart';
import 'package:egitim_uygulamasi/models/unit_model.dart';
import 'package:egitim_uygulamasi/services/grade_service.dart';
import 'package:egitim_uygulamasi/services/outcome_service.dart';
import 'package:egitim_uygulamasi/services/topic_service.dart';
import 'package:egitim_uygulamasi/main.dart'; // Supabase client için
import 'package:flutter/material.dart';

class OutcomeListPage extends StatefulWidget {
  const OutcomeListPage({super.key});

  @override
  State<OutcomeListPage> createState() => _OutcomeListPageState();
}

class _OutcomeListPageState extends State<OutcomeListPage> {
  // Servisler
  final _gradeService = GradeService();
  final _topicService = TopicService();
  final _outcomeService = OutcomeService();

  // Seçim ID'leri
  int? _selectedGradeId;
  int? _selectedUnitId;
  int? _selectedTopicId;

  // Veri listeleri
  List<Unit> _units = [];
  List<Topic> _topics = [];
  List<Outcome> _outcomes = [];

  // Yüklenme durumları
  bool _isLoadingUnits = false;
  bool _isLoadingTopics = false;
  bool _isLoadingOutcomes = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kazanım Yönetimi'),
        actions: [
          if (_selectedTopicId != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: FilledButton.icon(
                onPressed: _showFormDialog,
                icon: const Icon(Icons.add),
                label: const Text('Yeni Kazanım'),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGradeSelector(),
            const SizedBox(height: 16),
            _buildUnitSelector(),
            const SizedBox(height: 16),
            _buildTopicSelector(),
            const SizedBox(height: 20),
            const Divider(),
            Expanded(child: _buildOutcomeList()),
          ],
        ),
      ),
    );
  }

  // Seçim Dropdown'ları
  Widget _buildGradeSelector() {
    return FutureBuilder<List<Grade>>(
      future: _gradeService.getGrades(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        return DropdownButtonFormField<int>(
          value: _selectedGradeId,
          hint: const Text('1. Sınıf Seçin'),
          onChanged: (value) {
            if (value != null) _onGradeSelected(value);
          },
          items: snapshot.data!
              .map(
                (grade) =>
                    DropdownMenuItem(value: grade.id, child: Text(grade.name)),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildUnitSelector() {
    return DropdownButtonFormField<int>(
      value: _selectedUnitId,
      hint: const Text('2. Ünite Seçin'),
      onChanged: _selectedGradeId == null
          ? null
          : (value) {
              if (value != null) _onUnitSelected(value);
            },
      items: _units
          .map(
            (unit) => DropdownMenuItem(value: unit.id, child: Text(unit.title)),
          )
          .toList(),
    );
  }

  Widget _buildTopicSelector() {
    return DropdownButtonFormField<int>(
      value: _selectedTopicId,
      hint: const Text('3. Konu Seçin'),
      onChanged: _selectedUnitId == null
          ? null
          : (value) {
              if (value != null) _onTopicSelected(value);
            },
      items: _topics
          .map(
            (topic) =>
                DropdownMenuItem(value: topic.id, child: Text(topic.name)),
          )
          .toList(),
    );
  }

  // Veri Yükleme ve Durum Yönetimi
  void _onGradeSelected(int gradeId) async {
    setState(() {
      _selectedGradeId = gradeId;
      _selectedUnitId = null;
      _selectedTopicId = null;
      _units = [];
      _topics = [];
      _outcomes = [];
      _isLoadingUnits = true;
    });
    try {
      final response = await supabase.rpc(
        'get_units_by_grade',
        params: {'gid': gradeId},
      );
      _units = (response as List)
          .map((data) => Unit.fromMap(data as Map<String, dynamic>))
          .toList();
    } finally {
      if (mounted) setState(() => _isLoadingUnits = false);
    }
  }

  void _onUnitSelected(int unitId) async {
    setState(() {
      _selectedUnitId = unitId;
      _selectedTopicId = null;
      _topics = [];
      _outcomes = [];
      _isLoadingTopics = true;
    });
    _topics = await _topicService.getTopicsForUnit(unitId);
    setState(() => _isLoadingTopics = false);
  }

  void _onTopicSelected(int topicId) async {
    setState(() {
      _selectedTopicId = topicId;
      _outcomes = [];
      _isLoadingOutcomes = true;
    });
    _outcomes = await _outcomeService.getOutcomesForTopic(topicId);
    setState(() => _isLoadingOutcomes = false);
  }

  // Kazanım Listesi ve İşlemleri
  Widget _buildOutcomeList() {
    if (_selectedTopicId == null) {
      return const Center(
        child: Text('Kazanımları listelemek için bir konu seçin.'),
      );
    }
    if (_isLoadingOutcomes)
      return const Center(child: CircularProgressIndicator());

    return ListView.builder(
      itemCount: _outcomes.length,
      itemBuilder: (context, index) {
        final outcome = _outcomes[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(outcome.text),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showFormDialog(outcome: outcome),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _deleteOutcome(outcome.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFormDialog({Outcome? outcome}) {
    showDialog(
      context: context,
      builder: (context) => OutcomeFormDialog(
        outcome: outcome,
        topicId: _selectedTopicId!,
        onSave: () => _onTopicSelected(_selectedTopicId!),
      ),
    );
  }

  Future<void> _deleteOutcome(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kazanımı Sil'),
        content: const Text('Bu kazanımı silmek istediğinizden emin misiniz?'),
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
      await _outcomeService.deleteOutcome(id);
      _onTopicSelected(_selectedTopicId!);
    }
  }
}
