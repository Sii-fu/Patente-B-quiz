import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/local_db.dart';
import '../models/quiz_session.dart';

/// Service for synchronizing pending offline data to Supabase
/// Automatically uploads quiz results when internet connection is restored
class SyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase;
  final Connectivity _connectivity;
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService({
    required AppDatabase database,
    SupabaseClient? supabaseClient,
    Connectivity? connectivity,
  })  : _db = database,
        _supabase = supabaseClient ?? Supabase.instance.client,
        _connectivity = connectivity ?? Connectivity();

  /// Initialize sync service and start listening for connectivity changes
  Future<void> initialize() async {
    // Attempt initial sync if online
    await uploadPendingResults();

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityResult result) {
    final hasConnection = result != ConnectivityResult.none;
    
    if (hasConnection && !_isSyncing) {
      // Connection restored - attempt sync
      uploadPendingResults();
    }
  }

  /// Upload all pending results to Supabase
  /// Returns summary of sync operation
  Future<SyncSummary> uploadPendingResults() async {
    // Prevent concurrent syncs
    if (_isSyncing) {
      return SyncSummary(
        totalAttempted: 0,
        successCount: 0,
        failedCount: 0,
        message: 'Sync already in progress',
      );
    }

    _isSyncing = true;

    try {
      // Step 1: Query PendingUploads table
      final pendingUploads = await _db.getAllPendingUploads();

      if (pendingUploads.isEmpty) {
        _isSyncing = false;
        return SyncSummary(
          totalAttempted: 0,
          successCount: 0,
          failedCount: 0,
          message: 'No pending results to sync',
        );
      }

      var successCount = 0;
      var failedCount = 0;
      final errors = <String>[];

      // Step 2: Loop through each row
      for (final upload in pendingUploads) {
        try {
          // Step 3: Decode JSON payload
          final data = jsonDecode(upload.payload) as Map<String, dynamic>;
          
          final sessionData = data['session'] as Map<String, dynamic>;
          final answersData = data['answers'] as List<dynamic>;

          // Parse models
          final session = QuizSession.fromJson(sessionData);
          final answers = answersData
              .map((a) => QuizAnswer.fromJson(a as Map<String, dynamic>))
              .toList();

          // Step 4: Try to insert into Supabase
          await _uploadToSupabase(session, answers);

          // Step 5: Success - Delete from PendingUploads
          await _db.deletePendingUpload(upload.id);
          successCount++;
        } catch (e) {
          // Step 6: Fail - Leave in table to retry later
          failedCount++;
          errors.add('Upload ${upload.id}: ${e.toString()}');
          // Continue to next upload
        }
      }

      _isSyncing = false;

      return SyncSummary(
        totalAttempted: pendingUploads.length,
        successCount: successCount,
        failedCount: failedCount,
        message: _buildSyncMessage(successCount, failedCount),
        errors: errors.isEmpty ? null : errors,
      );
    } catch (e) {
      _isSyncing = false;
      return SyncSummary(
        totalAttempted: 0,
        successCount: 0,
        failedCount: 0,
        message: 'Sync failed: ${e.toString()}',
        errors: [e.toString()],
      );
    }
  }

  /// Upload quiz session and answers to Supabase
  Future<void> _uploadToSupabase(
    QuizSession session,
    List<QuizAnswer> answers,
  ) async {
    // Insert quiz session first
    await _supabase.from('quiz_sessions').insert(session.toJson());

    // Insert all answers
    if (answers.isNotEmpty) {
      final answersJson = answers.map((a) => a.toJson()).toList();
      await _supabase.from('quiz_answers').insert(answersJson);
    }
  }

  /// Build user-friendly sync message
  String _buildSyncMessage(int successCount, int failedCount) {
    if (successCount == 0 && failedCount == 0) {
      return 'No results synced';
    } else if (successCount > 0 && failedCount == 0) {
      return '✅ Successfully synced $successCount result${successCount > 1 ? 's' : ''}';
    } else if (successCount == 0 && failedCount > 0) {
      return '⚠️ Failed to sync $failedCount result${failedCount > 1 ? 's' : ''}. Will retry later.';
    } else {
      return '✅ Synced $successCount, ⚠️ failed $failedCount. Will retry failed results later.';
    }
  }

  /// Get count of pending uploads
  Future<int> getPendingCount() async {
    final uploads = await _db.getAllPendingUploads();
    return uploads.length;
  }

  /// Check if sync is currently in progress
  bool get isSyncing => _isSyncing;

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

// ====== SYNC RESULT MODEL ======

class SyncSummary {
  final int totalAttempted;
  final int successCount;
  final int failedCount;
  final String message;
  final List<String>? errors;

  SyncSummary({
    required this.totalAttempted,
    required this.successCount,
    required this.failedCount,
    required this.message,
    this.errors,
  });

  bool get hasSuccess => successCount > 0;
  bool get hasFailures => failedCount > 0;
  bool get allSuccess => totalAttempted > 0 && failedCount == 0;
  bool get allFailed => totalAttempted > 0 && successCount == 0;

  @override
  String toString() => message;
}
