class VocabularyWord {
  final int id;
  final String wordIt;
  final String? translationEn;
  final String? translationBn;

  const VocabularyWord({
    required this.id,
    required this.wordIt,
    this.translationEn,
    this.translationBn,
  });

  factory VocabularyWord.fromJson(Map<String, dynamic> json) {
    return VocabularyWord(
      id: json['id'] as int,
      wordIt: json['word_it'] as String,
      translationEn: json['translation_en'] as String?,
      translationBn: json['translation_bn'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word_it': wordIt,
      'translation_en': translationEn,
      'translation_bn': translationBn,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is VocabularyWord && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
