import 'package:flutter/material.dart';

class AddQuestionDialog extends StatefulWidget {
  const AddQuestionDialog({super.key});

  @override
  State<AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<AddQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  String _questionType = 'multiple_choice';
  final _questionTextController = TextEditingController();
  final _scoreController = TextEditingController(text: '10');
  final _difficultyController = TextEditingController(text: '5');

  // For matching questions
  List<MapEntry<String, String>> _matchingPairs = [];
  final _matchLeftTextController = TextEditingController();
  final _matchRightTextController = TextEditingController();
  
  // For multiple choice
  List<Map<String, dynamic>> _choices = [];
  final _choiceTextController = TextEditingController();
  bool _isCorrectChoice = false;

  @override
  void dispose() {
    _questionTextController.dispose();
    _scoreController.dispose();
    _difficultyController.dispose();
    _matchLeftTextController.dispose();
    _matchRightTextController.dispose();
    _choiceTextController.dispose();
    super.dispose();
  }

  void _addMatchingPair() {
    if (_matchLeftTextController.text.isNotEmpty &&
        _matchRightTextController.text.isNotEmpty) {
      setState(() {
        _matchingPairs.add(
            MapEntry(_matchLeftTextController.text, _matchRightTextController.text));
        _matchLeftTextController.clear();
        _matchRightTextController.clear();
      });
    }
  }
  
  void _addChoice() {
    if (_choiceTextController.text.isNotEmpty) {
      setState(() {
        _choices.add({
          'text': _choiceTextController.text,
          'is_correct': _isCorrectChoice,
        });
        _choiceTextController.clear();
        _isCorrectChoice = false;
      });
    }
  }


  void _saveQuestion() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final question = <String, dynamic>{
      'question_text': _questionTextController.text,
      'question_type': _questionType,
      'score': int.tryParse(_scoreController.text) ?? 10,
      'difficulty': int.tryParse(_difficultyController.text) ?? 5,
    };

    if (_questionType == 'matching') {
      if (_matchingPairs.isEmpty) {
        // Show an error or prevent saving.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Lütfen en az bir eşleştirme çifti ekleyin.'),
            backgroundColor: Colors.red));
        return;
      }
      question['pairs'] = _matchingPairs
          .map((p) => {'left_text': p.key, 'right_text': p.value})
          .toList();
    } else if (_questionType == 'multiple_choice') {
      if (_choices.length < 2) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Lütfen en az iki seçenek ekleyin.'),
            backgroundColor: Colors.red));
        return;
      }
       if (!_choices.any((c) => c['is_correct'] == true)) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Lütfen doğru cevabı işaretleyin.'),
            backgroundColor: Colors.red));
        return;
      }
      question['choices'] = _choices;
    }

    Navigator.of(context).pop(question);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Soru Ekle'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Common fields
              TextFormField(
                controller: _questionTextController,
                decoration: const InputDecoration(labelText: 'Soru Metni'),
                validator: (val) =>
                    val!.isEmpty ? 'Soru metni boş olamaz.' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _questionType,
                decoration: const InputDecoration(labelText: 'Soru Tipi', border: OutlineInputBorder()),
                items: ['multiple_choice', 'matching', 'blank', 'classical']
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _questionType = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _scoreController,
                      decoration: const InputDecoration(labelText: 'Puan', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _difficultyController,
                      decoration: const InputDecoration(labelText: 'Zorluk', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              if (_questionType == 'matching')
                _buildMatchingFields(),
              if (_questionType == 'multiple_choice')
                _buildMultipleChoiceFields(),

            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _saveQuestion,
          child: const Text('Kaydet'),
        )
      ],
    );
  }

  Widget _buildMatchingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Eşleştirme Seçenekleri', style: Theme.of(context).textTheme.titleMedium),
        const Divider(),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _matchingPairs.length,
          itemBuilder: (context, index) {
            final pair = _matchingPairs[index];
            return ListTile(
                  dense: true,
                  title: Text(pair.key),
                  subtitle: Text(pair.value),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() {
                        _matchingPairs.removeAt(index);
                      });
                    },
                  ),
                );
          },
        ),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: TextFormField(controller: _matchLeftTextController, decoration: const InputDecoration(labelText: 'Sol Metin'))),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(controller: _matchRightTextController, decoration: const InputDecoration(labelText: 'Sağ Metin'))),
             IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _addMatchingPair,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMultipleChoiceFields() {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Çoktan Seçmeli Seçenekler', style: Theme.of(context).textTheme.titleMedium),
        const Divider(),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _choices.length,
          itemBuilder: (context, index) {
            final choice = _choices[index];
            return ListTile(
                  dense: true,
                  title: Text(choice['text']),
                  leading: Icon(
                    choice['is_correct'] ? Icons.check_box : Icons.check_box_outline_blank,
                    color: choice['is_correct'] ? Colors.green : null,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() {
                        _choices.removeAt(index);
                      });
                    },
                  ),
                );
          },
        ),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: TextFormField(controller: _choiceTextController, decoration: const InputDecoration(labelText: 'Seçenek Metni'))),
            StatefulBuilder(
              builder: (context, setState) {
                return Checkbox(
                  value: _isCorrectChoice,
                  onChanged: (val) => setState(() => _isCorrectChoice = val!),
                );
              }
            ),
             IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _addChoice,
            ),
          ],
        ),
      ],
    );
  }
}
