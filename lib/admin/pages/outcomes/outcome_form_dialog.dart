
import 'package:egitim_uygulamasi/models/topic_model.dart';
import 'package:egitim_uygulamasi/models/unit_model.dart';
import 'package:flutter/material.dart';
import 'package:egitim_uygulamasi/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SmartContentFormPage extends StatefulWidget {
  final int gradeId;
  final int lessonId;
  final VoidCallback onSave;

  const SmartContentFormPage({
    super.key,
    required this.gradeId,
    required this.lessonId,
    required this.onSave,
  });

  @override
  State<SmartContentFormPage> createState() => _SmartContentFormPageState();
}

class _SmartContentFormPageState extends State<SmartContentFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final _outcomesController = TextEditingController();
  final _multitextContentController = TextEditingController();
  final _curriculumWeekController = TextEditingController(text: '1');
  final _totalPartController = TextEditingController(text: '1');
  final _newUnitController = TextEditingController();
  final _newTopicController = TextEditingController();

  // State
  List<Unit> _units = [];
  List<Topic> _topics = [];
  final List<Map<String, TextEditingController>> _videoControllers = [];

  String _unitSelectionMode = 'existing';
  String _topicSelectionMode = 'existing';

  int? _selectedUnitId;
  int? _selectedTopicId;

  @override
  void initState() {
    super.initState();
    _fetchUnits();
    _addVideoField();
  }

  @override
  void dispose() {
    _outcomesController.dispose();
    _multitextContentController.dispose();
    _curriculumWeekController.dispose();
    _totalPartController.dispose();
    _newUnitController.dispose();
    _newTopicController.dispose();
    for (var controllers in _videoControllers) {
      controllers['title']!.dispose();
      controllers['url']!.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchUnits() async {
    try {
      final response = await supabase
          .from('units')
          .select('id, title')
          .eq('lesson_id', widget.lessonId)
          .order('order_no', ascending: true);
      
      final units = (response as List)
          .map((item) => Unit.fromMap(item as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _units = units;
        });
      }
    } catch (e) {
      _showError('Üniteler yüklenirken bir hata oluştu: $e');
    }
  }

  Future<void> _fetchTopics(int unitId) async {
    try {
      final response = await supabase
          .from('topics')
          .select('id, title')
          .eq('unit_id', unitId)
          .order('order_no', ascending: true);

      final topics = (response as List)
          .map((item) => Topic.fromMap(item as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _topics = topics;
        });
      }
    } catch (e) {
      _showError('Konular yüklenirken bir hata oluştu: $e');
    }
  }

  void _addVideoField() {
    setState(() {
      _videoControllers.add({
        'title': TextEditingController(),
        'url': TextEditingController(),
      });
    });
  }

  void _removeVideoField(int index) {
    setState(() {
      // Dispose controllers before removing
      _videoControllers[index]['title']!.dispose();
      _videoControllers[index]['url']!.dispose();
      _videoControllers.removeAt(index);
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 6)),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // --- 1. Prepare Data ---
      final curriculumWeek = int.parse(_curriculumWeekController.text.trim());

      final unitSelection = _unitSelectionMode == 'existing'
          ? {'type': 'existing', 'unit_id': _selectedUnitId}
          : {'type': 'new', 'new_unit_title': _newUnitController.text.trim()};

      final topicSelection = _topicSelectionMode == 'existing'
          ? {'type': 'existing', 'topic_id': _selectedTopicId}
          : {'type': 'new', 'new_topic_title': _newTopicController.text.trim()};

      final outcomeDescriptions = _outcomesController.text
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      
      final contentText = _multitextContentController.text.trim();

      // --- 2. Call the new, atomic RPC function ---
      await supabase.rpc('add_weekly_curriculum', params: {
        'p_grade_id': widget.gradeId,
        'p_lesson_id': widget.lessonId,
        'p_unit_selection': unitSelection,
        'p_topic_selection': topicSelection,
        'p_curriculum_week': curriculumWeek,
        'p_outcomes_text': outcomeDescriptions,
        'p_content_text': contentText,
      });

      // --- 3. Handle Success ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İçerik ve kazanımlar başarıyla oluşturuldu.'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSave();
        Navigator.of(context).pop();
      }

    } on PostgrestException catch (e) {
      // --- 4. Handle Errors with DETAIL ---
      final errorMessage = "Veritabanı Hatası: ${e.message}\n"
                           "Kod: ${e.code}\n"
                           "Detaylar: ${e.details}\n"
                           "İpucu: ${e.hint}";
      debugPrint("--- POSTGREST ERROR ---");
      debugPrint(errorMessage);
      debugPrint("-----------------------");
      _showError(errorMessage);

    } catch (e) {
      final errorMessage = "Beklenmedik bir hata oluştu: $e";
      debugPrint("--- UNEXPECTED ERROR ---");
      debugPrint(errorMessage);
      debugPrint("------------------------");
      _showError(errorMessage);

    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akıllı İçerik Oluşturucu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('1. Ünite Seçimi'),
              _buildToggle(
                mode: _unitSelectionMode,
                onChanged: (val) => setState(() {
                  _unitSelectionMode = val;
                  _selectedUnitId = null;
                  _topics = [];
                }),
              ),
              if (_unitSelectionMode == 'existing')
                _buildUnitSelector()
              else
                _buildTextField(_newUnitController, 'Yeni Ünite Başlığı'),

              if (_unitSelectionMode == 'new' || _selectedUnitId != null) ...[
                const SizedBox(height: 24),
                _buildSectionHeader('2. Konu Seçimi'),
                _buildToggle(
                  mode: _topicSelectionMode,
                  onChanged: (val) => setState(() => _topicSelectionMode = val),
                ),
                if (_topicSelectionMode == 'existing')
                  _buildTopicSelector()
                else
                  _buildTextField(_newTopicController, 'Yeni Konu Başlığı'),
              ],
              
              const SizedBox(height: 24),
              _buildSectionHeader('3. Haftalık Plan'),
              _buildTextField(_curriculumWeekController, 'Hafta Numarası', isNumeric: true),

              const SizedBox(height: 24),
              _buildSectionHeader('4. Kazanımlar'),
              _buildTextField(
                _outcomesController,
                'Kazanımları girin (her satıra bir tane)',
                maxLines: 5,
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('5. Ders İçeriği'),
               _buildTextField(
                _multitextContentController,
                'İçeriği girin...',
                maxLines: 10,
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('6. Konu Videoları (Opsiyonel)'),
              ..._buildVideoFields(),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Video Alanı Ekle'),
                onPressed: _addVideoField,
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Tümünü Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildToggle({required String mode, required ValueChanged<String> onChanged}) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'existing', label: Text('Mevcutlardan Seç')),
        ButtonSegment(value: 'new', label: Text('Yeni Oluştur')),
      ],
      selected: {mode},
      onSelectionChanged: (val) => onChanged(val.first),
    );
  }

  Widget _buildUnitSelector() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedUnitId,
      hint: const Text('Mevcut bir ünite seçin...'),
      items: _units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.title))).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedUnitId = val;
            _selectedTopicId = null; 
            _topics = [];
          });
          _fetchTopics(val);
        }
      },
      validator: (val) => val == null ? 'Lütfen bir ünite seçin.' : null,
    );
  }

  Widget _buildTopicSelector() {
    if (_topics.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: _isLoading ? const CircularProgressIndicator() : const Text('Bu üniteye ait konu bulunamadı.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _topics.map((topic) {
        return RadioListTile<int>(
          title: Text(topic.title),
          value: topic.id,
          groupValue: _selectedTopicId,
          onChanged: (val) => setState(() => _selectedTopicId = val),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    {
    int? maxLines = 1,
    bool isNumeric = false,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines != null && maxLines > 1,
        ),
        maxLines: maxLines,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.multiline,
        validator: (val) {
          if (isRequired && (val == null || val.isEmpty)) {
            return 'Bu alan boş bırakılamaz.';
          }
          return null;
        },
      ),
    );
  }

  List<Widget> _buildVideoFields() {
    return List.generate(_videoControllers.length, (index) {
      return Card(
        margin: const EdgeInsets.only(top: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildTextField(
                _videoControllers[index]['title']!,
                'Video Başlığı ${index + 1}',
                isRequired: false,
              ),
              const SizedBox(height: 8),
              _buildTextField(
                _videoControllers[index]['url']!,
                'Video URL\'si ${index + 1}',
                isRequired: false,
              ),
              if (_videoControllers.length > 1)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeVideoField(index),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
