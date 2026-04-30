/// TheoryCard model - Represents a single theory content card (e.g., DOSSO, CUNETTA)
/// Matches the 'theory_cards' table in Supabase
int _parseDisplayOrder(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class TheoryCard {
  final int id;
  final int chapterId;
  final int? subtopicId;
  final String? titleIt;
  final String? titleEn;
  final String? titleBn;
  final String textIt;
  final String? textEn;
  final String? textBn;
  final String? imageUrl;
  final String? audioExplanationUrl;
  final String? audioItUrl;
  final String? audioEnUrl;
  final String? audioBnUrl;
  final int displayOrder;
  final DateTime createdAt;

  TheoryCard({
    required this.id,
    required this.chapterId,
    this.subtopicId,
    this.titleIt,
    this.titleEn,
    this.titleBn,
    required this.textIt,
    this.textEn,
    this.textBn,
    this.imageUrl,
    this.audioExplanationUrl,
    this.audioItUrl,
    this.audioEnUrl,
    this.audioBnUrl,
    required this.displayOrder,
    required this.createdAt,
  });

  // Get localized title based on language code
  String? getLocalizedTitle(String languageCode) {
    switch (languageCode) {
      case 'en':
        return titleEn ?? titleIt;
      case 'bn':
        return titleBn ?? titleIt;
      default:
        return titleIt;
    }
  }

  // Get localized text based on language code
  String getLocalizedText(String languageCode) {
    switch (languageCode) {
      case 'en':
        return textEn ?? textIt;
      case 'bn':
        return textBn ?? textIt;
      default:
        return textIt;
    }
  }

  // Get localized audio URL based on language code
  String? getLocalizedAudioUrl(String languageCode) {
    switch (languageCode) {
      case 'en':
        return audioEnUrl ?? audioItUrl ?? audioBnUrl;
      case 'bn':
        return audioBnUrl ?? audioItUrl ?? audioEnUrl;
      default:
        return audioItUrl ?? audioEnUrl ?? audioBnUrl;
    }
  }

  // From JSON (Supabase)
  factory TheoryCard.fromJson(Map<String, dynamic> json) {
    return TheoryCard(
      id: json['id'] as int,
      chapterId: json['chapter_id'] as int,
      subtopicId: json['subtopic_id'] as int?,
      titleIt: json['title_it'] as String?,
      titleEn: json['title_en'] as String?,
      titleBn: json['title_bn'] as String?,
      textIt: json['text_it'] as String,
      textEn: json['text_en'] as String?,
      textBn: json['text_bn'] as String?,
      imageUrl: json['image_url'] as String?,
      audioExplanationUrl: json['audio_explanation_url'] as String?,
      audioItUrl: json['audio_it_url'] as String?,
      audioEnUrl: json['audio_en_url'] as String?,
      audioBnUrl: json['audio_bn_url'] as String?,
      displayOrder: _parseDisplayOrder(json['display_order']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // To JSON (Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chapter_id': chapterId,
      'subtopic_id': subtopicId,
      'title_it': titleIt,
      'title_en': titleEn,
      'title_bn': titleBn,
      'text_it': textIt,
      'text_en': textEn,
      'text_bn': textBn,
      'image_url': imageUrl,
      'audio_explanation_url': audioExplanationUrl,
      'audio_it_url': audioItUrl,
      'audio_en_url': audioEnUrl,
      'audio_bn_url': audioBnUrl,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // From SQLite map
  factory TheoryCard.fromMap(Map<String, dynamic> map) {
    return TheoryCard(
      id: map['id'] as int,
      chapterId: map['chapter_id'] as int,
      subtopicId: map['subtopic_id'] as int?,
      titleIt: map['title_it'] as String?,
      titleEn: map['title_en'] as String?,
      titleBn: map['title_bn'] as String?,
      textIt: map['text_it'] as String,
      textEn: map['text_en'] as String?,
      textBn: map['text_bn'] as String?,
      imageUrl: map['image_url'] as String?,
      audioExplanationUrl: map['audio_explanation_url'] as String?,
      audioItUrl: map['audio_it_url'] as String?,
      audioEnUrl: map['audio_en_url'] as String?,
      audioBnUrl: map['audio_bn_url'] as String?,
      displayOrder: _parseDisplayOrder(map['display_order']),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // To SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapter_id': chapterId,
      'subtopic_id': subtopicId,
      'title_it': titleIt,
      'title_en': titleEn,
      'title_bn': titleBn,
      'text_it': textIt,
      'text_en': textEn,
      'text_bn': textBn,
      'image_url': imageUrl,
      'audio_explanation_url': audioExplanationUrl,
      'audio_it_url': audioItUrl,
      'audio_en_url': audioEnUrl,
      'audio_bn_url': audioBnUrl,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'TheoryCard(id: $id, chapterId: $chapterId, subtopicId: $subtopicId, titleIt: $titleIt)';
  }
}
