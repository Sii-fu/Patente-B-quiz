# Offline Functionality Guide

## Overview
The Patente B Quiz App is designed with offline-first principles for essential features while requiring internet connectivity for others.

## ✅ Features That Work Offline

### 1. **Dark Mode** (Fully Offline)
- **Storage**: `SharedPreferences` (Local)
- **Behavior**: 
  - Toggle works instantly without internet
  - Preference is saved locally
  - Persists across app restarts
- **Implementation**: `ThemeProvider` class
- **Location**: `lib/providers/theme_provider.dart`

### 2. **Language Selection** (Fully Offline)
- **Storage**: `SharedPreferences` (Local)
- **Supported Languages**: 
  - English (en)
  - Italian (it)
  - Bangla (bn)
- **Behavior**:
  - Changes apply immediately
  - No internet required
  - Saves locally
- **Implementation**: `LanguageProvider` class
- **Location**: `lib/providers/language_provider.dart`

### 3. **Profile Viewing** (Cached Data)
- **Storage**: `SharedPreferences` (Cached JSON)
- **Behavior**:
  - Shows last fetched profile data when offline
  - Displays orange "Offline Mode" banner
  - Statistics remain visible (cached)
  - User can still view their information
- **Limitation**: Cannot save profile changes (name, phone, license type) while offline
- **Cache Key**: `cached_profile_data`

### 4. **Quiz Questions** (Downloadable)
- **Storage**: Local SQLite database (Drift)
- **Behavior**:
  - Questions can be pre-downloaded
  - Full quiz functionality when downloaded
  - Automatic fallback to local DB when offline
- **Implementation**: `QuizRepository` with offline detection
- **Location**: `lib/services/quiz_repository.dart`

### 5. **Theory Content** (Downloadable)
- **Storage**: Local SQLite database
- **Behavior**:
  - Theory chapters cached locally
  - Reading available offline after download
- **Tables**: `theory_chapters`, `theory_cards`

---

## ❌ Features That Require Internet

### 1. **Video Tutorials**
- **Why**: YouTube videos cannot be cached
- **Behavior**:
  - Shows "No Internet Connection" screen with helpful message
  - Retry button available
  - Clean error handling via `VideoOfflineException`
- **Implementation**: `VideoRepository` checks connectivity first
- **Location**: 
  - `lib/repositories/video_repository.dart`
  - `lib/features/videos/video_library_screen.dart`

### 2. **Profile Updates**
- **Why**: Requires Supabase sync
- **What Cannot Be Changed Offline**:
  - Full Name
  - Phone Number
  - License Type
- **Behavior**:
  - Shows orange warning: "Cannot save profile changes while offline"
  - Notes that dark mode and language still work
  - Form fields remain editable but Save button shows warning

### 3. **Authentication**
- **Why**: Requires Supabase Auth
- **Affected Actions**:
  - Login
  - Signup
  - Password reset
  - Logout (works offline but clears local session)

### 4. **Statistics Sync**
- **Why**: Quiz results stored in Supabase
- **Behavior**:
  - Quiz can be taken offline (if questions downloaded)
  - Results queued for sync when online
  - Statistics update when connection restored

---

## Implementation Details

### Connectivity Checking
```dart
Future<bool> _hasInternetConnection() async {
  try {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  } catch (e) {
    return false;
  }
}
```

### Profile Caching Strategy
```dart
// Save to cache when online
Future<void> _cacheProfileData(Profile profile) async {
  final prefs = await SharedPreferences.getInstance();
  final profileJson = json.encode(profile.toJson());
  await prefs.setString(_cachedProfileKey, profileJson);
}

// Load from cache when offline
Future<void> _loadCachedProfile() async {
  final prefs = await SharedPreferences.getInstance();
  final cachedData = prefs.getString(_cachedProfileKey);
  if (cachedData != null) {
    final profile = Profile.fromJson(json.decode(cachedData));
    // Use cached profile
  }
}
```

### Video Offline Exception
```dart
class VideoOfflineException implements Exception {
  final String message;
  VideoOfflineException([this.message = 'Video content requires an internet connection']);
}

// Usage in repository
Future<List<VideoCategory>> fetchVideoLibrary() async {
  final hasConnection = await _hasInternetConnection();
  if (!hasConnection) {
    throw VideoOfflineException();
  }
  // Proceed with fetch
}
```

---

## User Experience

### Visual Indicators

1. **Offline Banner** (Profile Screen)
   - Orange background
   - WiFi-off icon
   - Clear message about offline status
   - Notes that settings still work

2. **Video Error Screen**
   - Large WiFi-off icon
   - "No Internet Connection" title
   - Helpful description
   - Retry button

3. **Loading States**
   - Spinner for async operations
   - Smooth transitions
   - No hanging UI

### Error Messages

#### Profile Save (Offline)
```
"Cannot save profile changes while offline. 
Changes to dark mode and language are saved locally."
```

#### Video Library (Offline)
```
"Videos require an internet connection. 
Please check your connection and try again."
```

---

## Testing Offline Functionality

### How to Test

1. **Enable Airplane Mode**
   - Toggle device airplane mode
   - Or disable WiFi/mobile data

2. **Test Dark Mode**
   - Should toggle instantly
   - Should persist after app restart

3. **Test Language**
   - Should change immediately
   - Should save without internet

4. **Test Profile**
   - Should load cached data
   - Should show offline banner
   - Save button should show warning

5. **Test Videos**
   - Should show offline error screen
   - Retry button should re-check connectivity

### Expected Behaviors

✅ **Dark mode works**: Toggle switches theme immediately  
✅ **Language works**: App UI updates to selected language  
✅ **Profile loads**: Shows cached data with orange banner  
✅ **Videos fail gracefully**: Clear error message with retry option  
✅ **Quiz works**: If questions downloaded, quiz functions normally  

---

## Best Practices

### For Developers

1. **Always Check Connectivity** for features requiring Supabase
2. **Cache Critical Data** in SharedPreferences or local DB
3. **Show Clear Messages** when offline
4. **Provide Retry Options** for failed network operations
5. **Never Block UI** - settings should work offline

### For Users

1. **Download Content** before going offline (use Download button)
2. **Dark Mode & Language** always work offline
3. **Video Tutorials** require internet connection
4. **Profile Changes** need internet but viewing works offline

---

## Technical Architecture

```
┌─────────────────────────────────────────────────┐
│             App Features                        │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────┐    ┌──────────────┐          │
│  │   Settings   │    │  Video Lib   │          │
│  │  (Offline)   │    │  (Online)    │          │
│  └──────┬───────┘    └──────┬───────┘          │
│         │                   │                   │
│         ▼                   ▼                   │
│  ┌──────────────┐    ┌──────────────┐          │
│  │SharedPrefs   │    │ Supabase +   │          │
│  │(Local)       │    │ Connectivity │          │
│  └──────────────┘    └──────────────┘          │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Future Enhancements

### Planned Offline Features
- [ ] Queue profile updates for sync when online
- [ ] Background sync service
- [ ] Offline quiz result storage
- [ ] Smart cache expiration (7 days)
- [ ] Download progress tracking

### Considerations
- Conflict resolution for queued updates
- Cache size management
- Network quality detection
- Partial connectivity handling

---

## Troubleshooting

### "Profile won't load"
- **Cause**: No cached data and offline
- **Solution**: Connect to internet once to cache data

### "Save button doesn't work"
- **Check**: Is offline banner visible?
- **Solution**: Connect to internet to save changes

### "Videos won't play"
- **Cause**: Offline or poor connection
- **Solution**: Videos require active internet connection

### "Dark mode reset"
- **Unlikely**: Dark mode preference is persistent
- **Check**: Ensure SharedPreferences not cleared

---

## Related Files

### Core Offline Logic
- `lib/providers/theme_provider.dart` - Dark mode (offline)
- `lib/providers/language_provider.dart` - Language (offline)
- `lib/features/profile/profile_screen.dart` - Profile with cache
- `lib/repositories/video_repository.dart` - Video (online-only)
- `lib/services/quiz_repository.dart` - Quiz with offline support

### Models
- `lib/models/profile.dart`
- `lib/models/video_models.dart`

### Database
- `lib/database/local_db.dart` - Drift database for offline storage

---

**Last Updated**: December 29, 2025  
**Version**: 1.0.0
