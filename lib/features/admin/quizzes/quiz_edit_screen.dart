import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/admin_audio_recorder.dart';
import '../services/admin_repository.dart';

class QuizEditScreen extends StatefulWidget {
  final Map<String, dynamic>? question;
  final List<Map<String, dynamic>> subtopics;
  final int? preselectedSubtopicId;

  const QuizEditScreen({
    super.key,
    this.question,
    required this.subtopics,
    this.preselectedSubtopicId,
  });

  @override
  State<QuizEditScreen> createState() => _QuizEditScreenState();
}

class _QuizEditScreenState extends State<QuizEditScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _textItController;
  late TextEditingController _textEnController;
  late TextEditingController _textBnController;
  late TextEditingController _explanationItController;
  late TextEditingController _explanationEnController;
  late TextEditingController _explanationBnController;

  int? _selectedSubtopicId;
  bool _isTrue = true;
  String? _imageUrl;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isSaving = false;
  bool _isUploading = false;

  // Audio recording state
  String? _recordedAudioPath; // local temp path from AdminAudioRecorder
  String? _existingAudioUrl;  // URL already stored in DB

  bool get _isEditing => widget.question != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final q = widget.question;
    
    _textItController = TextEditingController(text: q?['text_it'] ?? '');
    _textEnController = TextEditingController(text: q?['text_en'] ?? '');
    _textBnController = TextEditingController(text: q?['text_bn'] ?? '');
    _explanationItController = TextEditingController(text: q?['explanation_it'] ?? '');
    _explanationEnController = TextEditingController(text: q?['explanation_en'] ?? '');
    _explanationBnController = TextEditingController(text: q?['explanation_bn'] ?? '');
    
    _selectedSubtopicId = q?['subtopic_id'] as int? ?? widget.preselectedSubtopicId;
    _isTrue = q?['is_true'] ?? true;
    _imageUrl = q?['image_url'];
    _existingAudioUrl = q?['explanation_audio_url'] as String?;
  }

  @override
  void dispose() {
    _textItController.dispose();
    _textEnController.dispose();
    _textBnController.dispose();
    _explanationItController.dispose();
    _explanationEnController.dispose();
    _explanationBnController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImageBytes == null || _selectedImageName == null) {
      return _imageUrl;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_$_selectedImageName';
      
      await Supabase.instance.client.storage
          .from('quiz_images')
          .uploadBinary(
            fileName,
            _selectedImageBytes!,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('quiz_images')
          .getPublicUrl(fileName);

      setState(() {
        _isUploading = false;
      });

      return publicUrl;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubtopicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.adminSelectSubtopic),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    HapticFeedback.mediumImpact();

    // Upload image if selected
    String? finalImageUrl = _imageUrl;
    if (_selectedImageBytes != null) {
      finalImageUrl = await _uploadImage();
    }

    // Upload audio if a new recording was provided
    String? finalAudioUrl = _existingAudioUrl;
    if (_recordedAudioPath != null) {
      setState(() => _isUploading = true);
      finalAudioUrl = await _adminRepository.uploadAudio(_recordedAudioPath!);
      setState(() => _isUploading = false);
      if (finalAudioUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio upload failed. Question saved without audio.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    final success = await _adminRepository.upsertQuestion(
      id: widget.question?['id'] as int?,
      subtopicId: _selectedSubtopicId!,
      textIt: _textItController.text.trim(),
      textEn: _textEnController.text.trim().isEmpty ? null : _textEnController.text.trim(),
      textBn: _textBnController.text.trim().isEmpty ? null : _textBnController.text.trim(),
      imageUrl: finalImageUrl,
      isTrue: _isTrue,
      explanationIt: _explanationItController.text.trim().isEmpty ? null : _explanationItController.text.trim(),
      explanationEn: _explanationEnController.text.trim().isEmpty ? null : _explanationEnController.text.trim(),
      explanationBn: _explanationBnController.text.trim().isEmpty ? null : _explanationBnController.text.trim(),
      explanationAudioUrl: finalAudioUrl,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.adminQuestionSaved),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.adminErrorSaving),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.adminEditQuestion : l10n.adminAddQuestion),
        actions: [
          if (_isSaving || _isUploading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(l10n.profileSaveButton),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtopic Dropdown
              _buildSectionTitle(l10n.adminSubtopic),
              DropdownButtonFormField<int>(
                initialValue: _selectedSubtopicId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                ),
                hint: Text(l10n.adminSelectSubtopic),
                items: widget.subtopics.map((subtopic) {
                  return DropdownMenuItem<int>(
                    value: subtopic['id'] as int,
                    child: Text(
                      subtopic['name_it'] ?? 'Unknown',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubtopicId = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Italian Text (Required)
              _buildSectionTitle('${l10n.adminQuestionTextIt} *'),
              TextFormField(
                controller: _textItController,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: l10n.adminEnterQuestionIt,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.adminFieldRequired;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // English Text (Optional)
              _buildSectionTitle(l10n.adminQuestionTextEn),
              TextFormField(
                controller: _textEnController,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: l10n.adminEnterQuestionEn,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),

              const SizedBox(height: 16),

              // Bangla Text (Optional)
              _buildSectionTitle(l10n.adminQuestionTextBn),
              TextFormField(
                controller: _textBnController,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: l10n.adminEnterQuestionBn,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),

              const SizedBox(height: 24),

              // Answer Toggle
              _buildSectionTitle(l10n.quizCorrectAnswer),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildAnswerOption(
                        label: l10n.quizTrue,
                        isSelected: _isTrue,
                        color: Colors.green,
                        onTap: () => setState(() => _isTrue = true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAnswerOption(
                        label: l10n.quizFalse,
                        isSelected: !_isTrue,
                        color: Colors.red,
                        onTap: () => setState(() => _isTrue = false),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Image Upload
              _buildSectionTitle(l10n.adminQuestionImage),
              _buildImageSection(),

              const SizedBox(height: 24),

              // Explanations Section
              ExpansionTile(
                title: Text(
                  l10n.adminExplanations,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                initiallyExpanded: _explanationItController.text.isNotEmpty ||
                    _existingAudioUrl != null,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('${l10n.explanation} (IT)'),
                        TextFormField(
                          controller: _explanationItController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionTitle('${l10n.explanation} (EN)'),
                        TextFormField(
                          controller: _explanationEnController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionTitle('${l10n.explanation} (BN)'),
                        TextFormField(
                          controller: _explanationBnController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Custom Voice Recording ──────────────────────
                        _buildSectionTitle('Custom Voice (Audio Explanation)'),
                        AdminAudioRecorder(
                          existingAudioUrl: _existingAudioUrl,
                          onAudioRecorded: (path) {
                            setState(() => _recordedAudioPath = path);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.profileSaveButton,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildAnswerOption({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Icon(Icons.check_circle, color: color, size: 20),
              if (isSelected) const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          if (_selectedImageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                _selectedImageBytes!,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
          ] else if (_imageUrl != null && _imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _imageUrl!,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
                  color: Colors.grey.withValues(alpha: 0.2),
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _isUploading ? null : _pickImage,
                icon: const Icon(Icons.upload),
                label: Text(
                  _imageUrl != null || _selectedImageBytes != null
                      ? l10n.adminChangeImage
                      : l10n.adminUploadImage,
                ),
              ),
              if (_imageUrl != null || _selectedImageBytes != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _imageUrl = null;
                      _selectedImageBytes = null;
                      _selectedImageName = null;
                    });
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ],
          ),
          
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
