# Phase 1: Onboarding & Auth Module - Setup Guide

## ✅ What's Been Implemented

Phase 1 is now complete with the following structure:

```
lib/
├── main.dart                                    # App entry point with Supabase initialization
├── utils/
│   ├── constants.dart                          # SharedPreferences keys & Supabase config
│   └── theme.dart                              # Light & Dark theme definitions
├── features/
│   └── auth/
│       └── screens/
│           ├── splash_screen.dart              # Logic hub for routing
│           ├── setup_wizard_screen.dart        # First-time setup (license type + school code)
│           └── auth_screen.dart                # Login/Signup with social auth & guest mode
└── screens/
    └── dashboard/
        └── home_screen.dart                    # Placeholder home screen
```

## 🔧 Setup Instructions

### 1. Configure Supabase

**a) Create a Supabase Project:**
1. Go to [supabase.com](https://supabase.com) and create a new project
2. Note your project URL and anon key from Settings > API

**b) Update Constants:**
Edit `lib/utils/constants.dart`:
```dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your-anon-key-here';
```

**c) Enable Authentication Providers:**
In your Supabase dashboard:
- Go to Authentication > Providers
- Enable Email provider
- Enable Google OAuth (optional - see below)
- Enable Facebook OAuth (optional - see below)

### 2. Configure Google Sign-In (Optional)

**a) Get Google OAuth Credentials:**
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable Google Sign-In API
4. Create OAuth 2.0 credentials (Web client)
5. Add authorized redirect URIs:
   - `https://your-project.supabase.co/auth/v1/callback`

**b) Configure Supabase:**
1. In Supabase Dashboard > Authentication > Providers > Google
2. Enable Google provider
3. Add your Client ID and Client Secret

**c) Update Auth Screen:**
Edit `lib/features/auth/screens/auth_screen.dart` line 60:
```dart
clientId: 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com',
```

**d) Configure Platform-Specific Settings:**

**Android** (`android/app/build.gradle`):
```gradle
// Add inside defaultConfig
manifestPlaceholders = [
    'appAuthRedirectScheme': 'com.yourpackage'
]
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 3. Configure Facebook Sign-In (Optional)

**a) Create Facebook App:**
1. Go to [Facebook Developers](https://developers.facebook.com)
2. Create a new app
3. Add Facebook Login product
4. Configure Valid OAuth Redirect URIs:
   - `https://your-project.supabase.co/auth/v1/callback`

**b) Configure Supabase:**
1. In Supabase Dashboard > Authentication > Providers > Facebook
2. Enable Facebook provider
3. Add your App ID and App Secret

**c) Add Package:**
```bash
flutter pub add flutter_facebook_auth
```

**d) Update redirect URI in `auth_screen.dart` line 97:**
```dart
redirectTo: 'your-app-scheme://login-callback',
```

### 4. Run the App

```bash
# Install dependencies (already done)
flutter pub get

# Run on your device/emulator
flutter run
```

## 📱 User Flow Testing

### First Launch Flow:
1. **Splash Screen** → Detects first-time user
2. **Setup Wizard** → Select license type (B/A/AM) + optional school code
3. **Auth Screen** → Login/Signup or continue as guest
4. **Home Screen** → Placeholder showing user status

### Returning User Flow:
1. **Splash Screen** → Checks for active session
2. **Home Screen** (if logged in) OR **Auth Screen** (if logged out)

### Guest Mode:
- Click "Continua come ospite" on Auth Screen
- Home screen shows "Modalità Ospite" with warning

## 🎨 UI Features

- ✅ Clean, minimalist white background (light mode)
- ✅ Dark mode support (essential for night studying)
- ✅ Large, friendly input fields with rounded corners
- ✅ High-contrast primary action buttons
- ✅ Modern sans-serif typography
- ✅ Smooth navigation transitions
- ✅ Form validation
- ✅ Loading states on all async operations

## 🔐 Authentication Features

- ✅ Email/Password authentication
- ✅ Google Sign-In integration
- ✅ Facebook Sign-In integration (requires additional setup)
- ✅ Guest mode (no registration required)
- ✅ Auth state listener (auto-navigation on login)
- ✅ Logout functionality
- ✅ Password visibility toggle
- ✅ Input validation

## 📝 Local Storage

Using `shared_preferences` to track:
- `is_first_time_user` - First launch detection
- `completed_setup` - Setup wizard completion
- `license_type` - Selected license type (B/A/AM)
- `driving_school_code` - Optional school code
- `guest_mode` - Guest mode flag

## ⚠️ Known Limitations

1. **Google Sign-In requires platform configuration** - Follow setup steps above
2. **Facebook Sign-In needs additional package** - Add `flutter_facebook_auth` if needed
3. **Supabase credentials must be configured** - Update `constants.dart`
4. **Deep linking not configured** - OAuth redirects may need additional setup

## 🚀 Next Steps (Phase 2: Dashboard)

After completing Supabase setup:
1. Implement the actual Dashboard with:
   - Circular progress "Exam Readiness" indicator
   - Three action cards (Exam Mode, Topic Mode, Review Errors)
   - Gamification (streak counter, level badge)
2. Add user profile management
3. Implement analytics tracking

## 🐛 Troubleshooting

### Error: "Missing Supabase URL"
- Update `lib/utils/constants.dart` with your actual credentials

### Google Sign-In fails
- Verify OAuth credentials in Google Cloud Console
- Check redirect URIs match Supabase configuration
- Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) are added

### Build errors
- Run `flutter clean` then `flutter pub get`
- Check Flutter SDK version (requires >=3.8.1)

## 📞 Support

For issues related to:
- **Supabase**: Check [Supabase Documentation](https://supabase.com/docs)
- **Google Sign-In**: See [google_sign_in package](https://pub.dev/packages/google_sign_in)
- **Flutter**: Visit [Flutter Documentation](https://docs.flutter.dev)
