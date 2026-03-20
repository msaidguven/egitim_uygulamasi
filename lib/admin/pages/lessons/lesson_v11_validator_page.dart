import 'package:egitim_uygulamasi/services/lesson_v11_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LessonV11ValidatorPage extends StatefulWidget {
  const LessonV11ValidatorPage({super.key});

  @override
  State<LessonV11ValidatorPage> createState() => _LessonV11ValidatorPageState();
}

class _LessonV11ValidatorPageState extends State<LessonV11ValidatorPage> {
  static const _sampleAssetPath =
      'lib/screens/lesson_content/lesson_v11/lesson_module.json';

  final _inputController = TextEditingController();
  final _validator = LessonV11Validator();
  LessonV11ValidationResult? _result;
  bool _isLoadingSample = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadSample() async {
    setState(() => _isLoadingSample = true);
    try {
      final raw = await rootBundle.loadString(_sampleAssetPath);
      if (!mounted) return;
      setState(() {
        _inputController.text = raw;
      });
      _validate();
    } finally {
      if (mounted) {
        setState(() => _isLoadingSample = false);
      }
    }
  }

  void _validate() {
    final raw = _inputController.text.trim();
    if (raw.isEmpty) {
      setState(() => _result = null);
      return;
    }
    setState(() {
      _result = _validator.validateRaw(raw);
    });
  }

  void _prettyPrint() {
    final result = _result ?? _validator.validateRaw(_inputController.text);
    if (result.parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pretty Print icin once parse edilebilir bir JSON gerekli. Gerekirse Auto Fix deneyin.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _inputController.text = result.normalizedJson;
      _result = result;
    });
  }

  void _autoFix() {
    final raw = _inputController.text.trim();
    if (raw.isEmpty) {
      setState(() => _result = null);
      return;
    }
    final result = _validator.autoFixRaw(raw);
    setState(() {
      _inputController.text = result.normalizedJson;
      _result = result;
    });
    final message = result.autoFixes.isEmpty
        ? 'Auto Fix calisti ama uygulanabilir bir duzeltme bulunamadi.'
        : 'Auto Fix ${result.autoFixes.length} duzeltme uyguladi.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _copy(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson V11 Validator'),
        actions: [
          TextButton.icon(
            onPressed: _isLoadingSample ? null : _loadSample,
            icon: const Icon(Icons.file_open_outlined),
            label: const Text('Örnek JSON'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI çıktısını buraya yapıştır. Validator parse eder, şema hatalarını bulur ve düzeltme promptu üretir.',
                    style: TextStyle(color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                        hintText:
                            'AI tarafindan uretilen lesson_v11 JSON\'unu buraya yapistir...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignLabelWithHint: true,
                      ),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: _validate,
                        icon: const Icon(Icons.rule_folder_outlined),
                        label: const Text('Kontrol Et'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _autoFix,
                        icon: const Icon(Icons.auto_fix_high_outlined),
                        label: const Text('Auto Fix'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _prettyPrint,
                        icon: const Icon(Icons.data_object_outlined),
                        label: const Text('Pretty Print'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _inputController.clear();
                            _result = null;
                          });
                        },
                        icon: const Icon(Icons.clear_all_outlined),
                        label: const Text('Temizle'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                padding: const EdgeInsets.all(16),
                child: result == null
                    ? const Center(
                        child: Text(
                          'Henüz doğrulama yapılmadı.',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      )
                    : _ResultPanel(
                        result: result,
                        onCopyFixPrompt: () => _copy(
                          result.fixPrompt,
                          'Duzeltme promptu kopyalandi.',
                        ),
                        onCopyNormalizedJson: result.parsed == null
                            ? null
                            : () => _copy(
                                result.normalizedJson,
                                'Duzenlenmis JSON kopyalandi.',
                              ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final LessonV11ValidationResult result;
  final VoidCallback onCopyFixPrompt;
  final VoidCallback? onCopyNormalizedJson;

  const _ResultPanel({
    required this.result,
    required this.onCopyFixPrompt,
    required this.onCopyNormalizedJson,
  });

  @override
  Widget build(BuildContext context) {
    final isValid = result.isValid;
    final statusColor = isValid
        ? const Color(0xFF166534)
        : const Color(0xFF991B1B);
    final statusBg = isValid
        ? const Color(0xFFECFDF5)
        : const Color(0xFFFEF2F2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Icon(
                isValid ? Icons.check_circle_outline : Icons.error_outline,
                color: statusColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isValid
                      ? 'JSON, Lesson V11 semasina gore gecerli gorunuyor.'
                      : 'JSON gecersiz. Asagidaki sorunlar duzeltilmeli.',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (result.parseError != null) ...[
          const SizedBox(height: 14),
          Text('Parse Hatası', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(
            result.parseError!,
            style: const TextStyle(color: Color(0xFF991B1B)),
          ),
        ],
        if (result.issues.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Hata Listesi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '${result.issues.length} hata',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: result.issues.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final issue = result.issues[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.path,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(issue.message),
                    ],
                  ),
                );
              },
            ),
          ),
        ] else ...[
          const Spacer(),
        ],
        if (result.autoFixes.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Uygulanan Auto Fixler',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in result.autoFixes) ...[
                  Text(item),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            FilledButton.icon(
              onPressed: onCopyFixPrompt,
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Düzeltme Promptu'),
            ),
            const SizedBox(width: 10),
            if (onCopyNormalizedJson != null)
              OutlinedButton.icon(
                onPressed: onCopyNormalizedJson,
                icon: const Icon(Icons.content_copy_outlined),
                label: const Text('Düzenli JSON'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'AI\'a geri gondermek icin hazir prompt',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 220),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              result.fixPrompt,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
