class HomeworkScore {
  final String id;
  final String homeworkSetId;
  final String userId;
  final String? sessionId;
  final String? userDisplayName;
  final String? userAvatarUrl;
  final int correctAnswers;
  final int wrongAnswers;
  final int skippedAnswers;
  final int totalQuestions;
  final double score;
  final int scorePercentage;
  final int? durationSeconds;
  final DateTime submittedAt;

  HomeworkScore({
    required this.id,
    required this.homeworkSetId,
    required this.userId,
    this.sessionId,
    this.userDisplayName,
    this.userAvatarUrl,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.skippedAnswers,
    required this.totalQuestions,
    required this.score,
    required this.scorePercentage,
    this.durationSeconds,
    required this.submittedAt,
  });

  factory HomeworkScore.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'];
    Map<String, dynamic>? profile;
    if (profileData is Map<String, dynamic>) {
      profile = profileData;
    } else if (profileData is List && profileData.isNotEmpty) {
      final first = profileData.first;
      if (first is Map<String, dynamic>) {
        profile = first;
      }
    }

    final correct = ((json['correct_count'] as num?) ??
            (json['correct_answers'] as num?) ??
            0)
        .toInt();
    final wrong =
        ((json['wrong_count'] as num?) ?? (json['wrong_answers'] as num?) ?? 0)
            .toInt();
    final unanswered = ((json['unanswered_count'] as num?) ??
            (json['skipped_answers'] as num?) ??
            0)
        .toInt();
    final total = ((json['total_questions'] as num?)?.toInt()) ??
        (correct + wrong + unanswered);
    final score = ((json['score'] as num?) ??
            (json['score_percentage'] as num?) ??
            0)
        .toDouble();

    return HomeworkScore(
      id: (json['id']).toString(),
      homeworkSetId: (json['homework_id'] ?? json['homework_set_id']).toString(),
      userId: (json['user_id']).toString(),
      sessionId: json['session_id']?.toString(),
      userDisplayName: (profile?['full_name'] as String?) ??
          (profile?['username'] as String?) ??
          json['user_name'] as String?,
      userAvatarUrl: profile?['avatar_url'] as String? ?? json['avatar_url'] as String?,
      correctAnswers: correct,
      wrongAnswers: wrong,
      skippedAnswers: unanswered,
      totalQuestions: total,
      score: score,
      scorePercentage: score.round(),
      durationSeconds:
          ((json['time_taken_seconds'] as num?) ?? (json['duration_seconds'] as num?))
              ?.toInt(),
      submittedAt: DateTime.parse(
        (json['submitted_at'] ?? DateTime.now().toIso8601String()) as String,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homework_id': homeworkSetId,
      'user_id': userId,
      'session_id': sessionId,
      'user_name': userDisplayName,
      'avatar_url': userAvatarUrl,
      'correct_count': correctAnswers,
      'wrong_count': wrongAnswers,
      'unanswered_count': skippedAnswers,
      'score': score,
      'time_taken_seconds': durationSeconds,
      'submitted_at': submittedAt.toIso8601String(),
    };
  }
}
