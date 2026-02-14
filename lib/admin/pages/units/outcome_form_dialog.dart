import 'package:egitim_uygulamasi/main.dart';
import 'package:egitim_uygulamasi/models/grade_model.dart';
import 'package:egitim_uygulamasi/models/lesson_model.dart';
import 'package:egitim_uygulamasi/models/unit_model.dart';
import 'package:egitim_uygulamasi/services/grade_service.dart';
import 'package:flutter/material.dart';

class UnitOutcomeFormPage extends StatefulWidget {
  final Map<String, dynamic>? outcome; // Düzenleme için mevcut veri (opsiyonel)
  final VoidCallback onSave;

  const UnitOutcomeFormPage({super.key, this.outcome, required this.onSave});

  @override
  State<UnitOutcomeFormPage> createState() => _UnitOutcomeFormPageState();
}

class _UnitOutcomeFormPageState extends State<UnitOutcomeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _gradeService = GradeService();

  // Controller'lar
  final _topicController = TextEditingController();
  final _contentController = TextEditingController();
  final _outcomeDescriptionController = TextEditingController();
  final _weekController = TextEditingController(text: '1');

  // Seçim State'leri
  int? _selectedGradeId;
  int? _selectedLessonId;
  int? _selectedUnitId;

  // Veri Listeleri
  late Future<List<Grade>> _gradesFuture;
  List<Lesson> _lessons = [];
  List<Unit> _units = [];
  List<Map<String, dynamic>> _availableTopics = []; // Autocomplete için
  List<Map<String, dynamic>> _unitDetails = []; // Liste görünümü için

  bool _isLoading = false;
  bool _isLessonsLoading = false;
  bool _isUnitsLoading = false;
  bool _isTopicsLoading = false;
  bool _isListLoading = false;

  @override
  void initState() {
    super.initState();
    _gradesFuture = _gradeService.getGrades();

    // Eğer düzenleme modundaysak mevcut verileri doldurabiliriz
    if (widget.outcome != null) {
      _outcomeDescriptionController.text = widget.outcome!['description'] ?? '';
      // Not: Düzenleme modunda hiyerarşiyi (Sınıf->Ders->Ünite) doldurmak için
      // ek sorgular gerekebilir, şimdilik basit ekleme senaryosuna odaklanıyoruz.
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _contentController.dispose();
    _outcomeDescriptionController.dispose();
    _weekController.dispose();
    super.dispose();
  }

  // --- Veri Yükleme Fonksiyonları ---

  Future<void> _loadLessonsForGrade(int gradeId) async {
    setState(() {
      _isLessonsLoading = true;
      _lessons = [];
      _selectedLessonId = null;
      _units = [];
      _selectedUnitId = null;
      _availableTopics = [];
      _topicController.clear();
    });

    try {
      final response = await supabase.rpc(
        'get_lessons_by_grade',
        params: {'gid': gradeId},
      );
      setState(() {
        _lessons = (response as List).map((e) => Lesson.fromMap(e)).toList();
      });
    } catch (e) {
      debugPrint('Dersler yüklenirken hata: $e');
    } finally {
      if (mounted) setState(() => _isLessonsLoading = false);
    }
  }

  Future<void> _loadUnitsForLesson(int lessonId) async {
    setState(() {
      _isUnitsLoading = true;
      _units = [];
      _selectedUnitId = null;
      _availableTopics = [];
      _topicController.clear();
    });

    try {
      // Grade ID'ye de ihtiyacımız var, state'den alıyoruz
      if (_selectedGradeId == null) return;

      final response = await supabase.rpc(
        'get_units_by_lesson_and_grade',
        params: {'lid': lessonId, 'gid': _selectedGradeId},
      );
      setState(() {
        _units = (response as List).map((e) => Unit.fromMap(e)).toList();
      });
    } catch (e) {
      debugPrint('Üniteler yüklenirken hata: $e');
    } finally {
      if (mounted) setState(() => _isUnitsLoading = false);
    }
  }

  Future<void> _loadUnitData(int unitId) async {
    setState(() {
      _isTopicsLoading = true;
      _isListLoading = true;
      _availableTopics = [];
      _unitDetails = [];
      _topicController.clear();
    });

    try {
      // 1. Autocomplete için konuları çek
      final topicsResponse = await supabase
          .from('topics')
          .select('id, title')
          .eq('unit_id', unitId)
          .order('title');

      // 2. Liste görünümü için detaylı verileri çek (Topics -> Contents, Videos, Outcomes)
      final detailsResponse = await supabase
          .from('topics')
          .select('*, topic_contents(*), unit_videos(*), outcomes(*)')
          .eq('unit_id', unitId)
          .order('title');

      setState(() {
        _availableTopics = List<Map<String, dynamic>>.from(topicsResponse);
        _unitDetails = List<Map<String, dynamic>>.from(detailsResponse);
      });
    } catch (e) {
      debugPrint('Ünite verileri yüklenirken hata: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isTopicsLoading = false;
          _isListLoading = false;
        });
      }
    }
  }

  // --- ID Çözümleme ve Kayıt Mantığı (Core Logic) ---

  /// Topic: Varsa ID'sini döndür, yoksa oluştur ve yeni ID'yi döndür.
  Future<int> _resolveTopicId(int unitId, String title) async {
    final trimmedTitle = title.trim();

    // 1. Önce var mı diye kontrol et
    final existing = await supabase
        .from('topics')
        .select('id')
        .eq('unit_id', unitId)
        .ilike('title', trimmedTitle) // Case-insensitive kontrol
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as int;
    }

    // 2. Yoksa oluştur
    final newRecord = await supabase
        .from('topics')
        .insert({'unit_id': unitId, 'title': trimmedTitle})
        .select('id')
        .single();

    return newRecord['id'] as int;
  }

  /// Topic Content: Varsa ID'sini döndür, yoksa oluştur ve yeni ID'yi döndür.
  Future<int> _resolveContentId(
    int topicId,
    String contentText,
    int week,
  ) async {
    final lines = contentText.trim().split('\n');
    String title = '';
    String content;

    if (lines.isNotEmpty && lines.first.startsWith('#')) {
      final header = lines.first.substring(1).trim();
      final parts = header.split(' ');
      title = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      content = lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';
    } else {
      content = contentText.trim();
      title = content.length > 50 ? '${content.substring(0, 47)}...' : content;
    }
    
    if (title.isEmpty) {
      title = content.length > 50 ? '${content.substring(0, 47)}...' : content;
    }


    // 1. Bu topic altında bu başlık veya içerik var mı?
    final existing = await supabase
        .from('topic_contents')
        .select('id')
        .eq('topic_id', topicId)
        .or('title.eq.$title,content.eq.$content')
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as int;
    }

    // 2. Yoksa oluştur ve haftasını ata
    final newRecord = await supabase
        .from('topic_contents')
        .insert({
          'topic_id': topicId,
          'title': title,
          'content': content,
        })
        .select('id')
        .single();
    
    final newContentId = newRecord['id'] as int;

    // Haftayı ayrı tabloya ekle
    await supabase.from('topic_content_weeks').insert({
      'topic_content_id': newContentId,
      'start_week': week,
      'end_week': week, // Bu formda tek hafta olduğu için başlangıç ve bitiş aynı
    });

    return newContentId;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUnitId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir ünite seçin.')));
      return;
    }

    setState(() => _isLoading = true);

    final week = int.tryParse(_weekController.text.trim()) ?? 1;

    try {
      // 1. Adım: Topic ID'yi çöz (Bul veya Oluştur)
      final topicId = await _resolveTopicId(
        _selectedUnitId!,
        _topicController.text,
      );

      // 2. Adım: Topic Content ID'yi çöz (Bul veya Oluştur)
      await _resolveContentId(
        topicId,
        _contentController.text,
        week,
      );

      // 3. Adım: Outcome (Kazanım) Oluştur
      await supabase.from('outcomes').insert({
        'topic_id': topicId,
        'description': _outcomeDescriptionController.text.trim(),
        'curriculum_week': week,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kazanım ve ilişkili veriler başarıyla kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSave();
      }

      // Listeyi güncelle
      if (_selectedUnitId != null) _loadUnitData(_selectedUnitId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kazanım Yönetimi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Yeni Kazanım Ekle',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  // --- Hiyerarşi Seçimi ---
                  FutureBuilder<List<Grade>>(
                    future: _gradesFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator();
                      }
                      return DropdownButtonFormField<int>(
                        initialValue: _selectedGradeId,
                        decoration: const InputDecoration(labelText: 'Sınıf'),
                        items: snapshot.data!
                            .map(
                              (g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(g.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedGradeId = val);
                            _loadLessonsForGrade(val);
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedLessonId,
                    decoration: const InputDecoration(labelText: 'Ders'),
                    items: _lessons
                        .map(
                          (l) => DropdownMenuItem(
                            value: l.id,
                            child: Text(l.name),
                          ),
                        )
                        .toList(),
                    onChanged: _lessons.isEmpty
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() => _selectedLessonId = val);
                              _loadUnitsForLesson(val);
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedUnitId,
                    decoration: const InputDecoration(labelText: 'Ünite'),
                    items: _units
                        .map(
                          (u) => DropdownMenuItem(
                            value: u.id,
                            child: Text(u.title),
                          ),
                        )
                        .toList(),
                    onChanged: _units.isEmpty
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() => _selectedUnitId = val);
                              _loadUnitData(val);
                            }
                          },
                  ),
                  const Divider(height: 32),

                  // --- 0) Hafta (Week) ---
                  TextFormField(
                    controller: _weekController,
                    decoration: const InputDecoration(
                      labelText: 'Hafta (Sayı)',
                      hintText: 'Örn: 1',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Hafta giriniz'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // --- 1) Topic (Autocomplete) ---
                  Autocomplete<Map<String, dynamic>>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const [];
                      return _availableTopics.where((topic) {
                        return topic['title'].toString().toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        );
                      });
                    },
                    displayStringForOption: (option) => option['title'],
                    fieldViewBuilder:
                        (context, controller, focusNode, onEditingComplete) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            onEditingComplete: onEditingComplete,
                            decoration: const InputDecoration(
                              labelText: 'Konu (Topic)',
                              hintText: 'Listeden seçin veya yeni yazın',
                              suffixIcon: Icon(Icons.search),
                            ),
                            validator: (val) =>
                                val!.isEmpty ? 'Konu boş olamaz' : null,
                            onChanged: (val) => _topicController.text = val,
                          );
                        },
                    onSelected: (Map<String, dynamic> selection) {
                      _topicController.text = selection['title'];
                    },
                  ),

                  const SizedBox(height: 16),

                  // --- 2) Topic Content (Simple Multiline) ---
                  TextFormField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: 'Konu İçeriği / Başlığı',
                      hintText: 'İçerik yoksa oluşturulacaktır',
                      alignLabelWithHint: true,
                    ),
                    maxLines: null,
                    minLines: 3,
                    keyboardType: TextInputType.multiline,
                    validator: (val) =>
                        val!.isEmpty ? 'İçerik boş olamaz' : null,
                  ),

                  const SizedBox(height: 16),

                  // --- 3) Outcome Description ---
                  TextFormField(
                    controller: _outcomeDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Kazanım Açıklaması',
                      alignLabelWithHint: true,
                    ),
                    maxLines: null,
                    minLines: 3,
                    validator: (val) =>
                        val!.isEmpty ? 'Kazanım açıklaması giriniz' : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          // Formu temizle
                          _formKey.currentState?.reset();
                          _topicController.clear();
                          _contentController.clear();
                          _outcomeDescriptionController.clear();
                          _weekController.text = '1';
                        },
                        child: const Text('Temizle'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Kaydet'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- LİSTE GÖRÜNÜMÜ ---
            Text(
              'Mevcut İçerikler',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            if (_isListLoading)
              const Center(child: CircularProgressIndicator())
            else if (_unitDetails.isEmpty)
              const Text('Bu üniteye ait henüz içerik bulunmamaktadır.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _unitDetails.length,
                itemBuilder: (context, index) {
                  final topic = _unitDetails[index];
                  final contents =
                      topic['topic_contents'] as List<dynamic>? ?? [];
                  final videos = topic['unit_videos'] as List<dynamic>? ?? [];
                  final outcomes = topic['outcomes'] as List<dynamic>? ?? [];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      title: Text(topic['title'] ?? 'Başlıksız Konu'),
                      subtitle: Text(
                        '${contents.length} İçerik, ${videos.length} Video, ${outcomes.length} Kazanım',
                      ),
                      children: [
                        if (outcomes.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Kazanımlar:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...outcomes.map(
                            (o) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.flag, size: 16),
                              title: Text(o['description'] ?? ''),
                            ),
                          ),
                        ],
                        if (contents.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'İçerikler:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...contents.map(
                            (c) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.article, size: 16),
                              title: Text(c['title'] ?? ''),
                              subtitle: Text(
                                c['content'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        if (videos.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Videolar:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...videos.map(
                            (v) => ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.video_library,
                                size: 16,
                              ),
                              title: Text(v['title'] ?? 'Video'),
                              subtitle: Text(v['video_url'] ?? ''),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
