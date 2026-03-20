import 'dart:convert';

class LessonV11ValidationIssue {
  final String path;
  final String message;

  const LessonV11ValidationIssue({required this.path, required this.message});
}

class LessonV11ValidationResult {
  final bool isValid;
  final String normalizedJson;
  final Map<String, dynamic>? parsed;
  final List<LessonV11ValidationIssue> issues;
  final String fixPrompt;
  final String? parseError;
  final List<String> autoFixes;

  const LessonV11ValidationResult({
    required this.isValid,
    required this.normalizedJson,
    required this.parsed,
    required this.issues,
    required this.fixPrompt,
    required this.parseError,
    this.autoFixes = const [],
  });
}

class LessonV11Validator {
  static const _contentTypes = {'markdown', 'misconception', 'image'};
  static const _questionTypes = {
    'single_choice',
    'multiple_choice',
    'true_false',
    'matching',
    'ordering',
    'fill_blank',
  };

  LessonV11ValidationResult validateRaw(String rawInput) {
    final normalized = _normalizeRaw(rawInput);
    final issues = <LessonV11ValidationIssue>[];

    dynamic decoded;
    try {
      decoded = jsonDecode(normalized);
    } on FormatException catch (e) {
      return LessonV11ValidationResult(
        isValid: false,
        normalizedJson: normalized,
        parsed: null,
        issues: const [],
        fixPrompt: _buildFixPrompt(
          rawJson: normalized,
          issues: const ['JSON parse edilemiyor. Sozdizimi hatalarini duzelt.'],
        ),
        parseError: e.message,
        autoFixes: const [],
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return LessonV11ValidationResult(
        isValid: false,
        normalizedJson: normalized,
        parsed: null,
        issues: const [],
        fixPrompt: _buildFixPrompt(
          rawJson: normalized,
          issues: const ['Kok yapi bir JSON nesnesi olmali.'],
        ),
        parseError: 'Root JSON object olmalı.',
        autoFixes: const [],
      );
    }

    _validateRoot(decoded, issues);

    return LessonV11ValidationResult(
      isValid: issues.isEmpty,
      normalizedJson: _pretty(decoded),
      parsed: decoded,
      issues: issues,
      fixPrompt: _buildFixPrompt(
        rawJson: _pretty(decoded),
        issues: issues
            .map((issue) => '${issue.path}: ${issue.message}')
            .toList(),
      ),
      parseError: null,
      autoFixes: const [],
    );
  }

  LessonV11ValidationResult autoFixRaw(String rawInput) {
    final normalized = _normalizeRaw(rawInput);
    final textLevelFixes = <String>[];
    final sanitized = _applyTextLevelFixes(normalized, textLevelFixes);

    dynamic decoded;
    try {
      decoded = jsonDecode(sanitized);
    } on FormatException catch (e) {
      return LessonV11ValidationResult(
        isValid: false,
        normalizedJson: sanitized,
        parsed: null,
        issues: const [],
        fixPrompt: _buildFixPrompt(
          rawJson: sanitized,
          issues: const ['JSON parse edilemiyor. Auto-fix uygulanamadi.'],
        ),
        parseError: e.message,
        autoFixes: textLevelFixes,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return LessonV11ValidationResult(
        isValid: false,
        normalizedJson: sanitized,
        parsed: null,
        issues: const [],
        fixPrompt: _buildFixPrompt(
          rawJson: sanitized,
          issues: const [
            'Kok yapi bir JSON nesnesi olmali. Auto-fix uygulanamadi.',
          ],
        ),
        parseError: 'Root JSON object olmalı.',
        autoFixes: textLevelFixes,
      );
    }

    final fixed = _deepCloneMap(decoded);
    final autoFixes = <String>[...textLevelFixes];
    _autoFixRoot(fixed, autoFixes);

    final validated = validateRaw(_pretty(fixed));
    return LessonV11ValidationResult(
      isValid: validated.isValid,
      normalizedJson: validated.normalizedJson,
      parsed: validated.parsed,
      issues: validated.issues,
      fixPrompt: validated.fixPrompt,
      parseError: validated.parseError,
      autoFixes: autoFixes,
    );
  }

  String _normalizeRaw(String input) {
    var raw = input.trim();
    raw = raw.replaceFirst(RegExp(r'^```json\s*', caseSensitive: false), '');
    raw = raw.replaceFirst(RegExp(r'^```\s*'), '');
    raw = raw.replaceFirst(RegExp(r'\s*```$'), '');
    raw = raw.replaceFirst(RegExp(r'^[^{\[]+'), '');
    raw = raw.replaceFirst(RegExp(r'[^}\]]+$'), '');
    return raw.trim();
  }

  String _pretty(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }

  String _applyTextLevelFixes(String input, List<String> autoFixes) {
    var text = input;

    if (text.contains(r'\_')) {
      text = text.replaceAll(r'\_', '_');
      autoFixes.add(
        r'Metinsel duzeltme: tum `\_` dizileri `_` olarak degistirildi.',
      );
    }

    final cleanedSmartQuotes = text
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll("‘", "'")
        .replaceAll("’", "'");
    if (cleanedSmartQuotes != text) {
      text = cleanedSmartQuotes;
      autoFixes.add(
        'Metinsel duzeltme: akilli tirnaklar standart tirnaga cevrildi.',
      );
    }

    final cleanedSvgEscapes = text
        .replaceAll(r'\<', '<')
        .replaceAll(r'\>', '>')
        .replaceAll(r'\#', '#')
        .replaceAll(r'\!', '!')
        .replaceAll(r'\?', '?')
        .replaceAll(r'\:', ':')
        .replaceAll(r'\;', ';')
        .replaceAll(r'\[', '[')
        .replaceAll(r'\]', ']')
        .replaceAll(r'\(', '(')
        .replaceAll(r'\)', ')');
    if (cleanedSvgEscapes != text) {
      text = cleanedSvgEscapes;
      autoFixes.add(
        r'Metinsel duzeltme: kacisli karakterler (`\<`, `\>`, `\#`, `\!`, `\?`, `\:`, `\;`, `\[`, `\]`, `\(`, `\)`) temizlendi.',
      );
    }

    return text;
  }

  String _buildFixPrompt({
    required String rawJson,
    required List<String> issues,
  }) {
    final issueLines = issues.isEmpty
        ? '- Gecersiz gorunen bir durum var ama ayristirma sirasinda detay cikarilamadi.'
        : issues.map((issue) => '- $issue').join('\n');

    return '''
Asagidaki `lesson_v11` JSON'unu duzelt.

Kurallar:
- Cevap yalnizca gecerli JSON olsun.
- Markdown, aciklama, not, backtick veya kod blogu kullanma.
- Mevcut icerigi koru; yalnizca sema ve veri hatalarini duzelt.
- `image` bloglarinda oncelik `svgCode`, sonra `imageUrl`; ikisi de yoksa `image` blogunu tamamen kaldir.
- `ordering.items` nesne listesi olmali: `{ "id": "...", "text": "..." }`
- `ordering.correctOrder` sayi listesi degil, `items[].id` listesi olmali.
- `single_choice` ve `multiple_choice` secenekleri string listesi degil nesne listesi olmali.
- `true_false.correctAnswer` boolean olmali.
- `fill_blank.question_text` tam olarak 1 adet `________` icermeli.

Tespit edilen hatalar:
$issueLines

Duzeltilecek JSON:
$rawJson
''';
  }

  Map<String, dynamic> _deepCloneMap(Map<String, dynamic> source) {
    return Map<String, dynamic>.from(
      jsonDecode(jsonEncode(source)) as Map<String, dynamic>,
    );
  }

  void _autoFixRoot(Map<String, dynamic> root, List<String> autoFixes) {
    final lessonModule = root['lessonModule'];
    if (lessonModule is! Map<String, dynamic>) {
      return;
    }
    final sections = lessonModule['sections'];
    if (sections is! List) {
      return;
    }

    for (var sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
      final section = sections[sectionIndex];
      if (section is! Map<String, dynamic>) {
        continue;
      }

      _autoFixContentBlocks(
        section['content'],
        'lessonModule.sections[$sectionIndex].content',
        autoFixes,
      );
      _autoFixQuizBlocks(
        section['quiz'],
        'lessonModule.sections[$sectionIndex].quiz',
        autoFixes,
      );
    }
  }

  void _autoFixContentBlocks(
    dynamic blocks,
    String path,
    List<String> autoFixes,
  ) {
    if (blocks is! List) return;
    blocks.removeWhere((block) {
      if (block is! Map<String, dynamic>) return false;
      final content = block['content'];
      if (content is! Map<String, dynamic>) return false;
      if (block['type'] == 'markdown') {
        _autoFixMarkdownContent(content, '$path.body', autoFixes);
        return false;
      }
      if (block['type'] != 'image') return false;
      _autoFixSvgContent(content, '$path.svgCode', autoFixes);
      final svgCode = (content['svgCode'] as String? ?? '').trim();
      final imageUrl = (content['imageUrl'] as String? ?? '').trim();
      final hasSvg = svgCode.startsWith('<svg');
      final hasImage =
          imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
      final remove = !hasSvg && !hasImage;
      if (remove) {
        autoFixes.add('$path: bos image blogu kaldirildi.');
      }
      return remove;
    });
  }

  void _autoFixMarkdownContent(
    Map<String, dynamic> content,
    String path,
    List<String> autoFixes,
  ) {
    final rawBody = content['body'];
    if (rawBody is! String || rawBody.isEmpty) {
      return;
    }

    var body = rawBody;
    final original = body;

    body = body
        .replaceAll(r'\#', '#')
        .replaceAll(r'\*', '*')
        .replaceAll(r'\|', '|')
        .replaceAll(r'\!', '!')
        .replaceAll(r'\?', '?');

    if (body != original) {
      content['body'] = body;
      autoFixes.add(
        '$path: markdown icindeki gereksiz kacis karakterleri temizlendi.',
      );
    }
  }

  void _autoFixSvgContent(
    Map<String, dynamic> content,
    String path,
    List<String> autoFixes,
  ) {
    final rawSvg = content['svgCode'];
    if (rawSvg is! String || rawSvg.trim().isEmpty) {
      return;
    }

    var svg = rawSvg.trim();
    final original = svg;

    svg = svg
        .replaceAll(r'\<', '<')
        .replaceAll(r'\>', '>')
        .replaceAll(r'\#', '#')
        .replaceAll(r'\[', '[')
        .replaceAll(r'\]', ']')
        .replaceAll(r'\(', '(')
        .replaceAll(r'\)', ')');

    svg = svg.replaceAll(
      '[http://www.w3.org/2000/svg](http://www.w3.org/2000/svg)',
      'http://www.w3.org/2000/svg',
    );

    if (svg != original) {
      content['svgCode'] = svg;
      autoFixes.add(
        '$path: kacisli SVG ve markdown baglantisi ham SVG metnine cevrildi.',
      );
    }
  }

  void _autoFixQuizBlocks(dynamic blocks, String path, List<String> autoFixes) {
    if (blocks is! List) return;
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block is! Map<String, dynamic>) continue;
      final content = block['content'];
      if (content is! Map<String, dynamic>) continue;
      final questionType = content['questionType'];
      final blockPath = '$path[$i].content';

      if (questionType == 'single_choice' ||
          questionType == 'multiple_choice') {
        _autoFixOptions(content, blockPath, autoFixes);
      }
      if (questionType == 'true_false') {
        final current = content['correctAnswer'];
        if (current is String) {
          final value = current.trim().toLowerCase();
          if (value == 'true' || value == 'dogru') {
            content['correctAnswer'] = true;
            autoFixes.add('$blockPath.correctAnswer: string -> boolean true');
          } else if (value == 'false' || value == 'yanlis') {
            content['correctAnswer'] = false;
            autoFixes.add('$blockPath.correctAnswer: string -> boolean false');
          }
        }
      }
      if (questionType == 'ordering') {
        _autoFixOrdering(content, blockPath, autoFixes);
      }
      if (questionType == 'fill_blank') {
        _autoFixFillBlank(content, blockPath, autoFixes);
      }
    }
  }

  void _autoFixOptions(
    Map<String, dynamic> content,
    String path,
    List<String> autoFixes,
  ) {
    final options = content['options'];
    if (options is List &&
        options.isNotEmpty &&
        options.every((o) => o is String)) {
      content['options'] = [
        for (var i = 0; i < options.length; i++)
          {'id': 'opt_${i + 1}', 'text': options[i]},
      ];
      autoFixes.add('$path.options: string listesi nesne listesine cevrildi.');
    }

    final fixedOptions = content['options'];
    if (fixedOptions is! List) return;

    final optionIds = <String>[];
    for (final option in fixedOptions) {
      if (option is Map<String, dynamic> && option['id'] is String) {
        optionIds.add(option['id'] as String);
      }
    }

    final singleId = content['correctOptionId'];
    if (singleId is int && singleId >= 0 && singleId < optionIds.length) {
      content['correctOptionId'] = optionIds[singleId];
      autoFixes.add('$path.correctOptionId: index -> option id');
    }

    final multiIds = content['correctOptionIds'];
    if (multiIds is List && multiIds.every((id) => id is int)) {
      final mapped = <String>[];
      for (final rawIndex in multiIds.cast<int>()) {
        if (rawIndex >= 0 && rawIndex < optionIds.length) {
          mapped.add(optionIds[rawIndex]);
        }
      }
      if (mapped.isNotEmpty) {
        content['correctOptionIds'] = mapped;
        autoFixes.add(
          '$path.correctOptionIds: index listesi option id listesine cevrildi.',
        );
      }
    }
  }

  void _autoFixOrdering(
    Map<String, dynamic> content,
    String path,
    List<String> autoFixes,
  ) {
    final items = content['items'];
    if (items is List &&
        items.isNotEmpty &&
        items.every((item) => item is String)) {
      final converted = <Map<String, dynamic>>[];
      for (var i = 0; i < items.length; i++) {
        converted.add({'id': 'step_${i + 1}', 'text': items[i]});
      }
      content['items'] = converted;
      autoFixes.add('$path.items: string listesi nesne listesine cevrildi.');
    }

    final fixedItems = content['items'];
    if (fixedItems is! List) return;

    final itemIds = <String>[];
    for (final item in fixedItems) {
      if (item is Map<String, dynamic> && item['id'] is String) {
        itemIds.add(item['id'] as String);
      }
    }

    final correctOrder = content['correctOrder'];
    if (correctOrder is List && correctOrder.every((item) => item is int)) {
      final mapped = <String>[];
      for (final rawIndex in correctOrder.cast<int>()) {
        if (rawIndex >= 0 && rawIndex < itemIds.length) {
          mapped.add(itemIds[rawIndex]);
        }
      }
      if (mapped.isNotEmpty) {
        content['correctOrder'] = mapped;
        autoFixes.add(
          '$path.correctOrder: index listesi id listesine cevrildi.',
        );
      }
    }
  }

  void _autoFixFillBlank(
    Map<String, dynamic> content,
    String path,
    List<String> autoFixes,
  ) {
    final acceptedAnswers = content['acceptedAnswers'];
    if (acceptedAnswers is List && acceptedAnswers.isNotEmpty) {
      final fixed = acceptedAnswers
          .map((answer) {
            if (answer is String) return answer;
            if (answer is Map<String, dynamic> && answer['text'] is String) {
              return answer['text'] as String;
            }
            return null;
          })
          .whereType<String>()
          .toList();
      if (fixed.length != acceptedAnswers.length) {
        content['acceptedAnswers'] = fixed;
        autoFixes.add(
          '$path.acceptedAnswers: nesne/karisik liste string listesine cevrildi.',
        );
      }
    }

    final distractors = content['distractors'];
    if (distractors is List && distractors.isNotEmpty) {
      final fixed = distractors
          .map((item) {
            if (item is String) return item;
            if (item is Map<String, dynamic> && item['text'] is String) {
              return item['text'] as String;
            }
            return null;
          })
          .whereType<String>()
          .toList();
      if (fixed.length != distractors.length) {
        content['distractors'] = fixed;
        autoFixes.add(
          '$path.distractors: nesne/karisik liste string listesine cevrildi.',
        );
      }
    }
  }

  void _validateRoot(
    Map<String, dynamic> root,
    List<LessonV11ValidationIssue> issues,
  ) {
    final lessonModule = root['lessonModule'];
    if (lessonModule is! Map<String, dynamic>) {
      issues.add(
        const LessonV11ValidationIssue(
          path: 'lessonModule',
          message: '`lessonModule` nesnesi eksik veya gecersiz.',
        ),
      );
      return;
    }

    _requireString(lessonModule, 'id', 'lessonModule.id', issues);
    _requireString(lessonModule, 'title', 'lessonModule.title', issues);
    _requireString(
      lessonModule,
      'description',
      'lessonModule.description',
      issues,
    );
    _requireString(lessonModule, 'subject', 'lessonModule.subject', issues);
    _requireString(
      lessonModule,
      'gradeLevel',
      'lessonModule.gradeLevel',
      issues,
    );

    if (lessonModule['language'] != 'tr') {
      issues.add(
        const LessonV11ValidationIssue(
          path: 'lessonModule.language',
          message: '`language` alani `tr` olmali.',
        ),
      );
    }

    final tags = lessonModule['tags'];
    if (tags is! List || tags.any((tag) => tag is! String)) {
      issues.add(
        const LessonV11ValidationIssue(
          path: 'lessonModule.tags',
          message: '`tags` string listesi olmali.',
        ),
      );
    }

    final estimatedMinutes = lessonModule['estimatedMinutes'];
    if (estimatedMinutes is! num) {
      issues.add(
        const LessonV11ValidationIssue(
          path: 'lessonModule.estimatedMinutes',
          message: '`estimatedMinutes` sayi olmali.',
        ),
      );
    }

    final sections = lessonModule['sections'];
    if (sections is! List) {
      issues.add(
        const LessonV11ValidationIssue(
          path: 'lessonModule.sections',
          message: '`sections` listesi eksik veya gecersiz.',
        ),
      );
      return;
    }

    final allIds = <String>{};
    for (var i = 0; i < sections.length; i++) {
      final sectionPath = 'lessonModule.sections[$i]';
      final section = sections[i];
      if (section is! Map<String, dynamic>) {
        issues.add(
          LessonV11ValidationIssue(
            path: sectionPath,
            message: 'Section nesnesi gecersiz.',
          ),
        );
        continue;
      }
      _validateSection(section, sectionPath, issues, allIds);
    }
  }

  void _validateSection(
    Map<String, dynamic> section,
    String path,
    List<LessonV11ValidationIssue> issues,
    Set<String> allIds,
  ) {
    final id = _requireString(section, 'id', '$path.id', issues);
    if (id != null && !allIds.add(id)) {
      issues.add(
        LessonV11ValidationIssue(path: '$path.id', message: 'Tekrarlanan id.'),
      );
    }
    _requireString(section, 'title', '$path.title', issues);
    _requireString(section, 'icon', '$path.icon', issues);
    _requireInt(section, 'order', '$path.order', issues);

    if (section.containsKey('subsections')) {
      issues.add(
        LessonV11ValidationIssue(
          path: path,
          message: '`subsections` kullanilamaz.',
        ),
      );
    }
    if (section.containsKey('blocks')) {
      issues.add(
        LessonV11ValidationIssue(path: path, message: '`blocks` kullanilamaz.'),
      );
    }

    final content = section['content'];
    if (content is! List) {
      issues.add(
        LessonV11ValidationIssue(
          path: '$path.content',
          message: '`content` listesi eksik veya gecersiz.',
        ),
      );
    } else {
      for (var i = 0; i < content.length; i++) {
        final block = content[i];
        final blockPath = '$path.content[$i]';
        if (block is! Map<String, dynamic>) {
          issues.add(
            LessonV11ValidationIssue(
              path: blockPath,
              message: 'Icerik blogu nesnesi gecersiz.',
            ),
          );
          continue;
        }
        _validateContentBlock(block, blockPath, issues, allIds);
      }
    }

    final quiz = section['quiz'];
    if (quiz is! List) {
      issues.add(
        LessonV11ValidationIssue(
          path: '$path.quiz',
          message: '`quiz` listesi eksik veya gecersiz.',
        ),
      );
    } else {
      for (var i = 0; i < quiz.length; i++) {
        final block = quiz[i];
        final blockPath = '$path.quiz[$i]';
        if (block is! Map<String, dynamic>) {
          issues.add(
            LessonV11ValidationIssue(
              path: blockPath,
              message: 'Quiz blogu nesnesi gecersiz.',
            ),
          );
          continue;
        }
        _validateQuizBlock(block, blockPath, issues, allIds);
      }
    }
  }

  void _validateContentBlock(
    Map<String, dynamic> block,
    String path,
    List<LessonV11ValidationIssue> issues,
    Set<String> allIds,
  ) {
    final id = _requireString(block, 'id', '$path.id', issues);
    if (id != null && !allIds.add(id)) {
      issues.add(
        LessonV11ValidationIssue(path: '$path.id', message: 'Tekrarlanan id.'),
      );
    }
    _requireInt(block, 'order', '$path.order', issues);
    final type = _requireString(block, 'type', '$path.type', issues);

    if (type != null && !_contentTypes.contains(type)) {
      issues.add(
        LessonV11ValidationIssue(
          path: '$path.type',
          message: 'Desteklenmeyen content type: $type',
        ),
      );
    }

    final content = block['content'];
    if (content is! Map<String, dynamic>) {
      issues.add(
        LessonV11ValidationIssue(
          path: '$path.content',
          message: '`content` nesnesi olmali.',
        ),
      );
      return;
    }

    switch (type) {
      case 'markdown':
        _requireString(content, 'body', '$path.content.body', issues);
        break;
      case 'misconception':
        _requireString(content, 'wrong', '$path.content.wrong', issues);
        _requireString(content, 'correct', '$path.content.correct', issues);
        _requireString(content, 'tip', '$path.content.tip', issues);
        break;
      case 'image':
        _requireString(content, 'caption', '$path.content.caption', issues);
        _requireString(content, 'altText', '$path.content.altText', issues);
        _requireString(
          content,
          'imagePrompt',
          '$path.content.imagePrompt',
          issues,
        );
        final svgCode = (content['svgCode'] as String? ?? '').trim();
        final imageUrl = (content['imageUrl'] as String? ?? '').trim();
        final hasSvg = svgCode.startsWith('<svg');
        final hasImage =
            imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
        if (!hasSvg && !hasImage) {
          issues.add(
            LessonV11ValidationIssue(
              path: '$path.content',
              message:
                  '`image` blogunda `svgCode` veya `imageUrl` olmali; aksi halde bu blog uretilmemeli.',
            ),
          );
        }
        break;
    }
  }

  void _validateQuizBlock(
    Map<String, dynamic> block,
    String path,
    List<LessonV11ValidationIssue> issues,
    Set<String> allIds,
  ) {
    final id = _requireString(block, 'id', '$path.id', issues);
    if (id != null && !allIds.add(id)) {
      issues.add(
        LessonV11ValidationIssue(path: '$path.id', message: 'Tekrarlanan id.'),
      );
    }
    _requireInt(block, 'order', '$path.order', issues);

    if (block['type'] != 'quiz') {
      issues.add(
        LessonV11ValidationIssue(
          path: '$path.type',
          message: 'Quiz blogunun `type` degeri `quiz` olmali.',
        ),
      );
    }

    final content = block['content'];
    if (content is! Map<String, dynamic>) {
      issues.add(
        LessonV11ValidationIssue(
          path: '$path.content',
          message: '`content` nesnesi olmali.',
        ),
      );
      return;
    }

    _requireString(content, 'question', '$path.content.question', issues);
    _requireString(content, 'hint', '$path.content.hint', issues);
    _requireString(content, 'explanation', '$path.content.explanation', issues);

    final questionType = _requireString(
      content,
      'questionType',
      '$path.content.questionType',
      issues,
    );

    if (questionType != null && !_questionTypes.contains(questionType)) {
      issues.add(
        LessonV11ValidationIssue(
          path: '$path.content.questionType',
          message: 'Desteklenmeyen questionType: $questionType',
        ),
      );
      return;
    }

    switch (questionType) {
      case 'single_choice':
        _validateOptions(content, '$path.content', issues);
        final correctOptionId = content['correctOptionId'];
        if (correctOptionId is! String || correctOptionId.trim().isEmpty) {
          issues.add(
            LessonV11ValidationIssue(
              path: '$path.content.correctOptionId',
              message: '`correctOptionId` string olmali.',
            ),
          );
        }
        break;
      case 'multiple_choice':
        _validateOptions(content, '$path.content', issues);
        final correctOptionIds = content['correctOptionIds'];
        if (correctOptionIds is! List ||
            correctOptionIds.isEmpty ||
            correctOptionIds.any((id) => id is! String)) {
          issues.add(
            LessonV11ValidationIssue(
              path: '$path.content.correctOptionIds',
              message: '`correctOptionIds` string listesi olmali.',
            ),
          );
        }
        break;
      case 'true_false':
        _requireString(content, 'statement', '$path.content.statement', issues);
        if (content['correctAnswer'] is! bool) {
          issues.add(
            LessonV11ValidationIssue(
              path: '$path.content.correctAnswer',
              message: '`correctAnswer` boolean olmali.',
            ),
          );
        }
        break;
      case 'matching':
        final pairs = content['pairs'];
        if (pairs is! List || pairs.length < 3) {
          issues.add(
            LessonV11ValidationIssue(
              path: '$path.content.pairs',
              message: '`pairs` en az 3 oge iceren liste olmali.',
            ),
          );
        } else {
          final pairIds = <String>{};
          for (var i = 0; i < pairs.length; i++) {
            final pair = pairs[i];
            final pairPath = '$path.content.pairs[$i]';
            if (pair is! Map<String, dynamic>) {
              issues.add(
                LessonV11ValidationIssue(
                  path: pairPath,
                  message: 'Pair nesnesi gecersiz.',
                ),
              );
              continue;
            }
            final pairId = _requireString(pair, 'id', '$pairPath.id', issues);
            if (pairId != null && !pairIds.add(pairId)) {
              issues.add(
                LessonV11ValidationIssue(
                  path: '$pairPath.id',
                  message: 'Tekrarlanan pair id.',
                ),
              );
            }
            _requireString(pair, 'left', '$pairPath.left', issues);
            _requireString(pair, 'right', '$pairPath.right', issues);
          }
        }
        break;
      case 'ordering':
        final items = content['items'];
        if (items is! List || items.length < 4) {
          issues.add(
            LessonV11ValidationIssue(
              path: '$path.content.items',
              message: '`items` en az 4 nesneden olusan liste olmali.',
            ),
          );
        } else {
          final itemIds = <String>{};
          for (var i = 0; i < items.length; i++) {
            final item = items[i];
            final itemPath = '$path.content.items[$i]';
            if (item is! Map<String, dynamic>) {
              issues.add(
                LessonV11ValidationIssue(
                  path: itemPath,
                  message:
                      '`ordering.items` string degil nesne listesi olmali.',
                ),
              );
              continue;
            }
            final itemId = _requireString(item, 'id', '$itemPath.id', issues);
            if (itemId != null && !itemIds.add(itemId)) {
              issues.add(
                LessonV11ValidationIssue(
                  path: '$itemPath.id',
                  message: 'Tekrarlanan item id.',
                ),
              );
            }
            _requireString(item, 'text', '$itemPath.text', issues);
          }
          final correctOrder = content['correctOrder'];
          if (correctOrder is! List ||
              correctOrder.length != items.length ||
              correctOrder.any((id) => id is! String)) {
            issues.add(
              LessonV11ValidationIssue(
                path: '$path.content.correctOrder',
                message:
                    '`correctOrder`, `items[].id` degerlerinden olusan string listesi olmali.',
              ),
            );
          }
        }
        break;
      case 'fill_blank':
        final questionText = _requireString(
          content,
          'question_text',
          '$path.content.question_text',
          issues,
        );
        if (questionText != null &&
            RegExp('________').allMatches(questionText).length != 1) {
          issues.add(
            LessonV11ValidationIssue(
              path: '$path.content.question_text',
              message: '`question_text` tam olarak 1 adet `________` icermeli.',
            ),
          );
        }
        final acceptedAnswers = content['acceptedAnswers'];
        if (acceptedAnswers is! List ||
            acceptedAnswers.isEmpty ||
            acceptedAnswers.any((answer) => answer is! String)) {
          issues.add(
            LessonV11ValidationIssue(
              path: '$path.content.acceptedAnswers',
              message: '`acceptedAnswers` bos olmayan string listesi olmali.',
            ),
          );
        }
        final distractors = content['distractors'];
        if (distractors is! List ||
            distractors.length != 3 ||
            distractors.any((item) => item is! String)) {
          issues.add(
            LessonV11ValidationIssue(
              path: '$path.content.distractors',
              message: '`distractors` tam olarak 3 string icermeli.',
            ),
          );
        }
        break;
    }
  }

  void _validateOptions(
    Map<String, dynamic> content,
    String path,
    List<LessonV11ValidationIssue> issues,
  ) {
    final options = content['options'];
    if (options is! List || options.length != 4) {
      issues.add(
        LessonV11ValidationIssue(
          path: '$path.options',
          message: '`options` tam olarak 4 nesneden olusan liste olmali.',
        ),
      );
      return;
    }

    final optionIds = <String>{};
    for (var i = 0; i < options.length; i++) {
      final option = options[i];
      final optionPath = '$path.options[$i]';
      if (option is! Map<String, dynamic>) {
        issues.add(
          LessonV11ValidationIssue(
            path: optionPath,
            message: 'Secenek string degil nesne olmali.',
          ),
        );
        continue;
      }
      final optionId = _requireString(option, 'id', '$optionPath.id', issues);
      if (optionId != null && !optionIds.add(optionId)) {
        issues.add(
          LessonV11ValidationIssue(
            path: '$optionPath.id',
            message: 'Tekrarlanan option id.',
          ),
        );
      }
      _requireString(option, 'text', '$optionPath.text', issues);
    }
  }

  String? _requireString(
    Map<String, dynamic> source,
    String key,
    String path,
    List<LessonV11ValidationIssue> issues,
  ) {
    final value = source[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    issues.add(
      LessonV11ValidationIssue(
        path: path,
        message: '`$key` dolu bir string olmali.',
      ),
    );
    return null;
  }

  void _requireInt(
    Map<String, dynamic> source,
    String key,
    String path,
    List<LessonV11ValidationIssue> issues,
  ) {
    if (source[key] is int) {
      return;
    }
    issues.add(
      LessonV11ValidationIssue(path: path, message: '`$key` tam sayi olmali.'),
    );
  }
}
