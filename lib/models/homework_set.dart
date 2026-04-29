class HomeworkSet {
  final String id;
  final String title;
  final String? description;
  final int timeLimitMinutes;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool shuffleQuestions;
  final bool retryAllowed;
  final String status;
  final bool isDraft;
  final String? createdBy;
  final DateTime createdAt;
  final int? questionCount;
  final int submissionCount;

  HomeworkSet({
    required this.id,
    required this.title,
    this.description,
    required this.timeLimitMinutes,
    this.startsAt,
    this.endsAt,
    required this.shuffleQuestions,
    required this.retryAllowed,
    this.status = 'draft',
    bool? isDraft,
    this.createdBy,
    required this.createdAt,
    this.questionCount,
    this.submissionCount = 0,
  }) : isDraft = isDraft ?? status == 'draft';

  factory HomeworkSet.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] as String?)?.toLowerCase() ??
        (((json['is_draft'] as bool?) ?? false) ? 'draft' : 'active');

    return HomeworkSet(
      id: (json['id']).toString(),
      title: (json['title'] ?? '') as String,
      description: json['description'] as String?,
      timeLimitMinutes: (json['time_limit_minutes'] as int?) ?? 20,
      startsAt: json['start_at'] != null
          ? DateTime.parse(json['start_at'] as String)
          : json['starts_at'] != null
              ? DateTime.parse(json['starts_at'] as String)
          : null,
      endsAt: json['end_at'] != null
          ? DateTime.parse(json['end_at'] as String)
          : json['ends_at'] != null
              ? DateTime.parse(json['ends_at'] as String)
          : null,
      shuffleQuestions: (json['shuffle_questions'] as bool?) ?? true,
      retryAllowed: (json['retry_allowed'] as bool?) ?? false,
      status: status,
      isDraft: status == 'draft',
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(
        (json['created_at'] ?? DateTime.now().toIso8601String()) as String,
      ),
      questionCount: (json['question_count'] as num?)?.toInt(),
      submissionCount: (json['submission_count'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'time_limit_minutes': timeLimitMinutes,
      'start_at': startsAt?.toIso8601String(),
      'end_at': endsAt?.toIso8601String(),
      'shuffle_questions': shuffleQuestions,
      'retry_allowed': retryAllowed,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'question_count': questionCount,
      'submission_count': submissionCount,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'title': title,
      'description': description,
      'time_limit_minutes': timeLimitMinutes,
      'start_at': startsAt?.toIso8601String(),
      'end_at': endsAt?.toIso8601String(),
      'shuffle_questions': shuffleQuestions,
      'retry_allowed': retryAllowed,
      'status': status,
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  HomeworkLifecycle get lifecycle {
    switch (status) {
      case 'draft':
        return HomeworkLifecycle.draft;
      case 'scheduled':
        return HomeworkLifecycle.upcoming;
      case 'active':
        return HomeworkLifecycle.active;
      case 'completed':
        return HomeworkLifecycle.completed;
      default:
        final now = DateTime.now();
        if (isDraft) return HomeworkLifecycle.draft;
        if (startsAt != null && startsAt!.isAfter(now)) {
          return HomeworkLifecycle.upcoming;
        }
        if (endsAt != null && endsAt!.isBefore(now)) {
          return HomeworkLifecycle.completed;
        }
        return HomeworkLifecycle.active;
    }
  }
}

enum HomeworkLifecycle {
  draft,
  upcoming,
  active,
  completed,
}
