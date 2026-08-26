import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/admin/services/admin_repository.dart';
import '../../services/admin_selection_state.dart';
import '../../services/auto_tts_service.dart';
import '../../utils/theme.dart';

/// Admin screen to create a brand-new quiz question, with chapter/subtopic
/// pickers, image upload, and automated TTS audio generation.
class AddQuizScreen extends StatefulWidget {
  final int? initialSubtopicId;
  final int? initialChapterId;

  const AddQuizScreen({
    super.key,
    this.initialSubtopicId,
    this.initialChapterId,
  });

  @override
  State<AddQuizScreen> createState() => _AddQuizScreenState();
}

class _AddQuizScreenState extends State<AddQuizScreen> {
  final AdminRepository _adminRepo = AdminRepository();
  final AutoTtsService _ttsService = AutoTtsService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final _textItController = TextEditingController();
  final _textEnController = TextEditingController();
  final _textBnController = TextEditingController();
  final _explanationItController = TextEditingController();
  final _explanationEnController = TextEditingController();
  final _explanationBnController = TextEditingController();

  bool _isTrue = true;
  int _difficultyLevel = 1;
  File? _selectedImageFile;

  List<Map<String, dynamic>> _chapters = [];
  List<Map<String, dynamic>> _subtopics = [];
  int? _selectedChapterId;
  int? _selectedSubtopicId;

  bool _isLoadingOptions = true;
  bool _isLoadingSubtopics = false;
  bool _isSaving = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
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

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingOptions = true);

    final chapters = await _adminRepo.getTheoryChapters();

    // Prefer ids passed in directly from the calling screen; fall back to
    // the last chapter/theory-card the admin tapped into elsewhere in the
    // app if this screen was opened without explicit ids.
    int? chapterId =
        widget.initialChapterId ?? AdminSelectionState.lastChapterId;
    final incomingSubtopicId =
        widget.initialSubtopicId ?? AdminSelectionState.lastSubtopicId;

    // If only a subtopic was passed in, resolve which chapter it belongs to
    // via the theory card that actually links them (reliable, unlike the
    // topics->subtopics chain which is often unset).
    if (chapterId == null && incomingSubtopicId != null) {
      final card = await _adminRepo.getTheoryCardBySubtopicId(
        incomingSubtopicId,
      );
      chapterId = card?['chapter_id'] as int?;
    }

    List<Map<String, dynamic>> subtopics = [];
    if (chapterId != null) {
      subtopics = await _loadSubtopicsForChapter(chapterId);
    }

    // The dropdown's option "id" is the theory card's own id (see
    // _loadSubtopicsForChapter), whereas `incomingSubtopicId` may be a real
    // subtopics.id (e.g. passed in from QuizQuestionsScreen) or already a
    // theory-card id (e.g. remembered from a manual pick in this screen).
    // Try a direct match first, then fall back to resolving it via the
    // theory card that links that subtopic id to this chapter.
    int? subtopicId;
    if (incomingSubtopicId != null) {
      if (subtopics.any((s) => s['id'] == incomingSubtopicId)) {
        subtopicId = incomingSubtopicId;
      } else {
        final card = await _adminRepo.getTheoryCardBySubtopicId(
          incomingSubtopicId,
        );
        final cardId = card?['id'] as int?;
        if (cardId != null && subtopics.any((s) => s['id'] == cardId)) {
          subtopicId = cardId;
        }
      }
    }

    // Likewise, only pre-select the chapter if it exists among the options.
    if (chapterId != null && !chapters.any((c) => c['id'] == chapterId)) {
      chapterId = null;
    }

    if (mounted) {
      setState(() {
        _chapters = chapters;
        _subtopics = subtopics;
        _selectedChapterId = chapterId;
        _selectedSubtopicId = subtopicId;
        _isLoadingOptions = false;
      });
    }
  }

  /// Load the "theory cards" (displayed as subtopic options) for a chapter,
  /// deduplicated by subtopic_id and with cards that have no subtopic yet
  /// filtered out (a question needs a real subtopic_id to attach to).
  Future<List<Map<String, dynamic>>> _loadSubtopicsForChapter(
    int chapterId,
  ) async {
    final cards = await _adminRepo.getTheoryCardsByChapter(chapterId);
    final seenSubtopicIds = <int>{};
    final options = <Map<String, dynamic>>[];

    for (final card in cards) {
      final subtopicId = card['id'] as int?;
      if (subtopicId == null || !seenSubtopicIds.add(subtopicId)) continue;
      options.add({
        'id': subtopicId,
        'display_order': card['display_order'],
        'name_it': card['title_it'],
        'name_en': card['title_en'],
        'name_bn': card['title_bn'],
      });
    }
    return options;
  }

  Future<void> _onChapterChanged(int? chapterId) async {
    if (chapterId == null || chapterId == _selectedChapterId) return;

    AdminSelectionState.rememberChapter(chapterId);

    // Clear the subtopic selection FIRST so the subtopic dropdown never
    // renders with a value that isn't present in its (now stale) items.
    setState(() {
      _selectedChapterId = chapterId;
      _selectedSubtopicId = null;
      _subtopics = [];
      _isLoadingSubtopics = true;
    });

    final subtopics = await _loadSubtopicsForChapter(chapterId);
    if (mounted) {
      setState(() {
        _subtopics = subtopics;
        _isLoadingSubtopics = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _selectedImageFile = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSubtopicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a theory card / subtopic')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _statusMessage = 'Saving question...';
    });

    try {
      String? imageUrl;
      if (_selectedImageFile != null) {
        final bytes = await _selectedImageFile!.readAsBytes();
        final fileName =
            'questions/${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await _adminRepo.uploadImage('quiz_images', fileName, bytes);

        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }

      final textIt = _textItController.text.trim();
      final textEn = _textEnController.text.trim().isEmpty
          ? null
          : _textEnController.text.trim();
      final textBn = _textBnController.text.trim().isEmpty
          ? null
          : _textBnController.text.trim();
      final explanationIt = _explanationItController.text.trim().isEmpty
          ? null
          : _explanationItController.text.trim();
      final explanationEn = _explanationEnController.text.trim().isEmpty
          ? null
          : _explanationEnController.text.trim();
      final explanationBn = _explanationBnController.text.trim().isEmpty
          ? null
          : _explanationBnController.text.trim();

      final newQuestionId = await _adminRepo.upsertQuestion(
        subtopicId: _selectedSubtopicId!,
        textIt: textIt,
        textEn: textEn,
        textBn: textBn,
        imageUrl: imageUrl,
        isTrue: _isTrue,
        explanationIt: explanationIt,
        explanationEn: explanationEn,
        explanationBn: explanationBn,
        difficultyLevel: _difficultyLevel,
      );

      if (newQuestionId == null) {
        throw Exception('Failed to create question');
      }

      setState(() => _statusMessage = 'Generating audio...');

      final audioUrls = await _ttsService.generateAndUploadAudio(
        questionId: newQuestionId,
        textIt: textIt,
        textEn: textEn,
        textBn: textBn,
      );

      await _adminRepo.upsertQuestion(
        id: newQuestionId,
        subtopicId: _selectedSubtopicId!,
        textIt: textIt,
        textEn: textEn,
        textBn: textBn,
        imageUrl: imageUrl,
        isTrue: _isTrue,
        explanationIt: explanationIt,
        explanationEn: explanationEn,
        explanationBn: explanationBn,
        audioItUrl: audioUrls['audio_it_url'],
        audioEnUrl: audioUrls['audio_en_url'],
        audioBnUrl: audioUrls['audio_bn_url'],
        difficultyLevel: _difficultyLevel,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz & Audio created successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving quiz: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusMessage = null;
        });
      }
    }
  }

  String _chapterLabel(Map<String, dynamic> chapter) {
    final order = chapter['display_order'] ?? chapter['id'];
    final name =
        chapter['name_it']?.toString() ??
        chapter['name_en']?.toString() ??
        'Chapter #${chapter['id']}';
    return '#$order - $name';
  }

  String _subtopicLabel(Map<String, dynamic> subtopic) {
    final order = subtopic['id'] % 100;
    final name =
        subtopic['name_it']?.toString() ??
        subtopic['name_en']?.toString() ??
        'Subtopic #${subtopic['id']}';
    return '#$order - $name';
  }

  bool get _canSave =>
      !_isSaving && _selectedChapterId != null && _selectedSubtopicId != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        title: Text(
          'Add Quiz',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.surface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.surface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _canSave ? _saveQuiz : null,
              tooltip: 'Save',
            ),
        ],
      ),
      body: _isLoadingOptions
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionHeader('Category', theme),
                  const SizedBox(height: 12),
                  // Keyed by the current selection so that programmatic
                  // updates (auto-selection, chapter switches) force the
                  // field to re-initialize from `initialValue` instead of
                  // keeping a stale internal value that may no longer be
                  // present in `items` (which throws an assertion error).
                  DropdownButtonFormField<int>(
                    key: ValueKey('chapter_dropdown_$_selectedChapterId'),
                    initialValue: _selectedChapterId,
                    isExpanded: true, // 👈 ADD THIS LINE HERE
                    decoration: const InputDecoration(
                      labelText: 'Chapter / Topic',
                      border: OutlineInputBorder(),
                    ),
                    items: _chapters
                        .map(
                          (chapter) => DropdownMenuItem<int>(
                            value: chapter['id'] as int,
                            child: Text(
                              _chapterLabel(chapter),
                              overflow:
                                  TextOverflow.ellipsis, // 👈 ALSO GOOD TO ADD
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _onChapterChanged,
                    validator: (value) =>
                        value == null ? 'Please select a chapter' : null,
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingSubtopics)
                    const SizedBox(
                      height: 56,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      key: ValueKey(
                        'subtopic_dropdown_${_selectedChapterId}_$_selectedSubtopicId',
                      ),
                      initialValue: _selectedSubtopicId,
                      isExpanded: true, // 👈 ADD THIS LINE HERE
                      decoration: const InputDecoration(
                        labelText: 'Theory Card / Subtopic',
                        border: OutlineInputBorder(),
                      ),
                      items: _subtopics
                          .map(
                            (subtopic) => DropdownMenuItem<int>(
                              value: subtopic['id'] as int,
                              child: Text(
                                _subtopicLabel(subtopic),
                                overflow: TextOverflow
                                    .ellipsis, // 👈 ALSO GOOD TO ADD
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedSubtopicId = value);
                        if (value != null && _selectedChapterId != null) {
                          AdminSelectionState.rememberSubtopic(
                            _selectedChapterId!,
                            value,
                          );
                        }
                      },
                      validator: (value) =>
                          value == null ? 'Please select a subtopic' : null,
                    ),

                  const SizedBox(height: 24),
                  _buildSectionHeader('Question Text', theme),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _textItController,
                    label: 'Italian (Required)',
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Italian text is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _textEnController,
                    label: 'English',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _textBnController,
                    label: 'Bangla',
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader('Correct Answer', theme),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('VERO (True)'),
                              value: true,
                              groupValue: _isTrue,
                              onChanged: (value) =>
                                  setState(() => _isTrue = value!),
                              activeColor: AppTheme.successGreen,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('FALSO (False)'),
                              value: false,
                              groupValue: _isTrue,
                              onChanged: (value) =>
                                  setState(() => _isTrue = value!),
                              activeColor: AppTheme.errorRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // const SizedBox(height: 24),
                  // _buildSectionHeader('Difficulty Level', theme),
                  // const SizedBox(height: 12),
                  // DropdownButtonFormField<int>(
                  //   initialValue: _difficultyLevel,
                  //   decoration: const InputDecoration(
                  //     labelText: 'Difficulty (1 = Easy, 3 = Hard)',
                  //     border: OutlineInputBorder(),
                  //   ),
                  //   items: const [1, 2, 3]
                  //       .map(
                  //         (level) => DropdownMenuItem<int>(
                  //           value: level,
                  //           child: Text('Level $level'),
                  //         ),
                  //       )
                  //       .toList(),
                  //   onChanged: (value) =>
                  //       setState(() => _difficultyLevel = value ?? 1),
                  // ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Image (Optional)', theme),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      child: _selectedImageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImageFile!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                              ),
                            )
                          : _buildImagePlaceholder(theme),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Select Image'),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader('Explanation (Optional)', theme),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _explanationItController,
                    label: 'Italian',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _explanationEnController,
                    label: 'English',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _explanationBnController,
                    label: 'Bangla',
                    maxLines: 4,
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Audio explanations will be generated automatically from the text above.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _canSave ? _saveQuiz : null,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _isSaving
                          ? (_statusMessage ?? 'Saving...')
                          : 'Upload quiz',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.surface,
                      minimumSize: const Size(double.infinity, 56),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to add image',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '(Optional)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
