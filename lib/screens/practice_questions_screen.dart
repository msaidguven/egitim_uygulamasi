import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:egitim_uygulamasi/models/question_model.dart';

class PracticeQuestionsScreen extends StatefulWidget {
  final int topicId;
  final String topicTitle;

  const PracticeQuestionsScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
  });

  @override
  State<PracticeQuestionsScreen> createState() => _PracticeQuestionsScreenState();
}

class _PracticeQuestionsScreenState extends State<PracticeQuestionsScreen> {
  late Future<List<Map<String, dynamic>>> _futureQuestions;
  int? _selectedDifficulty; // NULL: Hepsi, 1: Kolay, 2: Orta, 3: Zor

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() {
    _futureQuestions = Supabase.instance.client.rpc(
      'get_practice_questions',
      params: {
        'p_topic_id': widget.topicId,
        'p_difficulty': _selectedDifficulty,
        'p_limit': 50,
        'p_offset': 0,
      },
    ).then((data) => List<Map<String, dynamic>>.from(data));
  }

  void _onFilterChanged(int? newValue) {
    setState(() {
      _selectedDifficulty = newValue;
      _loadQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicTitle),
        bottom: _buildFilterBar(),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureQuestions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text("Bu zorluk seviyesinde soru bulunamadı."));
          }

          final questions = data.map((json) => Question.fromMap(json)).toList();

          return _PracticeListView(questions: questions);
        },
      ),
    );
  }

  PreferredSizeWidget _buildFilterBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _filterChip("Hepsi", null),
            _filterChip("Kolay", 1),
            _filterChip("Orta", 2),
            _filterChip("Zor", 3),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, int? value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: _selectedDifficulty == value,
        onSelected: (selected) {
          if (selected) _onFilterChanged(value);
        },
      ),
    );
  }
}

class _PracticeListView extends StatefulWidget {
  final List<Question> questions;
  const _PracticeListView({required this.questions});

  @override
  State<_PracticeListView> createState() => _PracticeListViewState();
}

class _PracticeListViewState extends State<_PracticeListView> {
  final Map<int, int?> _userAnswers = {}; // questionId -> selectedOptionId

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.questions.length,
      itemBuilder: (context, index) {
        final question = widget.questions[index];
        return _PracticeQuestionCard(
          question: question,
          selectedOptionId: _userAnswers[question.id],
          onOptionSelected: (optionId) {
            setState(() {
              _userAnswers[question.id] = optionId;
            });
          },
        );
      },
    );
  }
}

class _PracticeQuestionCard extends StatelessWidget {
  final Question question;
  final int? selectedOptionId;
  final ValueChanged<int> onOptionSelected;

  const _PracticeQuestionCard({
    required this.question,
    required this.selectedOptionId,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDifficultyBadge(question.difficulty),
                if (selectedOptionId != null)
                  Icon(
                    _isCorrect ? Icons.check_circle : Icons.cancel,
                    color: _isCorrect ? Colors.green : Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question.text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...question.choices.map((choice) => _buildOption(choice)),
          ],
        ),
      ),
    );
  }

  bool get _isCorrect {
    if (selectedOptionId == null) return false;
    return question.choices.firstWhere((c) => c.id == selectedOptionId).isCorrect;
  }

  Widget _buildOption(QuestionChoice choice) {
    bool isSelected = selectedOptionId == choice.id;
    bool showResult = selectedOptionId != null;
    
    Color borderColor = Colors.grey.shade300;
    Color bgColor = Colors.transparent;

    if (showResult) {
      if (choice.isCorrect) {
        borderColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.1);
      } else if (isSelected) {
        borderColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
      }
    } else if (isSelected) {
      borderColor = Colors.blue;
    }

    return GestureDetector(
      onTap: showResult ? null : () => onOptionSelected(choice.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(10),
          color: bgColor,
        ),
        child: Text(choice.text),
      ),
    );
  }

  Widget _buildDifficultyBadge(int difficulty) {
    String label;
    Color color;
    switch (difficulty) {
      case 1: label = "Kolay"; color = Colors.green; break;
      case 2: label = "Orta"; color = Colors.orange; break;
      case 3: label = "Zor"; color = Colors.red; break;
      default: label = "Bilinmiyor"; color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
