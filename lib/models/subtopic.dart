class Subtopic {
  final int id;
  final int topicId;
  final String nameIt;
  final String? nameEn;
  final String? nameBn;
  final String? imageUrl;
  final int? displayOrder;
  final DateTime createdAt;

  Subtopic({
    required this.id,
    required this.topicId,
    required this.nameIt,
    this.nameEn,
    this.nameBn,
    this.imageUrl,
    this.displayOrder,
    required this.createdAt,
  });

  factory Subtopic.fromJson(Map<String, dynamic> json) {
    return Subtopic(
      id: json['id'] as int,
      topicId: json['topic_id'] as int,
      nameIt: json['name_it'] as String,
      nameEn: json['name_en'] as String?,
      nameBn: json['name_bn'] as String?,
      imageUrl: json['image_url'] as String?,
      displayOrder: json['display_order'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic_id': topicId,
      'name_it': nameIt,
      'name_en': nameEn,
      'name_bn': nameBn,
      'image_url': imageUrl,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Get localized name based on language code
  String getName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return nameEn ?? nameIt;
      case 'bn':
        return nameBn ?? nameIt;
      default:
        return nameIt;
    }
  }
}
