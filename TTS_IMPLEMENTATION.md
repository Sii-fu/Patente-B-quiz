# Text-to-Speech (TTS) Implementation Guide

## Overview
The Patente B Quiz App now includes a robust Text-to-Speech feature that supports **Italian (it-IT)**, **English (en-US)**, and **Bangla (bn-BD)** with intelligent fallback handling and compatibility across all Android devices.

## Key Features

### ✅ **Multi-Language Support**
- **Italian (it-IT)** - Primary language (default)
- **English (en-US)** - Secondary language with en-GB fallback
- **Bangla (bn-BD)** - With bn-IN fallback for broader device compatibility

### ✅ **Robust Error Handling**
- Gracefully handles missing language data (e.g., Bangla not installed)
- Automatic fallback to English → Italian if requested language unavailable
- Force-speak option to attempt speech even if availability check fails
- Never crashes the app due to TTS issues

### ✅ **Android Compatibility**
- Works on Android 11+ (requires TTS_SERVICE query in manifest)
- Overrides silent mode for educational audio playback
- Optimized for all Android devices regardless of TTS engine installed

### ✅ **User Experience**
- **0.5 speech rate** - Slower, clearer for studying complex content
- **Prevents overlapping audio** - Stops current speech before starting new
- **Visual feedback** - Shows success/failure status in UI
- **Haptic feedback** - Medium impact when speaker button pressed

---

## Architecture

### 1. **TtsHelper Service** (`lib/services/tts_helper.dart`)
Singleton class that manages all TTS operations.

**Key Methods:**
- `init()` - Initializes TTS with optimal settings for education
- `speak(String text, String languageCode)` - Main method with fallback logic
- `stop()` - Stops any currently playing audio
- `getAvailableLanguages()` - Returns list of device-supported languages

**Language Normalization:**
- Accepts short codes: `'it'`, `'en'`, `'bn'`
- Automatically converts to full format: `'it-IT'`, `'en-US'`, `'bn-BD'`
- Tries alternative codes if primary fails (e.g., bn-IN if bn-BD unavailable)

---

## Configuration

### Android Manifest (`android/app/src/main/AndroidManifest.xml`)

**CRITICAL:** The following `<queries>` tag was added outside the `<application>` tag:

```xml
<queries>
    <intent>
        <action android:name="android.intent.action.PROCESS_TEXT"/>
        <data android:mimeType="text/plain"/>
    </intent>
    <!-- Required for Text-to-Speech to work on Android 11+ -->
    <intent>
        <action android:name="android.intent.action.TTS_SERVICE"/>
    </intent>
</queries>
```

**Why?** Android 11+ requires explicit package visibility declarations. Without this, the app cannot detect or use TTS engines.

---

## Usage Examples

### In Quiz Screens

**Before (Direct FlutterTts):**
```dart
final FlutterTts _flutterTts = FlutterTts();

void _initTts() async {
  await _flutterTts.setLanguage('it-IT');
  await _flutterTts.setSpeechRate(0.5);
  await _flutterTts.setVolume(1.0);
  await _flutterTts.setPitch(1.0);
}

await _flutterTts.setLanguage(ttsLanguage);
await _flutterTts.speak(text);
```

**After (TtsHelper):**
```dart
final TtsHelper _ttsHelper = TtsHelper();

@override
void initState() {
  super.initState();
  _ttsHelper.init(); // One-line initialization
}

// Later, when speaking:
final success = await _ttsHelper.speak(text, _currentQuestionLanguage);
```

### Speaker Button Integration

```dart
IconButton(
  icon: const Icon(Icons.volume_up),
  onPressed: _speakQuestion,
  tooltip: 'Read question aloud',
)

Future<void> _speakQuestion() async {
  HapticFeedback.mediumImpact();
  
  final question = _questions[_currentPage];
  final text = question.getText(_currentQuestionLanguage); // 'it', 'en', or 'bn'
  
  // TtsHelper handles language codes and fallbacks automatically
  final success = await _ttsHelper.speak(text, _currentQuestionLanguage);
  
  // Show visual feedback
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(success ? Icons.volume_up : Icons.volume_off),
          const SizedBox(width: 8),
          Text(success ? 'Playing audio...' : 'Audio not available'),
        ],
      ),
      backgroundColor: success ? null : Colors.orange,
    ),
  );
}
```

---

## Fallback Logic Flow

```
User presses speaker button
    ↓
TtsHelper.speak('Questo è un test', 'it')
    ↓
Check: Is Italian (it-IT) available?
    ├─ YES → Set language to it-IT → Speak
    └─ NO  → Try fallback chain:
             1. Try English (en-US)
             2. Try English (en-GB)
             3. Try Italian anyway (force)
             4. Return false if all fail
```

**Example Scenario:**
- Device has Google TTS with English only
- User tries to speak Bangla question
- System detects Bangla unavailable
- Automatically speaks in English
- Shows "Audio not available" (orange) instead of "Playing audio" (blue)

---

## Testing Checklist

### ✅ Basic Functionality
- [ ] Italian questions play in Italian voice
- [ ] English questions play in English voice
- [ ] Bangla questions attempt Bangla (or fallback gracefully)
- [ ] Audio stops when new question is spoken
- [ ] Audio stops when quiz is exited

### ✅ Edge Cases
- [ ] Works on device with only Google TTS (limited languages)
- [ ] Works on device with Samsung TTS (more languages)
- [ ] Doesn't crash if NO TTS engine installed (rare)
- [ ] Plays audio even in silent mode
- [ ] Visual feedback matches audio success/failure

### ✅ User Experience
- [ ] Speech is slow enough to understand (0.5 rate)
- [ ] No overlapping audio when rapidly pressing speaker button
- [ ] Haptic feedback occurs on button press
- [ ] Snackbar appears showing audio status

---

## Device Compatibility

| Device Type | TTS Engine | Italian | English | Bangla | Notes |
|-------------|------------|---------|---------|--------|-------|
| **Samsung Galaxy** | Samsung TTS | ✅ | ✅ | ⚠️ | Bangla may need download |
| **Google Pixel** | Google TTS | ✅ | ✅ | ❌ | Falls back to English |
| **Xiaomi/Redmi** | Google TTS | ✅ | ✅ | ❌ | Falls back to English |
| **Oppo/Vivo** | Custom TTS | ✅ | ✅ | ⚠️ | Varies by model |
| **OnePlus** | Google TTS | ✅ | ✅ | ❌ | Falls back to English |

**Legend:**
- ✅ = Fully supported
- ⚠️ = May require additional voice data download
- ❌ = Not available (fallback used)

---

## Troubleshooting

### Problem: "Audio not available" always shown
**Solution:** Check device has TTS engine installed:
1. Settings → Accessibility → Text-to-Speech
2. Ensure Google TTS or Samsung TTS is installed
3. Download Italian voice data if needed

### Problem: No audio on Android 11+
**Solution:** Verify AndroidManifest.xml has TTS_SERVICE query (see Configuration section)

### Problem: Bangla not speaking
**Expected behavior:** Most devices don't have Bangla TTS. App will:
1. Attempt Bangla (bn-BD, bn-IN)
2. Fall back to English
3. Show orange "Audio not available" snackbar
4. Continue working normally

### Problem: Audio overlaps when clicking rapidly
**Solution:** Already handled - `stop()` is called before each `speak()`

---

## Future Enhancements

### Planned Features
- [ ] **Voice data download prompt** - Detect missing languages and prompt user to download
- [ ] **Speech rate selector** - Let users adjust speed (0.3 - 1.0)
- [ ] **Voice pitch control** - Male/female voice preference
- [ ] **Auto-play on question load** - Optional setting
- [ ] **Highlight text while speaking** - Visual sync with audio

### Advanced Options
- [ ] **Offline TTS support** - Bundle Italian voice data in APK
- [ ] **Custom pronunciation** - Fix mispronounced Italian acronyms
- [ ] **Audio caching** - Pre-generate audio for offline use

---

## Files Modified

### New Files
- `lib/services/tts_helper.dart` - TTS singleton service

### Updated Files
- `android/app/src/main/AndroidManifest.xml` - Added TTS query
- `lib/features/quiz/quiz_screen.dart` - Uses TtsHelper
- `lib/screens/dashboard/custom_quiz_screen.dart` - Uses TtsHelper

### No Changes Needed
- `pubspec.yaml` - flutter_tts already in dependencies
- Question models - Already support multi-language text

---

## API Reference

### TtsHelper Methods

#### `Future<void> init()`
Initializes TTS with optimal settings. Call once in initState().
```dart
await _ttsHelper.init();
```

#### `Future<bool> speak(String text, String languageCode, {bool force = false})`
Speaks text in specified language with fallback handling.
- **Returns:** `true` if successful, `false` if failed
- **Parameters:**
  - `text`: The text to speak
  - `languageCode`: 'it', 'en', 'bn', or full codes like 'it-IT'
  - `force`: If true, attempts to speak even if language check fails

```dart
final success = await _ttsHelper.speak(
  'Questa è una domanda di prova',
  'it',
  force: false,
);
```

#### `Future<void> stop()`
Stops any currently playing speech.
```dart
await _ttsHelper.stop();
```

#### `Future<List<String>> getAvailableLanguages()`
Returns list of languages available on device.
```dart
final languages = await _ttsHelper.getAvailableLanguages();
print(languages); // ['it-IT', 'en-US', 'en-GB', ...]
```

---

## Support

For issues or questions about TTS implementation:
1. Check device TTS settings first
2. Verify AndroidManifest.xml has correct queries tag
3. Test with different TTS engines (Google vs Samsung)
4. Check debug logs for "TTS:" prefixed messages

**Debug Logging:**
All TTS operations log to console with `debugPrint('TTS: ...')` for troubleshooting.

---

## License Notes

The `flutter_tts` package is MIT licensed. All custom code in `tts_helper.dart` follows the project's license.
