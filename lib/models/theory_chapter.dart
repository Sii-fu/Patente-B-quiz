/// TheoryChapter model - Represents a lesson/chapter in the theory book
/// Matches the 'theory_chapters' table in Supabase
class TheoryChapter {
  final int id;
  final int? relatedQuizTopicId; // Optional link to quiz topics
  final String nameIt;
  final String? nameEn;
  final String? nameBn;
  final String? imageUrl;
  final int displayOrder;
  final DateTime createdAt;

  TheoryChapter({
    required this.id,
    this.relatedQuizTopicId,
    required this.nameIt,
    this.nameEn,
    this.nameBn,
    this.imageUrl,
    required this.displayOrder,
    required this.createdAt,
  });

  // Get localized name based on language code
  String getLocalizedName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return nameEn ?? nameIt;
      case 'bn':
        return nameBn ?? nameIt;
      default:
        return nameIt;
    }
  }

  // From JSON (Supabase)
  factory TheoryChapter.fromJson(Map<String, dynamic> json) {
    return TheoryChapter(
      id: json['id'] as int,
      relatedQuizTopicId: json['related_quiz_topic_id'] as int?,
      nameIt: json['name_it'] as String,
      nameEn: json['name_en'] as String?,
      nameBn: json['name_bn'] as String?,
      imageUrl: json['image_url'] as String?,
      displayOrder: json['display_order'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // To JSON (Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'related_quiz_topic_id': relatedQuizTopicId,
      'name_it': nameIt,
      'name_en': nameEn,
      'name_bn': nameBn,
      'image_url': imageUrl,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // From SQLite map
  factory TheoryChapter.fromMap(Map<String, dynamic> map) {
    return TheoryChapter(
      id: map['id'] as int,
      relatedQuizTopicId: map['related_quiz_topic_id'] as int?,
      nameIt: map['name_it'] as String,
      nameEn: map['name_en'] as String?,
      nameBn: map['name_bn'] as String?,
      imageUrl: map['image_url'] as String?,
      displayOrder: map['display_order'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // To SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'related_quiz_topic_id': relatedQuizTopicId,
      'name_it': nameIt,
      'name_en': nameEn,
      'name_bn': nameBn,
      'image_url': imageUrl,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'TheoryChapter(id: $id, nameIt: $nameIt, displayOrder: $displayOrder)';
  }
}
