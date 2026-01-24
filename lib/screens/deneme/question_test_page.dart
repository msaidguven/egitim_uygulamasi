import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionTestPage extends StatefulWidget {
  const QuestionTestPage({super.key});

  @override
  State<QuestionTestPage> createState() => _QuestionTestPageState();
}

class _QuestionTestPageState extends State<QuestionTestPage> {
  final _controller = TextEditingController();
  String? questionText;
  bool loading = false;
  String? error;

  final supabase = Supabase.instance.client;

  Future<void> fetchQuestion() async {
    setState(() {
      loading = true;
      error = null;
      questionText = null;
    });

    try {
      final id = int.parse(_controller.text);

      final res = await supabase
          .from('questions')
          .select('question_text')
          .eq('id', id)
          .single();

      setState(() {
        questionText = res['question_text'];
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  /// -------- FRACTION WIDGET --------
  Widget fraction(int n, int d, {double size = 20}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(n.toString(), style: TextStyle(fontSize: size * 0.7)),
        Container(width: size * 0.8, height: 2, color: Colors.black),
        Text(d.toString(), style: TextStyle(fontSize: size * 0.7)),
      ],
    );
  }

  /// -------- QUESTION PARSER --------
  RichText parseQuestion(String text, {double fontSize = 18}) {
    final regex = RegExp(r'\d+\/\d+');
    final matches = regex.allMatches(text);

    int lastIndex = 0;
    List<InlineSpan> spans = [];

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }

      final parts = match.group(0)!.split('/');
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: fraction(
            int.parse(parts[0]),
            int.parse(parts[1]),
            size: fontSize,
          ),
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: fontSize, color: Colors.black),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Question Test Page')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Question ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loading ? null : fetchQuestion,
              child: const Text('DB’den Getir'),
            ),
            const SizedBox(height: 24),

            if (loading) const CircularProgressIndicator(),

            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),

            if (questionText != null) ...[
              const Text(
                'SORU:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              parseQuestion(questionText!),
            ],
          ],
        ),
      ),
    );
  }
}
