class Profile {
  final String id;
  final String? fullName;
  final String? username;
  final String? avatarUrl;
  final String licenseType;
  final bool isVerified;
  final DateTime? verifiedUntil;
  final int xp;
  final int currentLevel;
  final int dailyStreak;
  final DateTime? lastStudyDate;
  final int totalQuizzesTaken;
  final double averageScore;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String role; // 'user' or 'admin'

  Profile({
    required this.id,
    this.fullName,
    this.username,
    this.avatarUrl,
    this.licenseType = 'B',
    this.isVerified = false,
    this.verifiedUntil,
    this.xp = 0,
    this.currentLevel = 1,
    this.dailyStreak = 0,
    this.lastStudyDate,
    this.totalQuizzesTaken = 0,
    this.averageScore = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.role = 'user',
  });

  bool get isAdmin => role == 'admin';

  /// True when the account is approved AND the course period has not ended.
  /// A null [verifiedUntil] means lifetime access.
  bool get isAccessValid =>
      isVerified && (verifiedUntil == null || verifiedUntil!.isAfter(DateTime.now()));

  /// True only for an approved account whose course period has already ended.
  /// Distinguishes "expired" from "never approved" for the access gates.
  bool get isAccessExpired =>
      isVerified && verifiedUntil != null && !verifiedUntil!.isAfter(DateTime.now());

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      licenseType: json['license_type'] as String? ?? 'B',
      isVerified: json['is_verified'] as bool? ?? false,
      verifiedUntil: json['verified_until'] != null
          ? DateTime.parse(json['verified_until'] as String)
          : null,
      xp: json['xp'] as int? ?? 0,
      currentLevel: json['current_level'] as int? ?? 1,
      dailyStreak: json['daily_streak'] as int? ?? 0,
      lastStudyDate: json['last_study_date'] != null
          ? DateTime.parse(json['last_study_date'] as String)
          : null,
      totalQuizzesTaken: json['total_quizzes_taken'] as int? ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      role: json['role'] as String? ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'avatar_url': avatarUrl,
      'license_type': licenseType,
      'is_verified': isVerified,
      'verified_until': verifiedUntil?.toIso8601String(),
      'xp': xp,
      'current_level': currentLevel,
      'daily_streak': dailyStreak,
      'last_study_date': lastStudyDate?.toIso8601String(),
      'total_quizzes_taken': totalQuizzesTaken,
      'average_score': averageScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'role': role,
    };
  }

  Profile copyWith({
    String? id,
    String? fullName,
    String? username,
    String? avatarUrl,
    String? licenseType,
    bool? isVerified,
    DateTime? verifiedUntil,
    int? xp,
    int? currentLevel,
    int? dailyStreak,
    DateTime? lastStudyDate,
    int? totalQuizzesTaken,
    double? averageScore,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? role,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      licenseType: licenseType ?? this.licenseType,
      isVerified: isVerified ?? this.isVerified,
      verifiedUntil: verifiedUntil ?? this.verifiedUntil,
      xp: xp ?? this.xp,
      currentLevel: currentLevel ?? this.currentLevel,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      totalQuizzesTaken: totalQuizzesTaken ?? this.totalQuizzesTaken,
      averageScore: averageScore ?? this.averageScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
    );
  }
}
