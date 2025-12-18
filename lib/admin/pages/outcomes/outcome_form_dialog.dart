// lib/admin/pages/outcomes/outcome_form_dialog.dart

import 'package:egitim_uygulamasi/models/outcome_model.dart';
import 'package:egitim_uygulamasi/services/outcome_service.dart';
import 'package:flutter/material.dart';

class OutcomeFormDialog extends StatefulWidget {
  final Outcome? outcome;
  final int topicId;
  final VoidCallback onSave;

  const OutcomeFormDialog({
    super.key,
    this.outcome,
    required this.topicId,
    required this.onSave,
  });

  @override
  State<OutcomeFormDialog> createState() => _OutcomeFormDialogState();
}

class _OutcomeFormDialogState extends State<OutcomeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _outcomeService = OutcomeService();
  late TextEditingController _textController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.outcome?.text ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (widget.outcome == null) {
          await _outcomeService.createOutcome(
            _textController.text,
            widget.topicId,
          );
        } else {
          await _outcomeService.updateOutcome(
            widget.outcome!.id,
            _textController.text,
          );
        }
        widget.onSave();
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.outcome == null ? 'Yeni Kazanım Ekle' : 'Kazanımı Düzenle',
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _textController,
          decoration: const InputDecoration(labelText: 'Kazanım Metni'),
          maxLines: 5, // Çok satırlı metin alanı
          validator: (value) =>
              value!.isEmpty ? 'Kazanım metni boş olamaz.' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const CircularProgressIndicator(strokeWidth: 2)
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}
