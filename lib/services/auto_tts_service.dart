import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Generates MP3 audio via Google Translate's TTS endpoint and uploads it
/// to the `quiz_audio` Supabase Storage bucket.
class AutoTtsService {
  static const String _bucket = 'quiz_audio';

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, String?>> generateAndUploadAudio({
    required int questionId,
    String? textIt,
    String? textEn,
    String? textBn,
  }) async {
    final result = <String, String?>{
      'audio_it_url': null,
      'audio_en_url': null,
      'audio_bn_url': null,
    };

    final texts = {
      'it': textIt,
      'en': textEn,
      'bn': textBn,
    };

    for (final entry in texts.entries) {
      final langCode = entry.key;
      final text = entry.value;
      if (text == null || text.trim().isEmpty) continue;

      final url = await _generateAndUploadForLanguage(
        questionId: questionId,
        text: text,
        langCode: langCode,
      );

      result['audio_${langCode}_url'] = url;
    }

    return result;
  }

  Future<String?> _generateAndUploadForLanguage({
    required int questionId,
    required String text,
    required String langCode,
  }) async {
    try {
      final ttsUrl = Uri.parse(
        'https://translate.google.com/translate_tts'
        '?ie=UTF-8&q=${Uri.encodeComponent(text)}&tl=$langCode&client=tw-ob',
      );

      final response = await http.get(ttsUrl);

      if (response.statusCode != 200) {
        debugPrint(
          'AutoTtsService: TTS request failed for $langCode (status ${response.statusCode})',
        );
        return null;
      }

      final bytes = response.bodyBytes;
      final fileName = 'q_${questionId}_$langCode.mp3';

      await _supabase.storage.from(_bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'audio/mpeg',
            ),
          );

      return _supabase.storage.from(_bucket).getPublicUrl(fileName);
    } catch (e) {
      debugPrint('AutoTtsService: Error generating/uploading $langCode audio: $e');
      return null;
    }
  }
}
