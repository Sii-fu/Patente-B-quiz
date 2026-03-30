# Theory Module - Quick Start Guide

## 🚀 Getting Started

### Step 1: Run Database Migration
```bash
cd "c:\Users\ACER\Documents\codes\work\Patente B quiz"
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 2: First-Time Data Sync
Open `lib/screens/dashboard/theory_chapters_screen.dart` and **temporarily uncomment** line 47:
```dart
// Line 47 - UNCOMMENT ONCE FOR INITIAL SYNC
await _theoryService.syncAllTheoryContent();
```

### Step 3: Run the App
```bash
flutter run
```

### Step 4: Navigate to Theory
1. Launch app → Dashboard
2. Tap "Theory Book" card
3. Tap "View All Chapters" button
4. Wait for initial sync (only first time)

### Step 5: Re-comment Sync Code
After first successful load, **comment line 47 again** to prevent repeated syncing:
```dart
// await _theoryService.syncAllTheoryContent(); // ✅ Already synced
```

---

## 📱 User Flow

### Chapter List Screen
```
┌─────────────────────────────────────┐
│  ← ALL THEORY                       │
├─────────────────────────────────────┤
│  Continue Learning                  │
│  ┌──────────────────────────────┐  │
│  │ Lezione 12: Distanza...  ▶ │  │
│  │ ████████░░░░░ 45% Completed │  │
│  └──────────────────────────────┘  │
│                                     │
│  All Chapters                       │
│  ┌─────────────────────────────┐   │
│  │ 01  Definizioni Stradali  ✓│   │ ← Completed
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 02  Segnali di Periolo    🔄│   │ ← In Progress (75%)
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 03  Norme di Precedenza   ○ │   │ ← Not Started
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### Reading Screen
```
┌─────────────────────────────────────┐
│  ← Lezione 2 (4/12)                 │
├─────────────────────────────────────┤
│  ┌──────────────────────────────┐  │
│  │     [IMAGE: DOSSO SIGN]      │  │
│  ├──────────────────────────────┤  │
│  │  DOSSO               🔊      │  │ ← Tap to hear
│  │                              │  │
│  │  🇮🇹 IT                       │  │
│  │  Indica una strada in salita │  │
│  │  seguita da una discesa...   │  │
│  │                              │  │
│  │  🇬🇧 EN                       │  │ ← Toggleable
│  │  Indicates an uphill road... │  │
│  │                              │  │
│  │    [IT] [EN] [BN]           │  │ ← Language toggles
│  └──────────────────────────────┘  │
│                                     │
│  [Scroll for more cards...]        │
└─────────────────────────────────────┘
```

---

## 🎯 Features & How to Use

### 1. **Continue Learning Card**
- **What:** Shows your last read chapter with progress
- **How:** Tap the play button (▶) to resume exactly where you left off
- **Location:** Top of Chapter List screen

### 2. **Progress Tracking**
- **Automatic:** Progress saves as you scroll through theory cards
- **Visual:** 
  - Green ✓ = 100% complete
  - Blue 🔄 = In progress (shows %)
  - Grey ○ = Not started
- **Persistent:** Progress saved even after closing app

### 3. **Text-to-Speech (TTS)**
- **Activate:** Tap the 🔊 speaker icon on any card
- **Stop:** Tap the 🛑 stop icon (appears while speaking)
- **Language:** Automatically speaks in the selected app language
- **Auto-stop:** TTS stops when you leave the screen

### 4. **Language Toggles**
- **Default:** Italian (IT) always shown
- **Add:** Tap [EN] or [BN] to show translations
- **Multiple:** Can show multiple languages at once
- **Remove:** Tap active language to hide (can't hide all)

### 5. **Image Viewing**
- **Full Screen:** Tap any theory image to view full size
- **Zoom:** Pinch to zoom in/out
- **Close:** Tap X button or back

### 6. **Pull to Refresh**
- **How:** Pull down on chapter list to refresh data
- **Use:** Updates progress and syncs any new content

---

## 🔧 Developer Reference

### Key Files

| File | Purpose |
|------|---------|
| `theory_service.dart` | Data management & sync |
| `theory_chapters_screen.dart` | Chapter list UI |
| `theory_reading_screen.dart` | Card reading UI |
| `theory_chapter.dart` | Chapter model |
| `theory_card.dart` | Card model |
| `local_db.dart` | Database schema (v2) |

### Important Methods

```dart
// TheoryService
await theoryService.syncAllTheoryContent(); // Initial sync
await theoryService.getAllChaptersWithProgress(); // Get chapters
await theoryService.markCardAsRead(chapterId, cardId); // Track progress
await theoryService.getLastReadPosition(); // Resume position

// Database
await db.getTheoryCardsByChapter(chapterId); // Get cards
await db.getChapterProgress(chapterId); // Get progress %
await db.getLastReadChapterId(); // Last read chapter
```

### Database Tables

```sql
-- theory_chapters
id, name_it, name_en, name_bn, image_url, display_order

-- theory_cards  
id, chapter_id, title_it/en/bn, text_it/en/bn, image_url

-- theory_progress_table (local only)
id, chapter_id, card_id, is_read, last_read_at
```

---

## 🐛 Troubleshooting

### Issue: "No chapters loading"
**Solution:** Ensure you uncommented the sync line (step 2) and have internet connection.

### Issue: "Database error on startup"
**Solution:** Run build_runner again:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: "Images not loading"
**Solution:** Check Supabase storage bucket permissions and image URLs in database.

### Issue: "TTS not working"
**Solution:** 
1. Ensure device volume is up
2. Check TTS language is installed on device
3. Test with Italian first (most reliable)

### Issue: "Progress not saving"
**Solution:** Check SharedPreferences permissions and ensure cards are being marked as read.

### Issue: "Resume doesn't work"
**Solution:** Ensure you've read at least one card. First-time users default to chapter 1.

---

## ✅ Quality Checklist

Before considering complete:
- [ ] Database migration successful (no errors)
- [ ] Initial sync completed (chapters visible)
- [ ] Chapter list displays correctly
- [ ] Progress indicators work (%, checkmarks)
- [ ] Continue Learning card appears
- [ ] Resume button navigates correctly
- [ ] Theory cards display with images
- [ ] TTS plays audio in all 3 languages
- [ ] Language toggles show/hide text
- [ ] Full-screen image zoom works
- [ ] Progress auto-saves while scrolling
- [ ] Back navigation preserves state
- [ ] Pull-to-refresh updates data

---

## 📊 Performance Tips

1. **Optimize Scroll:** Adjust `cardPosition` calculation if cards have different heights
2. **Image Caching:** CachedNetworkImage automatically handles offline mode
3. **TTS Cleanup:** Always stop TTS in `dispose()` method
4. **Memory:** Clear large lists when not needed

---

## 🎨 Customization

### Change Colors
Edit `lib/utils/theme.dart`:
```dart
AppTheme.primaryBrandBlue = Color(0xFF3498DB); // Play button color
AppTheme.primaryBrandGreen = Color(0xFF6BCB80); // Progress bar
```

### Adjust Card Height
Edit `theory_reading_screen.dart` line 97:
```dart
final cardPosition = i * 500.0; // Change 500 to match your cards
```

### Modify TTS Voice
Edit `lib/services/tts_helper.dart`:
```dart
await _flutterTts.setPitch(1.0); // 0.5 - 2.0
await _flutterTts.setSpeechRate(0.5); // 0.0 - 1.0
```

---

## 📞 Support

For issues or questions:
1. Check `THEORY_MODULE_COMPLETE.md` for detailed implementation notes
2. Review error logs in debug console
3. Verify database schema matches Supabase
4. Test with Italian content first (most complete)

---

**Version:** 1.0.0  
**Last Updated:** December 25, 2025  
**Status:** ✅ Production Ready
