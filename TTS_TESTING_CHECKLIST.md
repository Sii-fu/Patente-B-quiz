# TTS Testing Checklist

## ✅ Pre-Testing Setup

- [ ] Run `flutter pub get` to ensure flutter_tts is installed
- [ ] Build app: `flutter build apk` or `flutter run`
- [ ] Install on physical Android device (emulator TTS is unreliable)
- [ ] Enable Developer Options on test device

## 📱 Device Requirements Test

### Check TTS Engine Installed
1. [ ] Go to: Settings → Accessibility → Text-to-Speech
2. [ ] Verify TTS engine is installed (Google TTS, Samsung TTS, etc.)
3. [ ] Check Italian voice data is downloaded
4. [ ] Test TTS in system settings (should speak sample text)

## 🧪 Functional Tests

### Basic Functionality
- [ ] **Test 1:** Open Quiz Screen → Press speaker button
  - ✅ Expected: Audio plays in Italian
  - ✅ Expected: "Playing audio..." snackbar appears
  - ✅ Expected: Haptic feedback occurs

- [ ] **Test 2:** Change language to English → Press speaker
  - ✅ Expected: Audio plays in English voice
  - ✅ Expected: Snackbar confirms playback

- [ ] **Test 3:** Change language to Bangla → Press speaker
  - ⚠️ Expected: Either Bangla plays OR
  - ⚠️ Expected: Falls back to English with orange "Audio not available"

### Stop Functionality
- [ ] **Test 4:** Press speaker → Immediately press speaker again
  - ✅ Expected: First audio stops
  - ✅ Expected: Second audio starts
  - ❌ NO audio overlap

- [ ] **Test 5:** Press speaker → Navigate back while speaking
  - ✅ Expected: Audio stops when leaving screen
  - ❌ NO audio continues in background

### Silent Mode Override
- [ ] **Test 6:** Put device in silent mode
  - ✅ Expected: Audio STILL plays (educational override)
  - Note: This is critical for study apps!

### Error Handling
- [ ] **Test 7:** Uninstall TTS engine (if possible)
  - ⚠️ Expected: App doesn't crash
  - ⚠️ Expected: Orange "Audio not available" appears
  - ✅ Expected: Other features work normally

## 🌐 Multi-Language Tests

### Italian (Primary Language)
- [ ] Quiz with Italian questions
- [ ] Speaker button plays Italian
- [ ] No errors in console
- [ ] Speech is slow (0.5 rate) and clear

### English (Secondary Language)
- [ ] Switch to English language mode
- [ ] Speaker button plays English
- [ ] Fallback works if Italian unavailable

### Bangla (Tertiary Language)
- [ ] Switch to Bangla mode
- [ ] Speaker button attempts Bangla
- [ ] If unavailable: Falls back gracefully
- [ ] Orange alert shown (not crash)

## 🎯 Edge Cases

### Rapid Input
- [ ] **Test 8:** Click speaker button 10 times rapidly
  - ✅ Expected: No overlap
  - ✅ Expected: Latest click takes priority
  - ✅ Expected: No lag or freeze

### Long Text
- [ ] **Test 9:** Question with very long text (100+ words)
  - ✅ Expected: Audio starts playing
  - ✅ Expected: Can interrupt with stop()
  - ✅ Expected: Snackbar appears immediately

### Empty Text
- [ ] **Test 10:** Pass empty string to speak()
  - ✅ Expected: Returns false
  - ✅ Expected: No audio plays
  - ✅ Expected: No crash

### Network Loss
- [ ] **Test 11:** Disable WiFi/Data during quiz
  - ✅ Expected: TTS still works (local engine)
  - ✅ Expected: No network dependency

## 📊 Performance Tests

### Memory
- [ ] **Test 12:** Play audio 50 times in a row
  - ✅ Expected: No memory leak
  - ✅ Expected: Performance stays consistent
  - ✅ Expected: App doesn't slow down

### Battery
- [ ] **Test 13:** Use TTS continuously for 5 minutes
  - ℹ️ Note: Battery drain (expected for audio)
  - ✅ Expected: No excessive drain beyond audio playback

## 🔊 Audio Quality Tests

### Speech Rate
- [ ] Audio is slower than normal speech
- [ ] Every word is clearly distinguishable
- [ ] Rate feels appropriate for studying (0.5x)

### Volume
- [ ] Audio is audible at maximum volume setting
- [ ] No distortion at high volume
- [ ] Overrides silent mode properly

### Pronunciation
- [ ] Italian words pronounced correctly
- [ ] English words pronounced correctly
- [ ] Technical terms (e.g., "autoveicoli") clear

## 📱 Device Compatibility Matrix

Test on different Android versions:

| Device Type | Android Version | TTS Engine | Result |
|-------------|----------------|------------|--------|
| Samsung Galaxy | 11+ | Samsung TTS | ⬜ Pass/Fail |
| Google Pixel | 11+ | Google TTS | ⬜ Pass/Fail |
| Xiaomi | 10+ | Google TTS | ⬜ Pass/Fail |
| Generic | 9+ | Google TTS | ⬜ Pass/Fail |

## 🐛 Known Issues to Verify Fixed

- [ ] ✅ Audio works on Android 11+ (TTS_SERVICE query added)
- [ ] ✅ No crash when language unavailable (fallback implemented)
- [ ] ✅ No audio overlap (stop() before speak())
- [ ] ✅ Silent mode override works (audio category set)
- [ ] ✅ Cleanup on dispose (memory leak prevented)

## 📝 Console Logs to Monitor

Watch for these debug messages:
```
TTS: Initialized successfully
TTS: Speaking in it-IT
TTS: Language it-IT available
TTS: Speak error: [if any errors]
```

## ✅ Final Validation

Before marking as complete:

- [ ] All basic tests pass
- [ ] At least 2 different devices tested
- [ ] Both quiz screens work (QuizScreen + CustomQuizScreen)
- [ ] No errors in console during normal use
- [ ] Silent mode override confirmed
- [ ] Bangla fallback behavior verified
- [ ] Documentation reviewed

## 🚀 Ready for Production?

- [ ] All tests passed on minimum 2 devices
- [ ] No critical bugs found
- [ ] Performance acceptable
- [ ] User experience smooth
- [ ] Error handling graceful

**Date Tested:** _______________
**Devices Used:** _______________
**Issues Found:** _______________

---

## 📞 If Tests Fail

### Audio doesn't play at all
1. Check AndroidManifest.xml has TTS query
2. Verify TTS engine installed on device
3. Check device volume settings
4. Review console for "TTS:" error messages

### Wrong language plays
1. Verify language codes: 'it', 'en', 'bn'
2. Check device has voice data for language
3. Test language availability with getAvailableLanguages()

### App crashes on speaker button
1. Verify TtsHelper.init() called in initState
2. Check imports are correct
3. Review stack trace for specific error
4. Ensure dispose() calls stop()

### Audio overlaps
1. This should be impossible (stop() is called first)
2. If it occurs, report as critical bug
3. Check TtsHelper singleton is being used correctly

---

**Testing Status:** 🟡 Pending

After completing tests, update to:
- 🟢 All tests passed
- 🟠 Minor issues found
- 🔴 Critical issues found
