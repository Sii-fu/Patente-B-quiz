import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Three possible states for the recording widget.
enum _RecorderState { idle, recording, preview }

/// A self-contained admin widget that records voice, previews it,
/// and fires [onAudioRecorded] with the local file path when done.
class AdminAudioRecorder extends StatefulWidget {
  /// Called when a recording is completed. Passes `null` when the
  /// recording is deleted (retake). Passes the temp file path otherwise.
  final void Function(String? filePath) onAudioRecorded;

  /// Optional: pre-existing audio URL to indicate a recording exists.
  final String? existingAudioUrl;

  const AdminAudioRecorder({
    super.key,
    required this.onAudioRecorded,
    this.existingAudioUrl,
  });

  @override
  State<AdminAudioRecorder> createState() => _AdminAudioRecorderState();
}

class _AdminAudioRecorderState extends State<AdminAudioRecorder>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  _RecorderState _state = _RecorderState.idle;
  String? _localFilePath;

  // Timer for the recording duration display
  Timer? _recordingTimer;
  int _recordedSeconds = 0;

  // Pulse animation for the recording indicator
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Playback state
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController);

    // Listen to player state changes
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
        // Reset to beginning when playback finishes
        if (state.processingState == ProcessingState.completed) {
          _player.seek(Duration.zero);
          _player.pause();
        }
      }
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  // ─── Permission helper ────────────────────────────────────────────────────

  Future<bool> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return true;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Microphone permission denied. Please enable it in Settings.',
          ),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Settings',
            onPressed: openAppSettings,
          ),
        ),
      );
    }
    return false;
  }

  // ─── Recording control ────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();
    final hasPermission = await _requestMicPermission();
    if (!hasPermission) return;

    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/temp_explanation.m4a';

      // Delete any previous temp file
      final existing = File(path);
      if (await existing.exists()) await existing.delete();

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: path,
      );

      setState(() {
        _state = _RecorderState.recording;
        _localFilePath = path;
        _recordedSeconds = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordedSeconds++);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    HapticFeedback.mediumImpact();
    _recordingTimer?.cancel();

    try {
      final path = await _recorder.stop();
      if (path == null || !File(path).existsSync()) {
        throw Exception('Recording file not found');
      }

      // Load file into player for preview
      await _player.setFilePath(path);

      setState(() {
        _state = _RecorderState.preview;
        _localFilePath = path;
      });

      widget.onAudioRecorded(path);
    } catch (e) {
      setState(() => _state = _RecorderState.idle);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteRecording() async {
    HapticFeedback.lightImpact();
    await _player.stop();

    if (_localFilePath != null) {
      final file = File(_localFilePath!);
      if (await file.exists()) await file.delete();
    }

    setState(() {
      _state = _RecorderState.idle;
      _localFilePath = null;
      _recordedSeconds = 0;
      _isPlaying = false;
    });

    widget.onAudioRecorded(null);
  }

  Future<void> _togglePlayback() async {
    HapticFeedback.selectionClick();
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  // ─── Time formatting ──────────────────────────────────────────────────────

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label row
          Row(
            children: [
              Icon(
                Icons.record_voice_over,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Custom Voice Explanation',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (widget.existingAudioUrl != null &&
                  _state == _RecorderState.idle) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Uploaded',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // ── State-specific UI ──
          switch (_state) {
            _RecorderState.idle => _buildIdleUI(theme),
            _RecorderState.recording => _buildRecordingUI(theme),
            _RecorderState.preview => _buildPreviewUI(theme),
          },
        ],
      ),
    );
  }

  // ── Idle state ────────────────────────────────────────────────────────────

  Widget _buildIdleUI(ThemeData theme) {
    return GestureDetector(
      onTap: _startRecording,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.mic,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.existingAudioUrl != null
                  ? 'Tap to Re-Record'
                  : 'Tap to Record Explanation',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.existingAudioUrl != null) ...[
              const SizedBox(height: 4),
              Text(
                'This will replace the existing audio',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Recording state ───────────────────────────────────────────────────────

  Widget _buildRecordingUI(ThemeData theme) {
    return Column(
      children: [
        // Pulsating red dot + timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'REC  ${_formatDuration(_recordedSeconds)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Stop button
        ElevatedButton.icon(
          onPressed: _stopRecording,
          icon: const Icon(Icons.stop_circle_outlined, size: 24),
          label: const Text(
            'Stop Recording',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // ── Preview state ─────────────────────────────────────────────────────────

  Widget _buildPreviewUI(ThemeData theme) {
    return Row(
      children: [
        // Play / Pause button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _togglePlayback,
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              size: 26,
            ),
            label: Text(
              _isPlaying ? 'Pause' : 'Play Preview',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Delete / Retake button
        IconButton.filled(
          onPressed: _deleteRecording,
          tooltip: 'Delete & Retake',
          style: IconButton.styleFrom(
            backgroundColor: Colors.red.withValues(alpha: 0.15),
            foregroundColor: Colors.red,
            minimumSize: const Size(52, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.delete_outline, size: 26),
        ),
      ],
    );
  }
}
