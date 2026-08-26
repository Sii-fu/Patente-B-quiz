import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/theme.dart';
import '../../features/admin/services/admin_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'audio_recorder_editor_screen.dart';

class EditQuestionScreen extends StatefulWidget {
  final Map<String, dynamic> question;
  final int subtopicId;

  const EditQuestionScreen({
    super.key,
    this.question = const {},
    required this.subtopicId,
  });

  bool get isNewQuestion => question['id'] == null;

  @override
  State<EditQuestionScreen> createState() => _EditQuestionScreenState();
}

class _EditQuestionScreenState extends State<EditQuestionScreen> {
  final AdminRepository _adminRepo = AdminRepository();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _textItController;
  late TextEditingController _textEnController;
  late TextEditingController _textBnController;
  late TextEditingController _explanationItController;
  late TextEditingController _explanationEnController;
  late TextEditingController _explanationBnController;
  late bool _isTrue;
  bool _isSaving = false;
  bool _isDeleting = false;

  String? imageUrl;
  File? selectedImageFile;

  // Store fresh question data from DB
  Map<String, dynamic> _freshQuestion = {};
  bool _isLoadingFreshData = true;

  @override
  void initState() {
    super.initState();
    _freshQuestion = widget.question; // Start with passed data
    _initializeControllers();
    _refreshQuestionData(); // Fetch fresh data including audio URL
  }

  /// Fetch fresh question data from database (includes newly uploaded audio URL)
  Future<void> _refreshQuestionData() async {
    if (widget.isNewQuestion) {
      setState(() => _isLoadingFreshData = false);
      return;
    }
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('questions')
          .select()
          .eq('id', widget.question['id'])
          .single();

      if (mounted) {
        setState(() {
          _freshQuestion = response;
          _isLoadingFreshData = false;
        });
        debugPrint('✓ Refreshed question data from DB');
      }
    } catch (e) {
      debugPrint('Error refreshing question: $e');
      if (mounted) {
        setState(() => _isLoadingFreshData = false);
      }
    }
  }

  /// Initialize controllers with question data
  void _initializeControllers() {
    _textItController = TextEditingController(text: widget.question['text_it']);
    _textEnController = TextEditingController(text: widget.question['text_en']);
    _textBnController = TextEditingController(text: widget.question['text_bn']);
    _explanationItController = TextEditingController(
      text: widget.question['explanation_it'],
    );
    _explanationEnController = TextEditingController(
      text: widget.question['explanation_en'],
    );
    _explanationBnController = TextEditingController(
      text: widget.question['explanation_bn'],
    );
    _isTrue = widget.question['is_true'] as bool? ?? true;
    imageUrl = widget.question['image_url'];
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
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          selectedImageFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    String? finalImageUrl = imageUrl;

    // Upload new image if selected
    if (selectedImageFile != null) {
      final bytes = await selectedImageFile!.readAsBytes();
      final fileName = 'questions/${DateTime.now().millisecondsSinceEpoch}.jpg';
      finalImageUrl = await _adminRepo.uploadImage(
        'quiz_images',
        fileName,
        bytes,
      );

      if (finalImageUrl == null) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
        return;
      }
    }

    final success = await _adminRepo.upsertQuestion(
      id: widget.question['id'] as int?,
      subtopicId: widget.subtopicId,
      textIt: _textItController.text.trim(),
      textEn: _textEnController.text.trim().isEmpty
          ? null
          : _textEnController.text.trim(),
      textBn: _textBnController.text.trim().isEmpty
          ? null
          : _textBnController.text.trim(),
      imageUrl: finalImageUrl,
      isTrue: _isTrue,
      explanationIt: _explanationItController.text.trim().isEmpty
          ? null
          : _explanationItController.text.trim(),
      explanationEn: _explanationEnController.text.trim().isEmpty
          ? null
          : _explanationEnController.text.trim(),
      explanationBn: _explanationBnController.text.trim().isEmpty
          ? null
          : _explanationBnController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);

      if (success != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isNewQuestion
                  ? 'Question added successfully'
                  : 'Question updated successfully',
            ),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isNewQuestion
                  ? 'Failed to add question'
                  : 'Failed to update question',
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final theme = Theme.of(context);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete this question?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This action cannot be undone. The question and its associated audio will be permanently removed.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      await _deleteQuestion();
    }
  }

  Future<void> _deleteQuestion() async {
    setState(() => _isDeleting = true);

    final success = await _adminRepo.deleteQuestion(
      widget.question['id'] as int,
    );

    if (!mounted) return;

    setState(() => _isDeleting = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Question deleted')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete question')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        title: Text(
          widget.isNewQuestion ? 'Add Question' : 'Edit Question',
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
          if (!widget.isNewQuestion)
            if (_isDeleting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                onPressed: _confirmDelete,
                tooltip: 'Delete',
              ),
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveQuestion,
              tooltip: 'Save',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Question Text Section
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

            // Answer Section
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
                        onChanged: (value) {
                          setState(() => _isTrue = value!);
                        },
                        activeColor: AppTheme.successGreen,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('FALSO (False)'),
                        value: false,
                        groupValue: _isTrue,
                        onChanged: (value) {
                          setState(() => _isTrue = value!);
                        },
                        activeColor: AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Image Section
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
                child: selectedImageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          selectedImageFile!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      )
                    : imageUrl != null && imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          errorBuilder: (context, error, stack) {
                            return _buildImagePlaceholder(theme);
                          },
                        ),
                      )
                    : _buildImagePlaceholder(theme),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to change image',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Audio Recording Section
            _buildAudioSection(theme),

            const SizedBox(height: 24),

            // Explanation Section
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

            const SizedBox(height: 32),

            // Save Button
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveQuestion,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
              style: ElevatedButton.styleFrom(
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

  Widget _buildAudioSection(ThemeData theme) {
    final audioUrl = _freshQuestion['explanation_audio_url'];
    final hasAudio = audioUrl != null && audioUrl.toString().trim().isNotEmpty;

    debugPrint('🎙️ Audio Section Debug:');
    debugPrint('  - Audio URL: $audioUrl');
    debugPrint('  - Has Audio: $hasAudio');
    debugPrint('  - Question ID: ${_freshQuestion['id']}');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mic, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Custom Audio Explanation',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasAudio)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.successGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Audio exists ✓',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successGreen,
                                ),
                              ),
                              Text(
                                'Tap to edit or replace',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Audio Player for existing audio
                  _buildExistingAudioPlayer(audioUrl, theme),
                ],
              )
            else
              Text(
                widget.isNewQuestion
                    ? 'Save the question first to add a voice explanation'
                    : 'Add a custom voice explanation for this question',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: widget.isNewQuestion ? null : _openAudioRecorder,
              icon: Icon(hasAudio ? Icons.edit : Icons.mic),
              label: Text(hasAudio ? 'Edit Audio' : 'Record Audio'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAudioRecorder() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AudioRecorderEditorScreen(
          questionId: widget.question['id'] as int,
          existingAudioUrl: widget.question['explanation_audio_url'] as String?,
        ),
      ),
    );

    // Reload question data if audio was uploaded
    if (result == true) {
      // Refresh the question data (optional - depends on your flow)
      setState(() {
        // UI will update on next question load
      });
    }
  }

  /// Build audio player for existing audio URL
  Widget _buildExistingAudioPlayer(String? audioUrl, ThemeData theme) {
    if (audioUrl == null || audioUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return _AudioPlayerWidget(audioUrl: audioUrl, theme: theme);
  }

  /// Play audio from URL
  Future<void> _playAudio(String audioUrl) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening audio player...'),
          duration: Duration(seconds: 2),
        ),
      );

      if (await canLaunchUrl(Uri.parse(audioUrl))) {
        await launchUrl(
          Uri.parse(audioUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open audio')));
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

/// In-app audio player using just_audio
class _AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final ThemeData theme;

  const _AudioPlayerWidget({required this.audioUrl, required this.theme});

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isUrlLoaded = false; // Track if URL already loaded

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    // Listen to player state changes (playing/paused)
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        // Update playing state and stop loading when playback actually starts
        setState(() {
          _isPlaying = state.playing;
          // Stop loading when we transition to playing
          if (state.playing) {
            _isLoading = false;
          }
        });
      }
    });

    // Listen to processing state (loading/buffering/ready)
    _audioPlayer.processingStateStream.listen((state) {
      if (mounted) {
        setState(() {
          // Stop loading when done loading
          if (state == ProcessingState.ready ||
              state == ProcessingState.completed) {
            _isLoading = false;
            _isUrlLoaded = true; // Mark as loaded once ready
          }
        });
      }
    });

    _audioPlayer.durationStream.listen((d) {
      if (mounted) {
        setState(() => _duration = d ?? Duration.zero);
      }
    });

    _audioPlayer.positionStream.listen((p) {
      if (mounted) {
        setState(() => _position = p);
      }
    });
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        // Pause without resetting position
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        // Resume or play from start
        if (!_isUrlLoaded) {
          // First time: load URL and play
          setState(() => _isLoading = true);
          try {
            await _audioPlayer.setUrl(widget.audioUrl);
            await _audioPlayer.play();
            // Loading state will be cleared by processingStateStream listener
          } catch (e) {
            setState(() => _isLoading = false);
            rethrow;
          }
        } else {
          // Already loaded: just resume from where it was paused
          await _audioPlayer.play();
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds"
        .replaceFirst(RegExp(r'^0:'), '');
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: widget.theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Audio',
            style: widget.theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          // Play/Pause button + progress
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: widget.theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _isLoading ? null : _togglePlayPause,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isLoading
                              ? Icons.hourglass_bottom
                              : (_isPlaying ? Icons.pause : Icons.play_arrow),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _duration.inMilliseconds > 0
                                  ? _position.inMilliseconds /
                                        _duration.inMilliseconds
                                  : 0,
                              minHeight: 4,
                              backgroundColor: widget.theme.colorScheme.outline
                                  .withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation(
                                widget.theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                            style: widget.theme.textTheme.labelSmall?.copyWith(
                              color: widget.theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Filename: ${widget.audioUrl.split('/').last}',
            style: widget.theme.textTheme.labelSmall?.copyWith(
              color: widget.theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
