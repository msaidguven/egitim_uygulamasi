import 'dart:convert';
import 'package:egitim_uygulamasi/admin/pages/smart_content_addition/smart_content_addition_page.dart';
import 'package:egitim_uygulamasi/admin/pages/smart_content_addition/smart_content_update_page.dart';
import 'package:egitim_uygulamasi/screens/outcomes/widgets/admin_copy_button.dart';
import 'package:egitim_uygulamasi/screens/lesson_content/lesson_v11/lesson_content_repository.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ═══════════════════════════════════════════════════════
// RENKLER
// ═══════════════════════════════════════════════════════

class _C {
  static const bg = Color(0xFFF0F4FF);
  static const List<Color> palette = [
    Color(0xFF6C63FF),
    Color(0xFF00ACC1),
    Color(0xFFFF6B6B),
    Color(0xFF43A047),
    Color(0xFFFF9800),
  ];
  static Color get(int i) => palette[i % palette.length];
  static const correct = Color(0xFF43A047);
  static const wrong = Color(0xFFE53935);
  static const hint = Color(0xFFFF9800);
}

// ═══════════════════════════════════════════════════════
// MODELLER
// ═══════════════════════════════════════════════════════

class LessonModule {
  final String id, title, description, subject, gradeLevel;
  final int estimatedMinutes;
  final List<LessonSection> sections;

  LessonModule({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.gradeLevel,
    required this.estimatedMinutes,
    required this.sections,
  });

  factory LessonModule.fromJson(Map<String, dynamic> json) {
    final m = json['lessonModule'] as Map<String, dynamic>;
    final sections =
        (m['sections'] as List? ?? [])
            .map((s) => LessonSection.fromJson(s))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    return LessonModule(
      id: m['id'],
      title: m['title'],
      description: m['description'],
      subject: m['subject'] ?? '',
      gradeLevel: m['gradeLevel'] ?? '',
      estimatedMinutes: m['estimatedMinutes'] ?? 0,
      sections: sections,
    );
  }
}

class LessonSection {
  final String id, title, icon;
  final int order;
  final List<LessonBlock> content;
  final List<LessonBlock> quiz;

  LessonSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.order,
    required this.content,
    required this.quiz,
  });

  factory LessonSection.fromJson(Map<String, dynamic> json) {
    final content =
        (json['content'] as List? ?? [])
            .map((b) => LessonBlock.fromJson(b))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    final quiz =
        (json['quiz'] as List? ?? [])
            .map((b) => LessonBlock.fromJson(b))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    return LessonSection(
      id: json['id'],
      title: json['title'],
      icon: json['icon'] ?? '📄',
      order: json['order'],
      content: content,
      quiz: quiz,
    );
  }
}

class LessonBlock {
  final String id, type;
  final int order;
  final Map<String, dynamic> content;

  LessonBlock({
    required this.id,
    required this.type,
    required this.order,
    required this.content,
  });

  factory LessonBlock.fromJson(Map<String, dynamic> json) => LessonBlock(
    id: json['id'],
    type: json['type'],
    order: json['order'],
    content: Map<String, dynamic>.from(json['content']),
  );
}

// ═══════════════════════════════════════════════════════
// EKRAN TÜRÜ
// ═══════════════════════════════════════════════════════

enum _ScreenType { content, quiz }

class _ScreenKey {
  final int sectionIndex;
  final _ScreenType type;
  const _ScreenKey(this.sectionIndex, this.type);
  @override
  bool operator ==(Object other) =>
      other is _ScreenKey &&
      other.sectionIndex == sectionIndex &&
      other.type == type;
  @override
  int get hashCode => Object.hash(sectionIndex, type);
}

// ═══════════════════════════════════════════════════════
// ANA SAYFA
// ═══════════════════════════════════════════════════════

class LessonPage extends StatefulWidget {
  final String? jsonString;
  final String? assetPath;
  final int? topicId;
  const LessonPage({super.key, this.jsonString, this.assetPath, this.topicId});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  static const String _musicAsset = 'audio/bg_music.mp3';
  LessonModule? _module;
  bool _loading = true;
  double _contentTextScale = 1.0;
  final List<_ScreenKey> _history = [const _ScreenKey(0, _ScreenType.content)];
  final Set<String> _completedQuizIds = {};
  final Set<_ScreenKey> _completedScreens = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  final LessonV11ContentRepository _repository = LessonV11ContentRepository();
  bool _musicOn = false;
  String? _errorMessage;
  bool _isAdmin = false;
  LessonV11AdminContext? _adminContext;
  LessonV11ContentRecord? _loadedContent;

  @override
  void initState() {
    super.initState();
    _initMusic();
    _loadLesson();
  }

  Future<void> _initMusic() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(0.35);
    await _audioPlayer.play(AssetSource(_musicAsset));
    await _audioPlayer.pause();
  }

  Future<void> _toggleMusic() async {
    if (_musicOn) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
    if (!mounted) return;
    setState(() => _musicOn = !_musicOn);
  }

  void _increaseContentTextScale() {
    setState(() {
      _contentTextScale = (_contentTextScale + 0.2).clamp(0.85, 3.6);
    });
  }

  void _decreaseContentTextScale() {
    setState(() {
      _contentTextScale = (_contentTextScale - 0.2).clamp(0.85, 3.6);
    });
  }

  Future<void> _loadLesson() async {
    try {
      String raw;
      if (widget.jsonString != null) {
        raw = widget.jsonString!;
        _loadedContent = null;
      } else if (widget.topicId != null) {
        final dbContent = await _repository.fetchLatestPublishedContentForTopic(
          widget.topicId!,
        );
        if (dbContent != null) {
          _loadedContent = dbContent;
          raw = dbContent.jsonString;
        } else if (widget.assetPath != null) {
          _loadedContent = null;
          raw = await rootBundle.loadString(widget.assetPath!);
        } else {
          throw Exception(
            'topic_id=${widget.topicId} icin yayinlanmis topic_contents_v11 kaydi bulunamadi.',
          );
        }
      } else if (widget.assetPath != null) {
        raw = await rootBundle.loadString(widget.assetPath!);
      } else {
        throw Exception('jsonString, topicId veya assetPath belirtilmeli');
      }

      if (!mounted) return;
      setState(() {
        _module = LessonModule.fromJson(jsonDecode(raw));
        _errorMessage = null;
        _loading = false;
      });
      if (widget.topicId != null) {
        await _loadAdminContext(widget.topicId!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadAdminContext(int topicId) async {
    try {
      final isAdmin = await _repository.isCurrentUserAdmin();
      if (!isAdmin) return;
      final adminContext = await _repository.fetchAdminContextForTopic(topicId);
      if (!mounted) return;
      setState(() {
        _isAdmin = isAdmin;
        _adminContext = adminContext;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
        _adminContext = null;
      });
    }
  }

  Future<void> _copyV11Prompt() async {
    final adminContext = _adminContext;
    if (adminContext == null) return;
    await AdminCopyButton.copyPrompt(
      context,
      gradeName: adminContext.gradeName,
      lessonName: adminContext.lessonName,
      unitTitle: adminContext.unitTitle,
      topicTitle: adminContext.topicTitle,
      outcomes: adminContext.outcomes,
      promptType: AdminPromptType.contentV2,
    );
  }

  Future<void> _openSmartContentAddition() async {
    final adminContext = _adminContext;
    if (adminContext == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmartContentAdditionPage(
          initialGradeId: adminContext.gradeId,
          initialLessonId: adminContext.lessonId,
          initialUnitId: adminContext.unitId,
          initialTopicId: adminContext.topicId,
        ),
      ),
    );
  }

  Future<void> _openSmartContentUpdate() async {
    final adminContext = _adminContext;
    if (adminContext == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmartContentUpdatePage(
          initialGradeId: adminContext.gradeId,
          initialLessonId: adminContext.lessonId,
          initialUnitId: adminContext.unitId,
          initialTopicId: adminContext.topicId,
        ),
      ),
    );
  }

  Future<void> _publishLatestVersion() async {
    final topicId = widget.topicId;
    if (topicId == null) return;
    final published = await _repository.publishLatestVersionForTopic(topicId);
    if (!mounted) return;
    if (published == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yayinlanacak bir V11 surumu bulunamadi.'),
        ),
      );
      return;
    }

    setState(() {
      _loadedContent = published;
      _module = LessonModule.fromJson(published.payload);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Surum ${published.versionNo} yayina alindi.')),
    );
  }

  Future<void> _unpublishCurrentContent() async {
    final loadedContent = _loadedContent;
    if (loadedContent == null) return;
    await _repository.unpublishContent(loadedContent.id);
    if (!mounted) return;
    setState(() {
      _loadedContent = LessonV11ContentRecord(
        id: loadedContent.id,
        topicId: loadedContent.topicId,
        versionNo: loadedContent.versionNo,
        isPublished: false,
        payload: loadedContent.payload,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mevcut V11 icerigi yayindan kaldirildi.')),
    );
  }

  _ScreenKey get _current => _history.last;
  bool get _canGoBack => _history.length > 1;

  void _handleBackNavigation() {
    if (_canGoBack) {
      setState(() => _history.removeLast());
      return;
    }
    Navigator.maybePop(context);
  }

  void _pushScreen(_ScreenKey key) {
    setState(() => _history.add(key));
  }

  void _onContentDone(int sectionIndex) {
    _completedScreens.add(_ScreenKey(sectionIndex, _ScreenType.content));
    final section = _module!.sections[sectionIndex];
    if (section.quiz.isNotEmpty) {
      _pushScreen(_ScreenKey(sectionIndex, _ScreenType.quiz));
    } else {
      _goToNextSection(sectionIndex);
    }
  }

  void _onQuizDone(int sectionIndex) {
    _completedScreens.add(_ScreenKey(sectionIndex, _ScreenType.quiz));
    _goToNextSection(sectionIndex);
  }

  void _goToNextSection(int sectionIndex) {
    final sections = _module!.sections;
    if (sectionIndex < sections.length - 1) {
      _pushScreen(_ScreenKey(sectionIndex + 1, _ScreenType.content));
    } else {
      _pushScreen(const _ScreenKey(-1, _ScreenType.content));
    }
  }

  double get _progress {
    if (_module == null) return 0;
    final total = _module!.sections.fold<int>(
      0,
      (sum, section) => sum + 1 + (section.quiz.isNotEmpty ? 1 : 0),
    );
    if (total == 0) return 0;
    final done = _completedScreens.length;
    return (done / total).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _C.bg,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
      );
    }

    if (_errorMessage != null || _module == null) {
      return Scaffold(
        backgroundColor: _C.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 44,
                  color: Color(0xFFB91C1C),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Lesson V11 yuklenemedi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Icerik bulunamadi.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B7280), height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final module = _module!;
    final current = _current;

    if (current.sectionIndex == -1) {
      return _FinishScreen(
        module: module,
        onRestart: () {
          setState(() {
            _history
              ..clear()
              ..add(const _ScreenKey(0, _ScreenType.content));
            _completedQuizIds.clear();
            _completedScreens.clear();
          });
        },
      );
    }

    final sectionIndex = current.sectionIndex;
    final section = module.sections[sectionIndex];
    final color = _C.get(sectionIndex);

    return WillPopScope(
      onWillPop: () async {
        if (_canGoBack) {
          _handleBackNavigation();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: _C.bg,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                module: module,
                progress: _progress,
                color: color,
                canGoBack: true,
                onBack: _handleBackNavigation,
                canIncreaseText: _contentTextScale < 3.6,
                canDecreaseText: _contentTextScale > 0.85,
                onIncreaseText: _increaseContentTextScale,
                onDecreaseText: _decreaseContentTextScale,
                musicOn: _musicOn,
                onToggleMusic: _toggleMusic,
                adminMenu: _isAdmin && _adminContext != null
                    ? _LessonAdminMenu(
                        onCopyPrompt: _copyV11Prompt,
                        onAddContent: _openSmartContentAddition,
                        onUpdateContent: _openSmartContentUpdate,
                        onPublishLatest: _publishLatestVersion,
                        onUnpublishCurrent: _unpublishCurrentContent,
                        canUnpublishCurrent:
                            _loadedContent != null &&
                            _loadedContent!.isPublished,
                      )
                    : null,
              ),
              Expanded(
                child: MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(_contentTextScale)),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) => SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    ),
                    child: current.type == _ScreenType.content
                        ? _ContentScreen(
                            key: ValueKey('c_$sectionIndex'),
                            section: section,
                            sectionIndex: sectionIndex,
                            color: color,
                            onDone: () => _onContentDone(sectionIndex),
                          )
                        : _QuizScreen(
                            key: ValueKey('q_$sectionIndex'),
                            section: section,
                            sectionIndex: sectionIndex,
                            color: color,
                            completedIds: _completedQuizIds,
                            onQuizAnswered: (id) =>
                                setState(() => _completedQuizIds.add(id)),
                            onDone: () => _onQuizDone(sectionIndex),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// ÜST BAR
// ═══════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final LessonModule module;
  final double progress;
  final Color color;
  final bool canGoBack;
  final VoidCallback onBack;
  final bool canIncreaseText;
  final bool canDecreaseText;
  final VoidCallback onIncreaseText;
  final VoidCallback onDecreaseText;
  final bool musicOn;
  final Future<void> Function() onToggleMusic;
  final Widget? adminMenu;

  const _TopBar({
    required this.module,
    required this.progress,
    required this.color,
    required this.canGoBack,
    required this.onBack,
    required this.canIncreaseText,
    required this.canDecreaseText,
    required this.onIncreaseText,
    required this.onDecreaseText,
    required this.musicOn,
    required this.onToggleMusic,
    this.adminMenu,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toInt();
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedOpacity(
                opacity: canGoBack ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  onPressed: canGoBack ? onBack : null,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: const Color(0xFF374151),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.subject,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      module.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '%$pct',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.text_decrease_rounded,
                color: const Color(0xFFB45309),
                enabled: canDecreaseText,
                onTap: onDecreaseText,
              ),
              const SizedBox(width: 6),
              _HeaderIconButton(
                icon: Icons.text_increase_rounded,
                color: const Color(0xFF047857),
                enabled: canIncreaseText,
                onTap: onIncreaseText,
              ),
              const SizedBox(width: 6),
              _HeaderIconButton(
                icon: musicOn
                    ? Icons.volume_off_rounded
                    : Icons.music_note_rounded,
                color: const Color(0xFF7C3AED),
                onTap: onToggleMusic,
              ),
              if (adminMenu != null) ...[const SizedBox(width: 6), adminMenu!],
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonAdminMenu extends StatelessWidget {
  const _LessonAdminMenu({
    required this.onCopyPrompt,
    required this.onAddContent,
    required this.onUpdateContent,
    required this.onPublishLatest,
    required this.onUnpublishCurrent,
    required this.canUnpublishCurrent,
  });

  final Future<void> Function() onCopyPrompt;
  final Future<void> Function() onAddContent;
  final Future<void> Function() onUpdateContent;
  final Future<void> Function() onPublishLatest;
  final Future<void> Function() onUnpublishCurrent;
  final bool canUnpublishCurrent;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Yonetici menusu',
      onSelected: (value) async {
        if (value == 'copy_prompt') {
          await onCopyPrompt();
          return;
        }
        if (value == 'add_content') {
          await onAddContent();
          return;
        }
        if (value == 'update_content') {
          await onUpdateContent();
          return;
        }
        if (value == 'publish_latest') {
          await onPublishLatest();
          return;
        }
        if (value == 'unpublish_current') {
          await onUnpublishCurrent();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'copy_prompt',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.data_object_rounded),
            title: Text('V11 promptunu kopyala'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'add_content',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.auto_awesome_rounded),
            title: Text('Akilli icerik ekle'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'update_content',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_note_rounded),
            title: Text('Icerigi guncelle'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'publish_latest',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.publish_rounded),
            title: Text('Son surumu yayina al'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'unpublish_current',
          enabled: canUnpublishCurrent,
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.visibility_off_rounded),
            title: Text('Mevcut yayini kaldir'),
          ),
        ),
      ],
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: const Color(0xFF2563EB).withValues(alpha: 0.28),
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.admin_panel_settings_rounded,
          size: 18,
          color: Color(0xFF2563EB),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _HeaderIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: color.withValues(alpha: 0.28),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// İÇERİK EKRANI
// ═══════════════════════════════════════════════════════

class _ContentScreen extends StatefulWidget {
  final LessonSection section;
  final int sectionIndex;
  final Color color;
  final VoidCallback onDone;

  const _ContentScreen({
    super.key,
    required this.section,
    required this.sectionIndex,
    required this.color,
    required this.onDone,
  });

  @override
  State<_ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<_ContentScreen> {
  int _cardIndex = 0;

  void _next() {
    if (_cardIndex < widget.section.content.length - 1) {
      setState(() => _cardIndex++);
    } else {
      widget.onDone();
    }
  }

  void _prev() {
    if (_cardIndex > 0) setState(() => _cardIndex--);
  }

  bool get _isLast => _cardIndex == widget.section.content.length - 1;

  @override
  Widget build(BuildContext context) {
    final total = widget.section.content.length;
    if (total == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      return const SizedBox.shrink();
    }
    final block = widget.section.content[_cardIndex];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            children: [
              _SectionBanner(
                section: widget.section,
                color: widget.color,
                isQuiz: false,
              ),
              const SizedBox(height: 12),
              if (total > 1) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(total, (i) {
                    final active = i == _cardIndex;
                    final done = i < _cardIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: done || active
                            ? widget.color
                            : const Color(0xFFDDE1E9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_cardIndex),
                  child: _buildBlock(block),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          color: const Color(0xFFF0F4FF),
          child: Row(
            children: [
              AnimatedOpacity(
                opacity: _cardIndex > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _cardIndex > 0 ? _prev : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: widget.color,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: widget.color.withOpacity(0.3)),
                      ),
                      elevation: 0,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                      shadowColor: widget.color.withOpacity(0.4),
                    ),
                    child: Text(
                      _isLast
                          ? (widget.section.quiz.isNotEmpty
                                ? 'Soruları Çöz  →'
                                : 'Sonraki Bölüm  →')
                          : 'Devam  →',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlock(LessonBlock block) {
    switch (block.type) {
      case 'markdown':
        return _MarkdownCard(
          body: block.content['body'] ?? '',
          color: widget.color,
        );
      case 'image':
        return _ImageCard(content: block.content, color: widget.color);
      case 'misconception':
        return _MisconceptionCard(content: block.content, color: widget.color);
      default:
        return _UnsupportedBlockCard(
          blockType: block.type,
          color: widget.color,
        );
    }
  }
}

// ═══════════════════════════════════════════════════════
// QUIZ EKRANI  — kart kart ilerler
// ═══════════════════════════════════════════════════════

class _QuizScreen extends StatefulWidget {
  final LessonSection section;
  final int sectionIndex;
  final Color color;
  final Set<String> completedIds;
  final ValueChanged<String> onQuizAnswered;
  final VoidCallback onDone;

  const _QuizScreen({
    super.key,
    required this.section,
    required this.sectionIndex,
    required this.color,
    required this.completedIds,
    required this.onQuizAnswered,
    required this.onDone,
  });

  @override
  State<_QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<_QuizScreen> {
  int _idx = 0; // aktif soru indeksi

  List<LessonBlock> get _quiz => widget.section.quiz;
  bool get _allDone => _quiz.every((q) => widget.completedIds.contains(q.id));

  void _next() {
    if (_idx < _quiz.length - 1) {
      setState(() => _idx++);
    }
  }

  void _prev() {
    if (_idx > 0) setState(() => _idx--);
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _quiz;
    if (quiz.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      return const SizedBox.shrink();
    }

    final block = quiz[_idx];
    final isDone = widget.completedIds.contains(block.id);
    final isLast = _idx == quiz.length - 1;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            children: [
              _SectionBanner(
                section: widget.section,
                color: widget.color,
                isQuiz: true,
              ),
              const SizedBox(height: 10),
              // Soru ilerleme göstergesi
              if (quiz.length > 1) ...[
                Row(
                  children: List.generate(quiz.length, (i) {
                    final done = widget.completedIds.contains(quiz[i].id);
                    final active = i == _idx;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _idx = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 6,
                          margin: EdgeInsets.only(
                            right: i < quiz.length - 1 ? 6 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: done
                                ? _C.correct
                                : active
                                ? widget.color
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    '${_idx + 1} / ${quiz.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.color,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Aktif soru kartı — animasyonlu geçiş
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: KeyedSubtree(
                  key: ValueKey(block.id),
                  child: _buildQuizCard(block),
                ),
              ),
              // Tüm sorular bitti → tebrik + devam
              if (_allDone) ...[
                const SizedBox(height: 16),
                _AllCorrectBanner(color: widget.color),
              ],
            ],
          ),
        ),
        // Alt navigasyon (geri / ileri veya sonraki bölüm)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          color: const Color(0xFFF0F4FF),
          child: Row(
            children: [
              // Geri
              AnimatedOpacity(
                opacity: _idx > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _idx > 0 ? _prev : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: widget.color,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: widget.color.withOpacity(0.3)),
                      ),
                      elevation: 0,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // İleri / Sonraki Bölüm
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: _allDone && isLast
                      ? ElevatedButton(
                          onPressed: widget.onDone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.correct,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Sonraki Bölüm  →',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: (isDone && !isLast) ? _next : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            disabledBackgroundColor: const Color(0xFFE5E7EB),
                            elevation: 0,
                          ),
                          child: Text(
                            isDone && !isLast
                                ? 'Sonraki Soru  →'
                                : isLast && isDone
                                ? 'Sonraki Bölüm  →'
                                : 'Soruyu Yanıtla',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: (isDone && !isLast)
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizCard(LessonBlock block) {
    final qt = block.content['questionType'] as String? ?? 'single_choice';
    switch (qt) {
      case 'matching':
        return _MatchingCard(
          block: block,
          color: widget.color,
          onAnswered: () => widget.onQuizAnswered(block.id),
          done: widget.completedIds.contains(block.id),
        );
      case 'fill_blank':
        return _FillBlankCard(
          block: block,
          color: widget.color,
          onAnswered: () => widget.onQuizAnswered(block.id),
          done: widget.completedIds.contains(block.id),
        );
      case 'ordering':
        return _OrderingCard(
          block: block,
          color: widget.color,
          onAnswered: () => widget.onQuizAnswered(block.id),
          done: widget.completedIds.contains(block.id),
        );
      case 'true_false':
        return _TrueFalseCard(
          block: block,
          color: widget.color,
          onAnswered: () => widget.onQuizAnswered(block.id),
          done: widget.completedIds.contains(block.id),
        );
      default: // single_choice, multiple_choice
        return _ChoiceCard(
          block: block,
          color: widget.color,
          onAnswered: () => widget.onQuizAnswered(block.id),
          done: widget.completedIds.contains(block.id),
        );
    }
  }
}

// ═══════════════════════════════════════════════════════
// ORTAK YARDIMCI — İpucu + Geri Bildirim Kutusu
// ═══════════════════════════════════════════════════════

class _HintBox extends StatefulWidget {
  final String hint;
  final bool visible;
  const _HintBox({required this.hint, required this.visible});
  @override
  State<_HintBox> createState() => _HintBoxState();
}

class _HintBoxState extends State<_HintBox> {
  bool _open = true;
  @override
  void didUpdateWidget(_HintBox old) {
    super.didUpdateWidget(old);
    if (!old.visible && widget.visible) setState(() => _open = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _C.hint.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.hint.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                const Text(
                  'İpucu',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _C.hint,
                  ),
                ),
                const Spacer(),
                Icon(
                  _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18,
                  color: _C.hint,
                ),
              ],
            ),
            if (_open) ...[
              const SizedBox(height: 6),
              Text(
                widget.hint,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7B5800),
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// SIRALAMA SORULARI — BELİRGİN İPUCU KUTUSU
// Her zaman görünür, baştan açık, öğrenmeyi destekler
// ═══════════════════════════════════════════════════════

class _OrderingHintBox extends StatefulWidget {
  final String hint;
  const _OrderingHintBox({required this.hint});
  @override
  State<_OrderingHintBox> createState() => _OrderingHintBoxState();
}

class _OrderingHintBoxState extends State<_OrderingHintBox> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFB300), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB300).withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'İpucu',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF7B5800),
                    ),
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 20,
                  color: const Color(0xFF7B5800),
                ),
              ],
            ),
            if (_open) ...[
              const SizedBox(height: 8),
              Text(
                widget.hint,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF5C3D00),
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackBox extends StatelessWidget {
  final bool isCorrect;
  final String explanation;
  const _FeedbackBox({required this.isCorrect, required this.explanation});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFECFDF5) : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isCorrect ? '🎉' : '🔄', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? 'Harika! Doğru cevap!' : 'Tekrar dene!',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: isCorrect ? _C.correct : _C.wrong,
                  ),
                ),
                if (isCorrect && explanation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    explanation,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF065F46),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _quizShell({
  required Color color,
  required String typeLabel,
  required int attempts,
  required bool submitted,
  required bool isCorrect,
  required List<Widget> children,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFDE7),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: submitted
            ? (isCorrect ? _C.correct : _C.wrong)
            : const Color(0xFFFFD54F),
        width: submitted ? 2 : 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const Spacer(),
            if (attempts > 0 && !isCorrect)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.wrong.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$attempts. deneme',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _C.wrong,
                  ),
                ),
              ),
          ],
        ),
        ...children,
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════
// TEK / ÇOKLU SEÇİM KARTI
// ═══════════════════════════════════════════════════════

class _ChoiceCard extends StatefulWidget {
  final LessonBlock block;
  final Color color;
  final VoidCallback onAnswered;
  final bool done;
  const _ChoiceCard({
    super.key,
    required this.block,
    required this.color,
    required this.onAnswered,
    required this.done,
  });
  @override
  State<_ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<_ChoiceCard>
    with SingleTickerProviderStateMixin {
  String? _selected;
  Set<String> _multi = {};
  bool _submitted = false;
  bool _isCorrect = false;
  int _attempts = 0;
  bool _showHint = false;

  late AnimationController _shake;
  late Animation<double> _shakeAnim;

  bool get _isMultiple =>
      widget.block.content['questionType'] == 'multiple_choice';

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _shake, curve: Curves.elasticIn));
    if (widget.done) {
      _submitted = true;
      _isCorrect = true;
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _submit() {
    final correctIds = Set<String>.from(
      widget.block.content['correctOptionIds'] ?? [],
    );
    final correct = _isMultiple
        ? setEquals(correctIds, _multi)
        : _selected == widget.block.content['correctOptionId'];

    setState(() {
      _submitted = true;
      _isCorrect = correct;
      _attempts++;
    });

    if (correct) {
      widget.onAnswered();
    } else {
      _shake.forward(from: 0);
      // Yanlışta seçimler temizlenmiyor — kullanıcı neyin yanlış olduğunu görüp düzeltsin
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _submitted = false;
            _showHint = true;
          });
          _shake.reset();
        }
      });
    }
  }

  void _handleOptionTap(String id) {
    if (_submitted) return;
    setState(() {
      if (_isMultiple) {
        _multi.contains(id) ? _multi.remove(id) : _multi.add(id);
      } else {
        _selected = id;
      }
    });
    if (!_isMultiple) {
      _submit();
    }
  }

  /// Her seçeneğin durumu bağımsız hesaplanır:
  /// - Doğru şık: her zaman yeşil (seçilmiş olsun olmasın)
  /// - Yanlış seçilen: kırmızı
  /// - Diğerleri: normal
  bool _isOptCorrect(String id) {
    if (_isMultiple) {
      return Set<String>.from(
        widget.block.content['correctOptionIds'] ?? [],
      ).contains(id);
    }
    return id == widget.block.content['correctOptionId'];
  }

  Color _optBg(String id) {
    final sel = _isMultiple ? _multi.contains(id) : _selected == id;
    if (!_submitted) return sel ? widget.color.withOpacity(0.1) : Colors.white;
    final ok = _isOptCorrect(id);
    if (_isCorrect && ok) return const Color(0xFFECFDF5);
    if (sel && !ok) return const Color(0xFFFFF0F0);
    return Colors.white;
  }

  Color _optBorder(String id) {
    final sel = _isMultiple ? _multi.contains(id) : _selected == id;
    if (!_submitted) return sel ? widget.color : const Color(0xFFE5E7EB);
    final ok = _isOptCorrect(id);
    if (_isCorrect && ok) return _C.correct;
    if (sel && !ok) return _C.wrong;
    return const Color(0xFFE5E7EB);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.block.content;
    final options = (c['options'] as List? ?? []).cast<Map<String, dynamic>>();
    final explanation = c['explanation'] as String? ?? '';
    final hint = c['hint'] as String? ?? '';

    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (ctx, child) {
        final dx = _submitted && !_isCorrect
            ? (_shakeAnim.value * 10 * ((_attempts % 2 == 0) ? 1 : -1)).clamp(
                -12.0,
                12.0,
              )
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: _quizShell(
        color: widget.color,
        typeLabel: _isMultiple ? '☑️  Çoklu Seçim' : '❓  Tek Seçim',
        attempts: _attempts,
        submitted: _submitted,
        isCorrect: _isCorrect,
        children: [
          const SizedBox(height: 12),
          Text(
            c['question'] ?? '',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          ...options.map((opt) {
            final id = opt['id'] as String;
            final sel = _isMultiple ? _multi.contains(id) : _selected == id;
            return GestureDetector(
              onTap: _submitted ? null : () => _handleOptionTap(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _optBg(id),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _optBorder(id), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _submitted
                            ? (_isCorrect && _isOptCorrect(id)
                                  ? _C.correct
                                  : sel
                                  ? _C.wrong
                                  : const Color(0xFFEEEEEE))
                            : sel
                            ? widget.color
                            : const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(
                          _isMultiple ? 6 : 14,
                        ),
                      ),
                      child: Center(
                        child: _submitted && _isCorrect && _isOptCorrect(id)
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              )
                            : _submitted && sel && !_isOptCorrect(id)
                            ? const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.white,
                              )
                            : Text(
                                opt['label'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: sel
                                      ? Colors.white
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        opt['text'] ?? '',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: _submitted
                              ? (_isCorrect && _isOptCorrect(id)
                                    ? _C.correct
                                    : sel
                                    ? _C.wrong
                                    : const Color(0xFF374151))
                              : const Color(0xFF374151),
                          fontWeight: _submitted && _isOptCorrect(id)
                              ? FontWeight.w700
                              : FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          _HintBox(
            hint: hint,
            visible: _showHint && _attempts > 0 && !_isCorrect,
          ),
          if (_isMultiple && !(_submitted && _isCorrect)) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: !_submitted && _multi.isNotEmpty ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  elevation: 0,
                ),
                child: const Text(
                  'Cevabı Kontrol Et',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
          if (_submitted)
            _FeedbackBox(isCorrect: _isCorrect, explanation: explanation),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// BOŞLUK DOLDURMA KARTI
// ═══════════════════════════════════════════════════════

class _FillBlankCard extends StatefulWidget {
  final LessonBlock block;
  final Color color;
  final VoidCallback onAnswered;
  final bool done;
  const _FillBlankCard({
    super.key,
    required this.block,
    required this.color,
    required this.onAnswered,
    required this.done,
  });
  @override
  State<_FillBlankCard> createState() => _FillBlankCardState();
}

class _FillBlankCardState extends State<_FillBlankCard> {
  String? _selected; // seçilen kelime
  bool _submitted = false;
  bool _isCorrect = false;
  int _attempts = 0;
  bool _showHint = false;
  late List<String> _wordOptions; // karıştırılmış seçenekler

  @override
  void initState() {
    super.initState();
    _wordOptions = _buildWordOptions();
    if (widget.done) {
      _submitted = true;
      _isCorrect = true;
      _selected = _displayAnswer;
    }
  }

  List<String> get _acceptedAnswers {
    final raw =
        (widget.block.content['acceptedAnswers'] as List? ??
                [widget.block.content['correctAnswer'] ?? ''])
            .cast<String>()
            .map((answer) => answer.trim())
            .where((answer) => answer.isNotEmpty)
            .toList();
    return raw.isNotEmpty ? raw : [''];
  }

  String get _displayAnswer => _acceptedAnswers.first;

  /// acceptedAnswers + distractors birleştir, karıştır
  List<String> _buildWordOptions() {
    final distractors = (widget.block.content['distractors'] as List? ?? [])
        .cast<String>()
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .cast<String>();

    // Alternatif doğru cevaplar kontrol için saklanır; seçeneklerde yalnızca
    // tek bir kanonik doğru cevap gösterilir. Aksi halde ekrandaki birden fazla
    // seçenek "doğru" olur.
    final options = <String>{_displayAnswer};
    options.addAll(distractors);

    final list = options.toList()..shuffle();
    return list;
  }

  bool _check(String input) {
    final cleaned = input.trim().toLowerCase();
    return _acceptedAnswers.any((a) => a.toLowerCase() == cleaned);
  }

  void _pick(String word) {
    if (_submitted && _isCorrect) return;
    final correct = _check(word);
    setState(() {
      _selected = word;
      _submitted = true;
      _isCorrect = correct;
      _attempts++;
      if (!correct) _showHint = true;
    });
    if (correct) {
      widget.onAnswered();
    } else {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          setState(() {
            _submitted = false;
            _selected = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.block.content;
    final explanation = c['explanation'] as String? ?? '';
    final hint = c['hint'] as String? ?? '';

    return _quizShell(
      color: widget.color,
      typeLabel: '✏️  Boşluk Doldur',
      attempts: _attempts,
      submitted: _submitted,
      isCorrect: _isCorrect,
      children: [
        const SizedBox(height: 12),
        // Soru metni — seçilen kelimeyle boşluk dolup dolmadığını göster
        ..._buildQuestion(
          context,
          c['question_text'] ?? c['question'] ?? '',
          widget.color,
          _selected,
          _submitted,
          _isCorrect,
        ),
        const SizedBox(height: 16),
        // Talimat
        if (!(_submitted && _isCorrect))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Boşluğa uygun kelimeyi seç:',
              style: TextStyle(
                fontSize: 11,
                color: widget.color.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        // Kelime seçenekleri
        if (!(_submitted && _isCorrect))
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _wordOptions.map((word) {
              final isSelected = _selected == word;
              final showCorrect = _submitted && isSelected && _isCorrect;
              final showWrong = _submitted && isSelected && !_isCorrect;
              return GestureDetector(
                onTap: () => _pick(word),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: showCorrect
                        ? const Color(0xFFECFDF5)
                        : showWrong
                        ? const Color(0xFFFFF0F0)
                        : isSelected
                        ? widget.color.withOpacity(0.12)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: showCorrect
                          ? _C.correct
                          : showWrong
                          ? _C.wrong
                          : isSelected
                          ? widget.color
                          : const Color(0xFFD1D5DB),
                      width: isSelected ? 2 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    word,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: showCorrect
                          ? _C.correct
                          : showWrong
                          ? _C.wrong
                          : isSelected
                          ? widget.color
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        if (hint.isNotEmpty && !(_submitted && _isCorrect))
          _OrderingHintBox(hint: hint),
        if (_submitted)
          _FeedbackBox(isCorrect: _isCorrect, explanation: explanation),
      ],
    );
  }

  List<Widget> _buildQuestion(
    BuildContext context,
    String raw,
    Color color,
    String? selected,
    bool submitted,
    bool isCorrect,
  ) {
    final lines = raw.split('\n');
    return lines.map((line) {
      if (line.trim().isEmpty) return const SizedBox(height: 4);
      if (line.contains('________')) {
        final parts = line.split('________');
        // Boşlukta gösterilecek içerik
        final filledText = selected ?? '  ?  ';
        final fillColor = submitted && isCorrect
            ? _C.correct
            : submitted && !isCorrect
            ? _C.wrong
            : selected != null
            ? color
            : color;
        final fillBg = submitted && isCorrect
            ? const Color(0xFFECFDF5)
            : submitted && !isCorrect
            ? const Color(0xFFFFF0F0)
            : color.withOpacity(0.1);

        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: RichText(
            textScaler: MediaQuery.textScalerOf(context),
            text: TextSpan(
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                height: 1.6,
              ),
              children: [
                TextSpan(text: parts[0]),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: fillBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: fillColor, width: 2),
                    ),
                    child: Text(
                      filledText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: fillColor,
                      ),
                    ),
                  ),
                ),
                if (parts.length > 1) TextSpan(text: parts[1]),
              ],
            ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          line,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            height: 1.6,
          ),
        ),
      );
    }).toList();
  }
}

// ═══════════════════════════════════════════════════════
// EŞLEŞTİRME KARTI
// ═══════════════════════════════════════════════════════

class _MatchingCard extends StatefulWidget {
  final LessonBlock block;
  final Color color;
  final VoidCallback onAnswered;
  final bool done;
  const _MatchingCard({
    super.key,
    required this.block,
    required this.color,
    required this.onAnswered,
    required this.done,
  });
  @override
  State<_MatchingCard> createState() => _MatchingCardState();
}

class _MatchingCardState extends State<_MatchingCard> {
  late List<Map<String, dynamic>> _pairs;
  late List<String> _shuffledRights;
  String? _selectedLeft;
  String? _selectedRight;
  // Onaylanmış doğru eşleşmeler: leftId → rightText
  final Map<String, String> _confirmed = {};
  // Anlık yanlış flash için: leftId → true (kırmızı göster)
  final Set<String> _wrongFlash = {};
  final Set<String> _wrongRightFlash = {};
  int _attempts = 0;
  bool _showHint = false;
  bool _allCorrect = false;

  @override
  void initState() {
    super.initState();
    _pairs = (widget.block.content['pairs'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    _shuffledRights = _pairs.map((p) => p['right'] as String).toList()
      ..shuffle();
    if (widget.done) {
      _allCorrect = true;
      for (final p in _pairs) {
        _confirmed[p['id']] = p['right'];
      }
    }
  }

  void _tapLeft(String pairId) {
    if (_allCorrect || _confirmed.containsKey(pairId)) return;
    setState(() {
      _selectedLeft = _selectedLeft == pairId ? null : pairId;
      if (_selectedLeft != null && _selectedRight != null) _tryMatch();
    });
  }

  void _tapRight(String rightText) {
    if (_allCorrect) return;
    // Zaten onaylanmış bir sağ değeri tıklanamaz
    if (_confirmed.values.contains(rightText)) return;
    setState(() {
      _selectedRight = _selectedRight == rightText ? null : rightText;
      if (_selectedLeft != null && _selectedRight != null) _tryMatch();
    });
  }

  void _tryMatch() {
    final leftId = _selectedLeft!;
    final rightText = _selectedRight!;
    _selectedLeft = null;
    _selectedRight = null;

    final correctRight =
        _pairs.firstWhere((p) => p['id'] == leftId)['right'] as String;
    _attempts++;

    if (rightText == correctRight) {
      // Doğru — onayla
      _confirmed[leftId] = rightText;
      if (_confirmed.length == _pairs.length) {
        _allCorrect = true;
        widget.onAnswered();
      }
    } else {
      // Yanlış — kırmızı flash, sonra temizle
      _wrongFlash.add(leftId);
      _wrongRightFlash.add(rightText);
      _showHint = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _wrongFlash.remove(leftId);
            _wrongRightFlash.remove(rightText);
          });
        }
      });
    }
  }

  Color _leftColor(String pairId) {
    if (_wrongFlash.contains(pairId)) return _C.wrong;
    if (_confirmed.containsKey(pairId)) return _C.correct;
    if (_selectedLeft == pairId) return widget.color;
    return const Color(0xFFE5E7EB);
  }

  Color _rightColor(String text) {
    if (_confirmed.values.contains(text)) return _C.correct;
    if (_wrongRightFlash.contains(text)) return _C.wrong;
    if (_selectedRight == text) return widget.color;
    return const Color(0xFFE5E7EB);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.block.content;
    final explanation = c['explanation'] as String? ?? '';
    final hint = c['hint'] as String? ?? '';

    return _quizShell(
      color: widget.color,
      typeLabel: '🔗  Eşleştir',
      attempts: _attempts,
      submitted: _allCorrect,
      isCorrect: _allCorrect,
      children: [
        const SizedBox(height: 12),
        Text(
          c['question'] ?? '',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        // Talimat
        if (!_allCorrect)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Sol ve sağdan birer seçenek tıklayarak eşleştir.',
              style: TextStyle(
                fontSize: 11,
                color: widget.color.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        // Sol — Sağ tablo
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sol sütun
            Expanded(
              child: Column(
                children: _pairs.map((p) {
                  final id = p['id'] as String;
                  final left = p['left'] as String;
                  final isConfirmed = _confirmed.containsKey(id);
                  final isWrong = _wrongFlash.contains(id);
                  final isActive = _selectedLeft == id;
                  return GestureDetector(
                    onTap: () => _tapLeft(id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isConfirmed
                            ? const Color(0xFFECFDF5)
                            : isWrong
                            ? const Color(0xFFFFF0F0)
                            : isActive
                            ? widget.color.withOpacity(0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _leftColor(id),
                          width: isConfirmed || isWrong ? 2 : 1.5,
                        ),
                      ),
                      child: Text(
                        left,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isConfirmed
                              ? _C.correct
                              : isWrong
                              ? _C.wrong
                              : isActive
                              ? widget.color
                              : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Ok simgesi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: _pairs
                    .map(
                      (_) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          height: 40,
                          child: Center(
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: widget.color.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            // Sağ sütun (karıştırılmış)
            Expanded(
              child: Column(
                children: _shuffledRights.map((right) {
                  final isConfirmedRight = _confirmed.values.contains(right);
                  final isActive = _selectedRight == right;
                  return GestureDetector(
                    onTap: () => _tapRight(right),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isConfirmedRight
                            ? const Color(0xFFECFDF5)
                            : _wrongRightFlash.contains(right)
                            ? const Color(0xFFFFF0F0)
                            : isActive
                            ? widget.color.withOpacity(0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _rightColor(right),
                          width: isConfirmedRight ? 2 : 1.5,
                        ),
                      ),
                      child: Text(
                        right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isConfirmedRight
                              ? _C.correct
                              : _wrongRightFlash.contains(right)
                              ? _C.wrong
                              : isActive
                              ? widget.color
                              : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        if (hint.isNotEmpty && !_allCorrect) _OrderingHintBox(hint: hint),
        if (_allCorrect)
          _FeedbackBox(isCorrect: true, explanation: explanation),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// SIRALAMA KARTI (ordering)
// ═══════════════════════════════════════════════════════

class _OrderingCard extends StatefulWidget {
  final LessonBlock block;
  final Color color;
  final VoidCallback onAnswered;
  final bool done;
  const _OrderingCard({
    super.key,
    required this.block,
    required this.color,
    required this.onAnswered,
    required this.done,
  });
  @override
  State<_OrderingCard> createState() => _OrderingCardState();
}

class _OrderingCardState extends State<_OrderingCard> {
  late List<Map<String, dynamic>> _items;
  bool _submitted = false;
  bool _isCorrect = false;
  int _attempts = 0;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _items = List<Map<String, dynamic>>.from(
      (widget.block.content['items'] as List? ?? [])
          .cast<Map<String, dynamic>>(),
    );
    if (!widget.done) _items.shuffle();
    if (widget.done) {
      _submitted = true;
      _isCorrect = true;
    }
  }

  List<String> get _correctOrder =>
      (widget.block.content['correctOrder'] as List? ?? []).cast<String>();

  bool _checkOrder() {
    final current = _items.map((i) => i['id'] as String).toList();
    for (int i = 0; i < _correctOrder.length; i++) {
      if (i >= current.length || current[i] != _correctOrder[i]) return false;
    }
    return true;
  }

  // Her item'ın doğru pozisyonda olup olmadığını döndürür
  bool _isItemCorrect(int idx) {
    if (!_submitted) return false;
    final itemId = _items[idx]['id'] as String;
    return idx < _correctOrder.length && _correctOrder[idx] == itemId;
  }

  void _submit() {
    final correct = _checkOrder();
    setState(() {
      _submitted = true;
      _isCorrect = correct;
      _attempts++;
      _showHint = !correct; // yanlışta hemen ipucunu göster
    });
    if (correct) {
      widget.onAnswered();
    } else {
      // Kırmızı/yeşil göster, shuffle YOK — kullanıcı kendi düzeltsin
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _submitted = false;
            // _items karıştırılmıyor, sıralama yerinde kalıyor
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.block.content;
    final explanation = c['explanation'] as String? ?? '';
    final hint = c['hint'] as String? ?? '';

    return _quizShell(
      color: widget.color,
      typeLabel: '↕️  Sırala',
      attempts: _attempts,
      submitted: _submitted,
      isCorrect: _isCorrect,
      children: [
        const SizedBox(height: 12),
        Text(
          c['question'] ?? '',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 6),
        if (!(_submitted && _isCorrect))
          Text(
            'Kartları sürükleyerek doğru sıraya diz.',
            style: TextStyle(
              fontSize: 11,
              color: widget.color.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        const SizedBox(height: 12),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: _submitted
              ? (_, __) {}
              : (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _items.removeAt(oldIndex);
                    _items.insert(newIndex, item);
                  });
                },
          children: _items.asMap().entries.map((e) {
            final idx = e.key;
            final item = e.value;
            final itemCorrect = _isItemCorrect(idx);
            final itemColor = _submitted
                ? (itemCorrect ? _C.correct : _C.wrong)
                : widget.color.withOpacity(0.35);
            final itemBg = _submitted
                ? (itemCorrect
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFFF0F0))
                : Colors.white;
            return Container(
              key: ValueKey(item['id']),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: itemBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: itemColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _submitted
                          ? itemColor.withOpacity(0.15)
                          : widget.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _submitted ? itemColor : widget.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['text'] ?? '',
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF374151),
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (!(_submitted && _isCorrect))
                    Icon(
                      Icons.drag_handle_rounded,
                      color: widget.color.withOpacity(0.4),
                      size: 20,
                    ),
                ],
              ),
            );
          }).toList(),
        ),
        // İpucu ordering'de her zaman görünür (baştan açık, belirgin)
        if (hint.isNotEmpty && !(_submitted && _isCorrect))
          _OrderingHintBox(hint: hint),
        if (!(_submitted && _isCorrect)) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: !_submitted ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                elevation: 0,
              ),
              child: const Text(
                'Sıralamayı Kontrol Et',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
        if (_submitted)
          _FeedbackBox(isCorrect: _isCorrect, explanation: explanation),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// DOĞRU / YANLIŞ KARTI (true_false)
// ═══════════════════════════════════════════════════════

class _TrueFalseCard extends StatefulWidget {
  final LessonBlock block;
  final Color color;
  final VoidCallback onAnswered;
  final bool done;
  const _TrueFalseCard({
    super.key,
    required this.block,
    required this.color,
    required this.onAnswered,
    required this.done,
  });
  @override
  State<_TrueFalseCard> createState() => _TrueFalseCardState();
}

class _TrueFalseCardState extends State<_TrueFalseCard>
    with SingleTickerProviderStateMixin {
  bool? _selected;
  bool _submitted = false;
  bool _isCorrect = false;
  int _attempts = 0;
  bool _showHint = false;

  late AnimationController _shake;
  late Animation<double> _shakeAnim;

  bool get _correctAnswer =>
      widget.block.content['correctAnswer'] as bool? ?? true;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _shake, curve: Curves.elasticIn));
    if (widget.done) {
      _submitted = true;
      _isCorrect = true;
      _selected = _correctAnswer;
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selected == null) return;
    final correct = _selected == _correctAnswer;
    setState(() {
      _submitted = true;
      _isCorrect = correct;
      _attempts++;
    });
    if (correct) {
      widget.onAnswered();
    } else {
      _shake.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          setState(() {
            _submitted = false;
            _selected = null;
            _showHint = true;
          });
          _shake.reset();
        }
      });
    }
  }

  void _handleAnswerTap(bool value) {
    if (_submitted) return;
    setState(() => _selected = value);
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.block.content;
    final statement =
        c['statement'] as String? ?? c['question'] as String? ?? '';
    final explanation = c['explanation'] as String? ?? '';
    final hint = c['hint'] as String? ?? '';

    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (ctx, child) {
        final dx = _submitted && !_isCorrect
            ? (_shakeAnim.value * 10 * ((_attempts % 2 == 0) ? 1 : -1)).clamp(
                -12.0,
                12.0,
              )
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: _quizShell(
        color: widget.color,
        typeLabel: '⚖️  Doğru / Yanlış',
        attempts: _attempts,
        submitted: _submitted,
        isCorrect: _isCorrect,
        children: [
          const SizedBox(height: 12),
          // İfade kutusu
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.color.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Text(
              statement,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Doğru / Yanlış butonları
          Row(
            children: [
              Expanded(
                child: _TFButton(
                  label: '✅  Doğru',
                  selected: _selected == true,
                  correct: _submitted ? (_correctAnswer == true) : null,
                  isCorrectAnswer: _isCorrect,
                  submitted: _submitted,
                  color: widget.color,
                  onTap: _submitted ? null : () => _handleAnswerTap(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TFButton(
                  label: '❌  Yanlış',
                  selected: _selected == false,
                  correct: _submitted ? (_correctAnswer == false) : null,
                  isCorrectAnswer: _isCorrect,
                  submitted: _submitted,
                  color: widget.color,
                  onTap: _submitted ? null : () => _handleAnswerTap(false),
                ),
              ),
            ],
          ),
          _HintBox(
            hint: hint,
            visible: _showHint && _attempts > 0 && !_isCorrect,
          ),
          if (_submitted)
            _FeedbackBox(isCorrect: _isCorrect, explanation: explanation),
        ],
      ),
    );
  }
}

class _TFButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool? correct; // null = henüz submit yok
  final bool isCorrectAnswer;
  final bool submitted;
  final Color color;
  final VoidCallback? onTap;

  const _TFButton({
    required this.label,
    required this.selected,
    required this.correct,
    required this.isCorrectAnswer,
    required this.submitted,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.white;
    Color border = const Color(0xFFE5E7EB);
    if (selected && !submitted) {
      bg = color.withOpacity(0.1);
      border = color;
    }
    if (submitted && isCorrectAnswer && correct == true) {
      bg = const Color(0xFFECFDF5);
      border = _C.correct;
    }
    if (submitted && selected && correct == false) {
      bg = const Color(0xFFFFF0F0);
      border = _C.wrong;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: selected ? color : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// BÖLÜM BANNER
// ═══════════════════════════════════════════════════════

class _SectionBanner extends StatelessWidget {
  final LessonSection section;
  final Color color;
  final bool isQuiz;

  const _SectionBanner({
    required this.section,
    required this.color,
    required this.isQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            isQuiz ? '✏️' : section.icon,
            style: const TextStyle(fontSize: 34),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bölüm ${section.order}  •  ${isQuiz ? "Pekiştirme" : "İçerik"}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// BÜYÜK BUTON
// ═══════════════════════════════════════════════════════

class _BigButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BigButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: color.withOpacity(0.4),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// HEPSİ DOĞRU BANNER
// ═══════════════════════════════════════════════════════

class _AllCorrectBanner extends StatelessWidget {
  final Color color;
  const _AllCorrectBanner({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.correct.withOpacity(0.4)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎉', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text(
            'Tüm soruları doğru yaptın!',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _C.correct,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnsupportedBlockCard extends StatelessWidget {
  final String blockType;
  final Color color;

  const _UnsupportedBlockCard({required this.blockType, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.hint.withOpacity(0.35), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Desteklenmeyen içerik bloğu',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"$blockType" tipi bu görünümde henüz işlenmiyor.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════
// MARKDOWN KARTI
// ═══════════════════════════════════════════════════════

class _MarkdownCard extends StatelessWidget {
  final String body;
  final Color color;

  const _MarkdownCard({required this.body, required this.color});

  List<Widget> _parse(BuildContext context, String raw) {
    final widgets = <Widget>[];
    final lines = raw.split('\n');
    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      if (line.contains('|') && line.trim().startsWith('|')) {
        final tableLines = <String>[];
        while (i < lines.length &&
            lines[i].contains('|') &&
            lines[i].trim().isNotEmpty) {
          tableLines.add(lines[i]);
          i++;
        }
        widgets.add(_table(context, tableLines));
        continue;
      }
      if (line.startsWith('## ')) {
        widgets.add(_h(line.substring(3), 16));
      } else if (line.startsWith('### ')) {
        widgets.add(_h(line.substring(4), 14));
      } else if (line.startsWith('> ')) {
        widgets.add(_quote(context, line.substring(2)));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(_bullet(context, line.substring(2)));
      } else if (RegExp(r'^\d+\. ').hasMatch(line)) {
        widgets.add(
          _bullet(context, line.replaceFirst(RegExp(r'^\d+\. '), '')),
        );
      } else if (line.startsWith('---')) {
        widgets.add(
          Divider(height: 20, color: color.withOpacity(0.2), thickness: 1),
        );
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 4));
      } else {
        widgets.add(_rich(context, line));
      }
      i++;
    }
    return widgets;
  }

  Widget _h(String t, double size) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 4),
    child: Text(
      t,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color,
      ),
    ),
  );

  Widget _quote(BuildContext context, String t) => Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border(left: BorderSide(color: color, width: 4)),
    ),
    child: _rich(
      context,
      t,
      style: TextStyle(
        fontSize: 13,
        fontStyle: FontStyle.italic,
        color: color.withAlpha(220),
        height: 1.5,
      ),
    ),
  );

  Widget _bullet(BuildContext context, String t) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•',
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _rich(context, t)),
      ],
    ),
  );

  Widget _table(BuildContext context, List<String> tableLines) {
    final dataLines = tableLines
        .where((l) => !RegExp(r'^\s*\|[\s\-|]+\|\s*$').hasMatch(l))
        .toList();
    if (dataLines.isEmpty) return const SizedBox.shrink();
    final rows = dataLines.map((l) {
      final cells = l.split('|').map((c) => c.trim()).toList();
      if (cells.isNotEmpty && cells.first.isEmpty) cells.removeAt(0);
      if (cells.isNotEmpty && cells.last.isEmpty) cells.removeLast();
      return cells;
    }).toList();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        color: Colors.white,
      ),
      clipBehavior: Clip.hardEdge,
      child: Table(
        border: TableBorder(
          horizontalInside: BorderSide(
            color: color.withOpacity(0.12),
            width: 1,
          ),
          verticalInside: BorderSide(color: color.withOpacity(0.08), width: 1),
        ),
        defaultColumnWidth: const FlexColumnWidth(),
        children: rows.asMap().entries.map((e) {
          final isHeader = e.key == 0;
          return TableRow(
            decoration: BoxDecoration(
              color: isHeader ? color.withOpacity(0.1) : Colors.transparent,
            ),
            children: e.value
                .map(
                  (cell) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: _rich(
                      context,
                      cell,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isHeader
                            ? FontWeight.w800
                            : FontWeight.w400,
                        color: isHeader ? color : const Color(0xFF374151),
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _rich(BuildContext context, String t, {TextStyle? style}) {
    final base =
        style ??
        const TextStyle(fontSize: 13.5, color: Color(0xFF374151), height: 1.6);
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|`(.+?)`');
    int last = 0;
    for (final m in regex.allMatches(t)) {
      if (m.start > last) {
        spans.add(TextSpan(text: t.substring(last, m.start), style: base));
      }
      if (m.group(1) != null) {
        spans.add(
          TextSpan(
            text: m.group(1),
            style: base.copyWith(fontWeight: FontWeight.w800),
          ),
        );
      } else if (m.group(2) != null) {
        spans.add(
          TextSpan(
            text: m.group(2),
            style: base.copyWith(
              fontFamily: 'monospace',
              backgroundColor: const Color(0xFFF3F4F6),
              color: const Color(0xFFDC2626),
            ),
          ),
        );
      }
      last = m.end;
    }
    if (last < t.length) {
      spans.add(TextSpan(text: t.substring(last), style: base));
    }
    return RichText(
      textScaler: MediaQuery.textScalerOf(context),
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _parse(context, body),
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final Map<String, dynamic> content;
  final Color color;

  const _ImageCard({required this.content, required this.color});

  @override
  Widget build(BuildContext context) {
    final svgCode = (content['svgCode'] as String? ?? '').trim();
    final imageUrl = (content['imageUrl'] as String? ?? '').trim();
    final caption = (content['caption'] as String? ?? '').trim();
    final altText = (content['altText'] as String? ?? '').trim();
    final hasSvg = svgCode.startsWith('<svg');
    final hasImage =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    if (!hasSvg && !hasImage) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: hasSvg
                  ? SvgPicture.string(svgCode, fit: BoxFit.contain)
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
            ),
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              caption,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                height: 1.45,
              ),
            ),
          ],
          if (altText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              altText,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// KAVRAM YANILGISI KARTI
// ═══════════════════════════════════════════════════════

class _MisconceptionCard extends StatefulWidget {
  final Map<String, dynamic> content;
  final Color color;
  const _MisconceptionCard({required this.content, required this.color});

  @override
  State<_MisconceptionCard> createState() => _MisconceptionCardState();
}

class _MisconceptionCardState extends State<_MisconceptionCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final wrong = widget.content['wrong'] ?? '';
    final correct = widget.content['correct'] ?? '';
    final tip = widget.content['tip'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCA28), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('⚠️', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text(
                'Kavram Yanılgısı',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7B5800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Text('❌', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    wrong,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF991B1B),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _revealed = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _revealed
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _revealed
                  ? Row(
                      children: [
                        const Text('✅', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            correct,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF065F46),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Text(
                        '👆  Doğrusunu görmek için dokun',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ),
          if (_revealed && tip != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7B5800),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// BİTİŞ EKRANI
// ═══════════════════════════════════════════════════════

class _FinishScreen extends StatelessWidget {
  final LessonModule module;
  final VoidCallback onRestart;
  const _FinishScreen({required this.module, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎊', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 16),
                const Text(
                  'Tebrikler!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${module.title}\n\nkonusunu başarıyla tamamladın!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                _BigButton(
                  label: '🔄  Baştan Başla',
                  color: _C.get(0),
                  onTap: onRestart,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
