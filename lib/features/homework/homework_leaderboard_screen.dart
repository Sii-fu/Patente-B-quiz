import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../models/homework_score.dart';
import '../../models/homework_set.dart';
import '../../repositories/homework_repository.dart';
import 'homework_localizations.dart';

class HomeworkLeaderboardScreen extends StatefulWidget {
  const HomeworkLeaderboardScreen({
    super.key,
    required this.homework,
  });

  final HomeworkSet homework;

  @override
  State<HomeworkLeaderboardScreen> createState() => _HomeworkLeaderboardScreenState();
}

class _HomeworkLeaderboardScreenState extends State<HomeworkLeaderboardScreen> {
  final HomeworkRepository _repository = HomeworkRepository();

  bool _isLoading = true;
  String? _error;
  List<HomeworkScore> _rows = <HomeworkScore>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final scores = await _repository.getHomeworkLeaderboard(widget.homework.id);
      if (!mounted) return;
      setState(() {
        _rows = scores;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatSeconds(int? seconds) {
    if (seconds == null || seconds <= 0) return '--:--';
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeworkLeaderboard),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: _load,
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                )
              : _rows.isEmpty
                  ? Center(child: Text(l10n.homeworkNoItems))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _rows.length,
                      itemBuilder: (context, index) {
                        final row = _rows[index];
                        final isMe = currentUserId != null && row.userId == currentUserId;
                        final displayName = (row.userDisplayName ?? '').trim().isEmpty
                            ? 'User ${row.userId.substring(0, 8)}'
                            : row.userDisplayName!.trim();

                        return Card(
                          color: isMe
                              ? theme.colorScheme.primaryContainer.withOpacity(0.45)
                              : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: (row.userAvatarUrl ?? '').isNotEmpty
                                  ? NetworkImage(row.userAvatarUrl!)
                                  : null,
                              child: (row.userAvatarUrl ?? '').isEmpty
                                  ? Text('${index + 1}')
                                  : null,
                            ),
                            title: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${l10n.homeworkRank}: ${index + 1} • ${l10n.resultTime}: ${_formatSeconds(row.durationSeconds)}',
                            ),
                            trailing: Text(
                              '${row.scorePercentage}%',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
