class Category {
  final int id;
  final String nameIt;
  final String? nameEn;
  final String? nameBn;
  final String? colorHex;
  final int? displayOrder;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.nameIt,
    this.nameEn,
    this.nameBn,
    this.colorHex,
    this.displayOrder,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      nameIt: json['name_it'] as String,
      nameEn: json['name_en'] as String?,
      nameBn: json['name_bn'] as String?,
      colorHex: json['color_hex'] as String?,
      displayOrder: json['display_order'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_it': nameIt,
      'name_en': nameEn,
      'name_bn': nameBn,
      'color_hex': colorHex,
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
