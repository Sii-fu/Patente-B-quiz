import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/theme.dart';
import '../../features/admin/services/admin_repository.dart';

class AudioRecorderEditorScreen extends StatefulWidget {
  final int questionId;
  final String? existingAudioUrl;

  const AudioRecorderEditorScreen({
    super.key,
    required this.questionId,
    this.existingAudioUrl,
  });

  @override
  State<AudioRecorderEditorScreen> createState() =>
      _AudioRecorderEditorScreenState();
}

class _AudioRecorderEditorScreenState extends State<AudioRecorderEditorScreen> {
  final AdminRepository _adminRepo = AdminRepository();
  final AudioRecorder _audioRecorder = AudioRecorder();
  late AudioPlayer _audioPlayer;

  // Recording states
  bool _isRecording = false;
  bool _isPaused = false;
  String? _recordedFilePath;
  String? _uploadedFilePath;
  Duration _recordingDuration = Duration.zero;

  // Editing states
  Duration _trimStart = Duration.zero;
  Duration _trimEnd = Duration.zero;

  // Playback states
  bool _isPlaying = false;
  Duration _playbackPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  int _selectedAudioSource = 0; // 0: existing, 1: recorded, 2: uploaded

  // Upload states
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
    if (widget.existingAudioUrl != null && widget.existingAudioUrl!.isNotEmpty) {
      _selectedAudioSource = 0;
      _loadExistingAudio();
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _playbackPosition = position;
        });
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration ?? Duration.zero;
          if (_trimEnd == Duration.zero) {
            _trimEnd = _totalDuration;
          }
        });
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
  }

  Future<void> _loadExistingAudio() async {
    try {
      if (widget.existingAudioUrl != null && widget.existingAudioUrl!.isNotEmpty) {
        await _audioPlayer.setUrl(widget.existingAudioUrl!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading audio: $e')),
        );
      }
    }
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
        // Use app's documents directory instead of system temp for persistent storage
        final dir = await getApplicationDocumentsDirectory();
        final recordingPath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

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
          _selectedAudioSource = 1; // Switch to recorded audio
        });

        // Update recording duration every 100ms
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
      setState(() {
        _isPaused = true;
      });
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
      setState(() {
        _isPaused = false;
      });
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

        // Load the recorded audio for preview
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
        
        // Verify it's an audio file by extension
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

        // Load uploaded file for preview
        try {
          await _audioPlayer.setFilePath(filePath);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading audio file: $e')),
            );
          }
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

  Future<void> _playPauseAudio() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        // Get the appropriate audio source
        String? audioPath;
        if (_selectedAudioSource == 0 && widget.existingAudioUrl != null) {
          audioPath = widget.existingAudioUrl;
        } else if (_selectedAudioSource == 1 && _recordedFilePath != null) {
          audioPath = _recordedFilePath;
        } else if (_selectedAudioSource == 2 && _uploadedFilePath != null) {
          audioPath = _uploadedFilePath;
        }

        if (audioPath != null) {
          if (_playbackPosition >= _totalDuration) {
            await _audioPlayer.seek(Duration.zero);
          }
          await _audioPlayer.play();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  Future<void> _uploadAudio() async {
    if (mounted) {
      setState(() => _isUploading = true);
    }

    try {
      // Determine which audio to upload
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

      // Upload to Supabase using existing uploadAudio method
      final audioUrl = await _adminRepo.uploadAudio(audioPath);

      if (audioUrl == null) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to upload audio. Please ensure:\n'
                '• You are logged in as an admin\n'
                '• Supabase RLS policy allows uploads\n'
                '• Internet connection is stable'
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Update question with audio URL
      final success = await _adminRepo.updateQuestionAudioUrl(
        questionId: widget.questionId,
        audioUrl: audioUrl,
      );

      if (mounted) {
        setState(() => _isUploading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Audio uploaded and saved successfully')),
          );
          Navigator.pop(context, true); // Return success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Audio uploaded but failed to save to database.\n'
                'URL: $audioUrl\n'
                'Check: questions table RLS policy allows admin updates'
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
          SnackBar(
            content: Text('Upload error: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    
    // Cleanup: Remove the temporary recorded file if it wasn't uploaded
    if (_recordedFilePath != null && !_recordedFilePath!.isEmpty) {
      try {
        final file = File(_recordedFilePath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        debugPrint('Error deleting temp audio file: $e');
      }
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Edit Audio Explanation',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Existing Audio Section
            if (widget.existingAudioUrl != null && widget.existingAudioUrl!.isNotEmpty)
              _buildExistingAudioSection(theme),

            const SizedBox(height: 24),

            // Recording Section
            _buildRecordingSection(theme),

            const SizedBox(height: 24),

            // File Upload Section
            _buildFileUploadSection(theme),

            const SizedBox(height: 24),

            // Audio Playback & Edit Section
            if (_recordedFilePath != null || _uploadedFilePath != null || widget.existingAudioUrl != null)
              _buildPlaybackAndEditSection(theme),

            const SizedBox(height: 32),

            // Action Buttons
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingAudioSection(ThemeData theme) {
    final isSelected = _selectedAudioSource == 0;
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.music_note, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Current Audio',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() => _selectedAudioSource = 0);
                _playPauseAudio();
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isPlaying && _selectedAudioSource == 0
                          ? Icons.pause_circle
                          : Icons.play_circle,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Play existing audio',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDuration(_playbackPosition),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingSection(ThemeData theme) {
    final isSelected = _selectedAudioSource == 1;
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mic,
                  color: _isRecording ? theme.colorScheme.error : theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Record New Audio',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isRecording)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recording',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Duration: ${_formatDuration(_recordingDuration)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_recordedFilePath != null)
                    Text(
                      '✓ Ready',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (!_isRecording)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startRecording,
                      icon: const Icon(Icons.mic),
                      label: const Text('Start Recording'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _stopRecording,
                      icon: const Icon(Icons.stop_circle),
                      label: const Text('Stop Recording'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ),
                if (_isRecording) const SizedBox(width: 12),
                if (_isRecording)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                      icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                      label: Text(_isPaused ? 'Resume' : 'Pause'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadSection(ThemeData theme) {
    final isSelected = _selectedAudioSource == 2;
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_open, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Or Upload from Files',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Supported: .m4a, .mp3, .wav, .aac',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (_uploadedFilePath != null)
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
                      child: Text(
                        'File selected: ${File(_uploadedFilePath!).path.split('/').last}',
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _pickAudioFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Choose Audio File'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackAndEditSection(ThemeData theme) {
    final hasAudio = _recordedFilePath != null ||
        _uploadedFilePath != null ||
        (widget.existingAudioUrl != null && widget.existingAudioUrl!.isNotEmpty);

    if (!hasAudio) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Playback & Edit',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Playback controls
            GestureDetector(
              onTap: _playPauseAudio,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isPlaying ? Icons.pause_circle : Icons.play_circle,
                      color: theme.colorScheme.primary,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isPlaying ? 'Playing...' : 'Ready to play',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _totalDuration.inMilliseconds > 0
                                  ? _playbackPosition.inMilliseconds /
                                      _totalDuration.inMilliseconds
                                  : 0,
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_formatDuration(_playbackPosition)} / ${_formatDuration(_totalDuration)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isUploading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isUploading ? null : _uploadAudio,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: _isUploading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        theme.colorScheme.onPrimary,
                      ),
                    ),
                  )
                : const Text('Upload & Save'),
          ),
        ),
      ],
    );
  }
}
