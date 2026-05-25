import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vocabulary_word.dart';
import '../models/question.dart';

/// Repository for the Vocabulary Dictionary feature.
/// - Online: Fetches from Supabase `vocabulary` table.
/// - Starred words: Persisted locally via SharedPreferences.
/// - Example questions: Queried via Supabase ILIKE filter on `questions.text_it`.
class VocabularyRepository {
  static const _starredKey = 'starred_vocabulary_ids';
  static Map<String, VocabularyWord>? _glossaryCache;

  final SupabaseClient _supabase;

  VocabularyRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  // ─── Vocabulary ──────────────────────────────────────────────────────────

  /// Fetches all vocabulary words ordered alphabetically by `word_it`.
  Future<List<VocabularyWord>> getVocabulary() async {
    final response = await _supabase
        .from('vocabulary')
        .select()
        .order('word_it', ascending: true);

    return (response as List)
        .map((json) => VocabularyWord.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Returns a lowercase lookup map keyed by `word_it` for glossary matching.
  Future<Map<String, VocabularyWord>> getGlossaryMap() async {
    final cached = _glossaryCache;
    if (cached != null) {
      return cached;
    }

    final words = await getVocabulary();
    final map = <String, VocabularyWord>{};
    for (final word in words) {
      final key = word.wordIt.toLowerCase().trim();
      if (key.isNotEmpty) {
        map[key] = word;
      }
    }

    _glossaryCache = map;
    return map;
  }

  // ─── Starred / Favorites ─────────────────────────────────────────────────

  /// Returns the set of starred vocabulary word IDs from local storage.
  Future<Set<int>> getStarredIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_starredKey) ?? [];
    return raw.map((s) => int.tryParse(s)).whereType<int>().toSet();
  }

  /// Returns whether a specific word is starred.
  Future<bool> isStarred(int wordId) async {
    final ids = await getStarredIds();
    return ids.contains(wordId);
  }

  /// Toggles the starred state for a word. Returns the new starred state.
  Future<bool> toggleStar(int wordId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_starredKey) ?? [];
    final ids = raw.map((s) => int.tryParse(s)).whereType<int>().toSet();

    final nowStarred = !ids.contains(wordId);
    if (nowStarred) {
      ids.add(wordId);
    } else {
      ids.remove(wordId);
    }
    await prefs.setStringList(_starredKey, ids.map((id) => id.toString()).toList());
    return nowStarred;
  }

  // ─── Dynamic Examples ────────────────────────────────────────────────────

  /// Queries the `questions` table for any question whose Italian text
  /// contains [word] (case-insensitive).
  Future<List<Question>> getQuestionsContainingWord(String word) async {
    final response = await _supabase
        .from('questions')
        .select()
        .ilike('text_it', '%$word%')
        .order('id', ascending: true);

    return (response as List)
        .map((q) => Question(
              id: q['id'] as int,
              subtopicId: q['subtopic_id'] as int?,
              textIt: q['text_it'] as String,
              textEn: q['text_en'] as String?,
              textBn: q['text_bn'] as String?,
              imageUrl: q['image_url'] as String?,
              isTrue: q['is_true'] as bool,
              explanationIt: q['explanation_it'] as String?,
              explanationEn: q['explanation_en'] as String?,
              explanationBn: q['explanation_bn'] as String?,
              difficultyLevel: q['difficulty_level'] as int? ?? 1,
              createdAt: DateTime.parse(q['created_at'] as String),
            ))
        .toList();
  }
}
