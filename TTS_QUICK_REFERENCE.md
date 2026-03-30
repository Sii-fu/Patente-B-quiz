# 🎙️ TTS Quick Reference Card

## Import
```dart
import '../services/tts_helper.dart';
```

## Basic Setup (3 Steps)

### 1. Create Instance
```dart
final TtsHelper _ttsHelper = TtsHelper();
```

### 2. Initialize
```dart
@override
void initState() {
  super.initState();
  _ttsHelper.init();
}
```

### 3. Cleanup
```dart
@override
void dispose() {
  _ttsHelper.stop();
  super.dispose();
}
```

## Usage

### Simple Speak
```dart
await _ttsHelper.speak('Questa è una domanda', 'it');
```

### With Success Check
```dart
final success = await _ttsHelper.speak(text, 'it');
if (success) {
  print('Audio playing');
} else {
  print('Audio failed');
}
```

### In Button Handler
```dart
IconButton(
  icon: const Icon(Icons.volume_up),
  onPressed: () async {
    HapticFeedback.mediumImpact();
    final success = await _ttsHelper.speak(questionText, 'it');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Playing...' : 'Not available'),
        backgroundColor: success ? null : Colors.orange,
      ),
    );
  },
)
```

## Language Codes

| Code | Language | Full Code | Availability |
|------|----------|-----------|--------------|
| `'it'` | Italian | it-IT | ✅ Common |
| `'en'` | English | en-US | ✅ Common |
| `'bn'` | Bangla | bn-BD | ⚠️ Rare |

## Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `init()` | `Future<void>` | Initialize with optimal settings |
| `speak(text, lang)` | `Future<bool>` | Speak text, returns success |
| `stop()` | `Future<void>` | Stop current audio |
| `getAvailableLanguages()` | `Future<List<String>>` | Get device languages |

## Settings

Default values (optimized for learning):
- **Speech Rate:** 0.5 (slow & clear)
- **Volume:** 1.0 (maximum)
- **Pitch:** 1.0 (normal)

## Fallback Chain

```
Requested Language
    ↓ (not available)
English (en-US)
    ↓ (not available)
Italian (it-IT)
    ↓ (not available)
Force Speak (may work)
    ↓ (fails)
Return false
```

## Common Patterns

### With Language Selector
```dart
String _currentLang = 'it';

// Speak button
await _ttsHelper.speak(text, _currentLang);

// Language cycle
void _cycleLanguage() {
  setState(() {
    _currentLang = _currentLang == 'it' 
        ? 'en' 
        : _currentLang == 'en' ? 'bn' : 'it';
  });
}
```

### Stop Before Exit
```dart
@override
void deactivate() {
  _ttsHelper.stop();
  super.deactivate();
}
```

### Check Availability
```dart
final languages = await _ttsHelper.getAvailableLanguages();
final hasItalian = languages.any((l) => l.contains('it'));
```

## Troubleshooting

### No audio?
1. Check device TTS: Settings → Accessibility → Text-to-Speech
2. Install Google TTS from Play Store
3. Download Italian voice data

### Wrong language?
- Use full codes: `'it-IT'` not `'ita'`
- Check device language settings

### Audio overlaps?
- Already handled automatically
- `stop()` called before each `speak()`

## Android Requirements

**AndroidManifest.xml must have:**
```xml
<queries>
    <intent>
        <action android:name="android.intent.action.TTS_SERVICE"/>
    </intent>
</queries>
```
✅ Already added!

## Tips

✅ **DO:**
- Initialize once in initState
- Stop in dispose
- Check return value of speak()
- Use short language codes ('it', 'en', 'bn')

❌ **DON'T:**
- Create multiple TtsHelper instances
- Forget to stop() on dispose
- Hardcode language without fallback
- Call speak() without init()

---

**Need help?** Check `TTS_IMPLEMENTATION.md` for full documentation.
