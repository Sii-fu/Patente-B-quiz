import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/theme.dart';
import '../../features/admin/services/admin_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditTheoryCardScreen extends StatefulWidget {
  final Map<String, dynamic> card;
  final int chapterId;

  const EditTheoryCardScreen({
    super.key,
    required this.card,
    required this.chapterId,
  });

  @override
  State<EditTheoryCardScreen> createState() => _EditTheoryCardScreenState();
}

class _EditTheoryCardScreenState extends State<EditTheoryCardScreen> {
  final AdminRepository _adminRepo = AdminRepository();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleItController;
  late TextEditingController _titleEnController;
  late TextEditingController _titleBnController;
  late TextEditingController _textItController;
  late TextEditingController _textEnController;
  late TextEditingController _textBnController;
  late TextEditingController _displayOrderController;
  
  bool _isSaving = false;
  String? _imageUrl;
  File? _selectedImageFile;
  
  // Store fresh card data from DB
  Map<String, dynamic> _freshCard = {};
  bool _isLoadingFreshData = true;

  @override
  void initState() {
    super.initState();
    _freshCard = widget.card;
    _initializeControllers();
    _refreshCardData();
  }

  Future<void> _refreshCardData() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('theory_cards')
          .select()
          .eq('id', widget.card['id'])
          .single();
      
      if (mounted) {
        setState(() {
          _freshCard = response;
          _isLoadingFreshData = false;
        });
        debugPrint('✓ Refreshed theory card data from DB');
      }
    } catch (e) {
      debugPrint('Error refreshing theory card: $e');
      if (mounted) {
        setState(() => _isLoadingFreshData = false);
      }
    }
  }

  void _initializeControllers() {
    _titleItController = TextEditingController(text: widget.card['title_it']);
    _titleEnController = TextEditingController(text: widget.card['title_en']);
    _titleBnController = TextEditingController(text: widget.card['title_bn']);
    _textItController = TextEditingController(text: widget.card['text_it']);
    _textEnController = TextEditingController(text: widget.card['text_en']);
    _textBnController = TextEditingController(text: widget.card['text_bn']);
    _displayOrderController = TextEditingController(
      text: (widget.card['display_order'] ?? 1).toString(),
    );
    _imageUrl = widget.card['image_url'];
  }

  @override
  void dispose() {
    _titleItController.dispose();
    _titleEnController.dispose();
    _titleBnController.dispose();
    _textItController.dispose();
    _textEnController.dispose();
    _textBnController.dispose();
    _displayOrderController.dispose();
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
          _selectedImageFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_textItController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Italian content is required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    String? finalImageUrl = _imageUrl;

    // Upload new image if selected
    if (_selectedImageFile != null) {
      final bytes = await _selectedImageFile!.readAsBytes();
      finalImageUrl = await _adminRepo.uploadTheoryCardImage(
        bytes,
        originalFileName: _selectedImageFile!.path.split('.').last,
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

    final success = await _adminRepo.upsertTheoryCard(
      id: widget.card['id'] as int,
      chapterId: widget.chapterId,
      titleIt: _titleItController.text.trim().isEmpty ? null : _titleItController.text.trim(),
      titleEn: _titleEnController.text.trim().isEmpty ? null : _titleEnController.text.trim(),
      titleBn: _titleBnController.text.trim().isEmpty ? null : _titleBnController.text.trim(),
      textIt: _textItController.text.trim(),
      textEn: _textEnController.text.trim().isEmpty ? null : _textEnController.text.trim(),
      textBn: _textBnController.text.trim().isEmpty ? null : _textBnController.text.trim(),
      imageUrl: finalImageUrl,
      displayOrder: int.tryParse(_displayOrderController.text) ?? 1,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Theory card updated successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update theory card')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Edit Theory Card'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
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
            TextButton.icon(
              onPressed: _saveCard,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
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
              // Image Section
              _buildImageSection(theme),
              const SizedBox(height: 16),
              
              // Audio Section
              _buildAudioSection(theme),
              const SizedBox(height: 16),
              
              // Title Section
              _buildTitleSection(theme),
              const SizedBox(height: 16),
              
              // Content Section
              _buildContentSection(theme),
              const SizedBox(height: 16),
              
              // Display Order
              _buildDisplayOrderSection(theme),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Card Image',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
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
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : _imageUrl != null && _imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stack) {
                                return _buildImagePlaceholder(theme);
                              },
                            ),
                          )
                        : _buildImagePlaceholder(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to add image',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioSection(ThemeData theme) {
    final audioUrl = _freshCard['audio_explanation_url'];
    final hasAudio = audioUrl != null && audioUrl.toString().trim().isNotEmpty;
    
    debugPrint('🎙️ Theory Card Audio Debug:');
    debugPrint('  - Audio URL: $audioUrl');
    debugPrint('  - Has Audio: $hasAudio');
    debugPrint('  - Card ID: ${_freshCard['id']}');

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
                  'Audio Explanation',
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
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.successGreen,
                        ),
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
                  _TheoryCardAudioPlayerWidget(audioUrl: audioUrl, theme: theme),
                ],
              )
            else
              Text(
                'Add a custom voice explanation for this theory card',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _openAudioRecorder,
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
        builder: (context) => TheoryCardAudioRecorderScreen(
          cardId: widget.card['id'] as int,
          existingAudioUrl: _freshCard['audio_explanation_url'] as String?,
        ),
      ),
    );

    // Reload card data if audio was uploaded
    if (result == true) {
      _refreshCardData();
    }
  }

  Widget _buildTitleSection(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.title, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Title (Optional)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleItController,
              decoration: const InputDecoration(
                labelText: '🇮🇹 Italian Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleEnController,
              decoration: const InputDecoration(
                labelText: '🇬🇧 English Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleBnController,
              decoration: const InputDecoration(
                labelText: '🇧🇩 Bangla Title',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.article, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Content',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _textItController,
              decoration: const InputDecoration(
                labelText: '🇮🇹 Italian Content *',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Italian content is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textEnController,
              decoration: const InputDecoration(
                labelText: '🇬🇧 English Content',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textBnController,
              decoration: const InputDecoration(
                labelText: '🇧🇩 Bangla Content',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayOrderSection(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sort, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Display Order',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _displayOrderController,
              decoration: const InputDecoration(
                labelText: 'Order Number',
                border: OutlineInputBorder(),
                hintText: 'e.g., 1, 2, 3...',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
      ),
    );
  }
}

/// In-app audio player for theory card
class _TheoryCardAudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final ThemeData theme;

  const _TheoryCardAudioPlayerWidget({
    required this.audioUrl,
    required this.theme,
  });

  @override
  State<_TheoryCardAudioPlayerWidget> createState() => _TheoryCardAudioPlayerWidgetState();
}

class _TheoryCardAudioPlayerWidgetState extends State<_TheoryCardAudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isUrlLoaded = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.playing) _isLoading = false;
        });
      }
    });

    _audioPlayer.processingStateStream.listen((state) {
      if (mounted) {
        setState(() {
          if (state == ProcessingState.ready || state == ProcessingState.completed) {
            _isLoading = false;
            _isUrlLoaded = true;
          }
        });
      }
    });

    _audioPlayer.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d ?? Duration.zero);
    });

    _audioPlayer.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        if (!_isUrlLoaded) {
          setState(() => _isLoading = true);
          await _audioPlayer.setUrl(widget.audioUrl);
        }
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: widget.theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
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
                              ? _position.inMilliseconds / _duration.inMilliseconds
                              : 0,
                          minHeight: 4,
                          backgroundColor: widget.theme.colorScheme.outline.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation(widget.theme.colorScheme.primary),
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
          ),
        ],
      ),
    );
  }
}

/// Audio recorder screen for theory cards
class TheoryCardAudioRecorderScreen extends StatefulWidget {
  final int cardId;
  final String? existingAudioUrl;

  const TheoryCardAudioRecorderScreen({
    super.key,
    required this.cardId,
    this.existingAudioUrl,
  });

  @override
  State<TheoryCardAudioRecorderScreen> createState() =>
      _TheoryCardAudioRecorderScreenState();
}

class _TheoryCardAudioRecorderScreenState extends State<TheoryCardAudioRecorderScreen> {
  final AdminRepository _adminRepo = AdminRepository();
  final AudioRecorder _audioRecorder = AudioRecorder();
  late AudioPlayer _audioPlayer;
  bool _isRecording = false;
  bool _isPaused = false;
  String? _recordedFilePath;
  String? _uploadedFilePath;
  Duration _recordingDuration = Duration.zero;

  bool _isPlaying = false;
  Duration _playbackPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  int _selectedAudioSource = 0; // 0: existing, 1: recorded, 2: uploaded

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupPlaybackListeners();
  }

  void _setupPlaybackListeners() {
    _audioPlayer.positionStream.listen((position) {
      if (mounted) setState(() => _playbackPosition = position);
    });

    _audioPlayer.durationStream.listen((duration) {
      if (mounted) setState(() => _totalDuration = duration ?? Duration.zero);
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
      }
    });
  }

  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required to record audio'),
        ),
      );
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final recordingPath = '${dir.path}/theory_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: recordingPath,
        );

        setState(() {
          _isRecording = true;
          _isPaused = false;
          _recordedFilePath = recordingPath;
          _recordingDuration = Duration.zero;
          _selectedAudioSource = 1;
        });

        _startDurationUpdater();
      } else {
        await _requestMicrophonePermission();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  void _startDurationUpdater() {
    Future.delayed(Duration.zero, () async {
      while (_isRecording && mounted) {
        if (!_isPaused) {
          setState(() {
            _recordingDuration += const Duration(milliseconds: 100);
          });
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    });
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioRecorder.pause();
      setState(() => _isPaused = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error pausing recording: $e')),
        );
      }
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _audioRecorder.resume();
      setState(() => _isPaused = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resuming recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isPaused = false;
          _recordedFilePath = path;
          _selectedAudioSource = 1;
        });

        if (path != null) {
          try {
            await _audioPlayer.setFilePath(path);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading recorded audio: $e')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        allowCompression: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        
        final audioExtensions = ['.m4a', '.mp3', '.wav', '.aac', '.m4b'];
        final isAudioFile = audioExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));
        
        if (!isAudioFile) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select an audio file (.m4a, .mp3, .wav, .aac)')),
            );
          }
          return;
        }

        setState(() {
          _uploadedFilePath = filePath;
          _selectedAudioSource = 2;
        });

        try {
          await _audioPlayer.setFilePath(filePath);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading audio: $e')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      String? audioPath;
      
      if (_selectedAudioSource == 0 && widget.existingAudioUrl != null) {
        audioPath = widget.existingAudioUrl;
      } else if (_selectedAudioSource == 1 && _recordedFilePath != null) {
        audioPath = _recordedFilePath;
      } else if (_selectedAudioSource == 2 && _uploadedFilePath != null) {
        audioPath = _uploadedFilePath;
      }

      if (audioPath == null) return;

      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_audioPlayer.audioSource == null || 
            (_playbackPosition == _totalDuration && _totalDuration != Duration.zero)) {
          if (audioPath.startsWith('http')) {
            await _audioPlayer.setUrl(audioPath);
          } else {
            await _audioPlayer.setFilePath(audioPath);
          }
        }
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Playback error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _uploadAudio() async {
    if (_isUploading) return;

    setState(() => _isUploading = true);

    try {
      String? audioPath;
      
      if (_selectedAudioSource == 1 && _recordedFilePath != null) {
        audioPath = _recordedFilePath;
      } else if (_selectedAudioSource == 2 && _uploadedFilePath != null) {
        audioPath = _uploadedFilePath;
      }

      if (audioPath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please record or upload an audio file')),
          );
          setState(() => _isUploading = false);
        }
        return;
      }

      // Upload to Supabase
      final audioUrl = await _adminRepo.uploadAudio(audioPath);

      if (audioUrl == null) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload audio')),
          );
        }
        return;
      }

      // Update theory card with audio URL
      final success = await _adminRepo.updateTheoryCardAudioUrl(
        cardId: widget.cardId,
        audioUrl: audioUrl,
      );

      if (mounted) {
        setState(() => _isUploading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Audio uploaded and saved successfully')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Audio uploaded but failed to save to database.\n'
                'URL: $audioUrl\n'
                'Check: theory_cards table RLS policy'
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Explanation'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Audio Source Selector
            Text(
              'Select Audio Source',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Existing audio option
            if (widget.existingAudioUrl != null) ...[
              _buildAudioSourceTile(
                theme: theme,
                index: 0,
                icon: Icons.cloud_done,
                title: 'Existing Audio',
                subtitle: 'Play current audio from server',
              ),
              const SizedBox(height: 8),
            ],
            
            // Record new option
            _buildAudioSourceTile(
              theme: theme,
              index: 1,
              icon: Icons.mic,
              title: 'Record New',
              subtitle: _recordedFilePath != null ? 'Recording ready' : 'Tap to record',
            ),
            
            // Recording controls (when record option selected)
            if (_selectedAudioSource == 1) ...[
              const SizedBox(height: 16),
              _buildRecordingControls(theme),
            ],
            
            const SizedBox(height: 8),
            
            // Upload option
            _buildAudioSourceTile(
              theme: theme,
              index: 2,
              icon: Icons.upload_file,
              title: 'Upload from Files',
              subtitle: _uploadedFilePath != null ? 'File selected' : 'Choose audio file',
            ),
            
            // File picker button (when upload option selected)
            if (_selectedAudioSource == 2) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickAudioFile,
                  icon: const Icon(Icons.folder_open),
                  label: Text(_uploadedFilePath != null ? 'Change File' : 'Select Audio File'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Playback controls
            if (_selectedAudioSource == 0 && widget.existingAudioUrl != null ||
                _selectedAudioSource == 1 && _recordedFilePath != null && !_isRecording ||
                _selectedAudioSource == 2 && _uploadedFilePath != null)
              _buildPlaybackControls(theme),
            
            const SizedBox(height: 24),
            
            // Upload button
            if (_selectedAudioSource != 0 &&
                (_recordedFilePath != null || _uploadedFilePath != null))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadAudio,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(_isUploading ? 'Uploading...' : 'Save Audio'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingControls(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Recording time display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: _isRecording 
                    ? AppTheme.errorRed.withOpacity(0.1) 
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isRecording && !_isPaused)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (_isRecording && !_isPaused)
                    const SizedBox(width: 8),
                  Text(
                    _formatDuration(_recordingDuration),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Recording buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRecording) ...[
                  // Start recording button
                  GestureDetector(
                    onTap: _startRecording,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.errorRed.withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ] else ...[
                  // Pause/Resume button
                  GestureDetector(
                    onTap: _isPaused ? _resumeRecording : _pauseRecording,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPaused ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Stop button
                  GestureDetector(
                    onTap: _stopRecording,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stop,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _isRecording 
                  ? (_isPaused ? 'Recording paused' : 'Recording...') 
                  : 'Tap to start recording',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSourceTile({
    required ThemeData theme,
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedAudioSource == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedAudioSource = index);
        _audioPlayer.stop();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.05)
              : theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackControls(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _totalDuration.inMilliseconds > 0
                    ? _playbackPosition.inMilliseconds / _totalDuration.inMilliseconds
                    : 0,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_playbackPosition), style: theme.textTheme.bodySmall),
                Text(_formatDuration(_totalDuration), style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
