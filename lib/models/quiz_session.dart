enum QuizMode { simulation, topic, reviewErrors }

class QuizSession {
  final String id;
  final String userId;
  final QuizMode mode;
  final int totalQuestions;
  final int? errorsCount;
  final bool? isPassed;
  final int? durationSeconds;
  final DateTime createdAt;

  QuizSession({
    required this.id,
    required this.userId,
    required this.mode,
    this.totalQuestions = 30,
    this.errorsCount,
    this.isPassed,
    this.durationSeconds,
    required this.createdAt,
  });

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    return QuizSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mode: _parseModeFromString(json['mode'] as String),
      totalQuestions: json['total_questions'] as int? ?? 30,
      errorsCount: json['errors_count'] as int?,
      isPassed: json['is_passed'] as bool?,
      durationSeconds: json['duration_seconds'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mode': _modeToString(mode),
      'total_questions': totalQuestions,
      'errors_count': errorsCount,
      'is_passed': isPassed,
      'duration_seconds': durationSeconds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static QuizMode _parseModeFromString(String mode) {
    switch (mode) {
      case 'simulation':
        return QuizMode.simulation;
      case 'topic':
        return QuizMode.topic;
      case 'review_errors':
        return QuizMode.reviewErrors;
      default:
        return QuizMode.simulation;
    }
  }

  static String _modeToString(QuizMode mode) {
    switch (mode) {
      case QuizMode.simulation:
        return 'simulation';
      case QuizMode.topic:
        return 'topic';
      case QuizMode.reviewErrors:
        return 'review_errors';
    }
  }

  QuizSession copyWith({
    String? id,
    String? userId,
    QuizMode? mode,
    int? totalQuestions,
    int? errorsCount,
    bool? isPassed,
    int? durationSeconds,
    DateTime? createdAt,
  }) {
    return QuizSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mode: mode ?? this.mode,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      errorsCount: errorsCount ?? this.errorsCount,
      isPassed: isPassed ?? this.isPassed,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class QuizAnswer {
  final int id;
  final String sessionId;
  final String userId;
  final int questionId;
  final bool selectedTrue;
  final bool isCorrect;
  final DateTime createdAt;

  QuizAnswer({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.questionId,
    required this.selectedTrue,
    required this.isCorrect,
    required this.createdAt,
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      id: json['id'] as int,
      sessionId: json['session_id'] as String,
      userId: json['user_id'] as String,
      questionId: json['question_id'] as int,
      selectedTrue: json['selected_true'] as bool,
      isCorrect: json['is_correct'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'question_id': questionId,
      'selected_true': selectedTrue,
      'is_correct': isCorrect,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
