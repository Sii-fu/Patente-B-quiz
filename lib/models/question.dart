import 'subtopic.dart';

class Question {
  final int id;
  final int? topicId; // Legacy field, keeping for backward compatibility
  final int? subtopicId;
  final Subtopic? subtopic; // Populated when joining with subtopics table
  final String textIt;
  final String? textEn;
  final String? textBn;
  final String? imageUrl;
  final bool isTrue;
  final String? explanationIt;
  final String? explanationEn;
  final String? explanationBn;
  final String? explanationAudioUrl;
  final String? audioItUrl;
  final String? audioEnUrl;
  final String? audioBnUrl;
  final int difficultyLevel;
  final DateTime createdAt;

  Question({
    required this.id,
    this.topicId,
    this.subtopicId,
    this.subtopic,
    required this.textIt,
    this.textEn,
    this.textBn,
    this.imageUrl,
    required this.isTrue,
    this.explanationIt,
    this.explanationEn,
    this.explanationBn,
    this.explanationAudioUrl,
    this.audioItUrl,
    this.audioEnUrl,
    this.audioBnUrl,
    this.difficultyLevel = 1,
    required this.createdAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    Subtopic? subtopic;
    if (json['subtopic'] != null) {
      subtopic = Subtopic.fromJson(json['subtopic'] as Map<String, dynamic>);
    }

    return Question(
      id: json['id'] as int,
      topicId: json['topic_id'] as int?,
      subtopicId: json['subtopic_id'] as int?,
      subtopic: subtopic,
      textIt: json['text_it'] as String,
      textEn: json['text_en'] as String?,
      textBn: json['text_bn'] as String?,
      imageUrl: json['image_url'] as String?,
      isTrue: json['is_true'] as bool,
      explanationIt: json['explanation_it'] as String?,
      explanationEn: json['explanation_en'] as String?,
      explanationBn: json['explanation_bn'] as String?,
      explanationAudioUrl: json['explanation_audio_url'] as String?,
      audioItUrl: json['audio_it_url'] as String?,
      audioEnUrl: json['audio_en_url'] as String?,
      audioBnUrl: json['audio_bn_url'] as String?,
      difficultyLevel: json['difficulty_level'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic_id': topicId,
      'subtopic_id': subtopicId,
      'subtopic': subtopic?.toJson(),
      'text_it': textIt,
      'text_en': textEn,
      'text_bn': textBn,
      'image_url': imageUrl,
      'is_true': isTrue,
      'explanation_it': explanationIt,
      'explanation_en': explanationEn,
      'explanation_bn': explanationBn,
      'explanation_audio_url': explanationAudioUrl,
      'audio_it_url': audioItUrl,
      'audio_en_url': audioEnUrl,
      'audio_bn_url': audioBnUrl,
      'difficulty_level': difficultyLevel,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Get localized text based on language code
  String getText(String languageCode) {
    switch (languageCode) {
      case 'en':
        return _firstNonBlankString([textEn, textIt, textBn]) ?? '';
      case 'bn':
        return _firstNonBlankString([textBn, textIt, textEn]) ?? '';
      default:
        return _firstNonBlankString([textIt, textEn, textBn]) ?? '';
    }
  }

  // Get localized explanation
  String? getExplanation(String languageCode) {
    switch (languageCode) {
      case 'en':
        return _firstNonBlankString([explanationEn, explanationIt, explanationBn]);
      case 'bn':
        return _firstNonBlankString([explanationBn, explanationIt, explanationEn]);
      default:
        return _firstNonBlankString([explanationIt, explanationEn, explanationBn]);
    }
  }

  // Get localized audio URL for question text
  String? getAudioUrl(String languageCode) {
    switch (languageCode) {
      case 'en':
        return _firstNonBlankString([audioEnUrl, audioItUrl, audioBnUrl]);
      case 'bn':
        return _firstNonBlankString([audioBnUrl, audioItUrl, audioEnUrl]);
      default:
        return _firstNonBlankString([audioItUrl, audioEnUrl, audioBnUrl]);
    }
  }

  static String? _firstNonBlankString(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }
}
