# iOS Xcode Setup Checklist — Patente B Quiz

> Complete every step on your Mac **before** running `flutter build ios --release`.
> Items are ordered by priority. ✅ = done, ☐ = todo.

---

## 1. Prerequisites (Terminal on Mac, BEFORE opening Xcode)

```bash
# 1a. Install CocoaPods if not already installed
sudo gem install cocoapods          # or: brew install cocoapods

# 1b. Get Flutter packages (generates ios/Flutter/Generated.xcconfig)
flutter pub get

# 1c. Install iOS dependencies
cd ios && pod install && cd ..

# 1d. Open the WORKSPACE (not .xcodeproj!)
open ios/Runner.xcworkspace
```

---

## 2. Signing & Team

| Step | Where in Xcode | Action |
|---|---|---|
| ☐ Select Team | Runner → Signing & Capabilities → Team | Pick your Apple Developer account |
| ☐ Set Bundle ID | Runner → Signing & Capabilities → Bundle Identifier | Verify `com.deshbangla.patente` (or replace with your own) and ensure it matches App Store Connect exactly |
| ☐ Auto-manage signing | Runner → Signing & Capabilities | Tick "Automatically manage signing" |
| ☐ RunnerTests Bundle ID | RunnerTests target → Signing & Capabilities | Keep it aligned (default: `com.deshbangla.patente.RunnerTests`) |

> ⚠️ The Bundle ID you set here must **exactly** match what you register in
> [App Store Connect → My Apps → New App](https://appstoreconnect.apple.com).

---

## 3. Add Capabilities (Runner target)

Open **Runner → Signing & Capabilities**, click **"+ Capability"** for each below.

### 3a. Sign in with Apple ← **CRITICAL — App Store will reject without this**
- Click **+ Capability** → search "Sign in with Apple" → double-click to add.
- No further configuration needed; the entitlement is auto-generated.

### 3b. Associated Domains (for Universal Links & Supabase magic links)
- Click **+ Capability** → "Associated Domains".
- Add: `applinks:gtlzxkfkfzndfsuqiyge.supabase.co`
- This enables Supabase magic-link emails to open the app directly.

> If you only want the custom URL scheme (`io.supabase.xxx://`) you can **skip**
> Associated Domains — it is optional. The `CFBundleURLTypes` entry in `Info.plist`
> already handles that scheme without any capability.

### 3c. Push Notifications (optional — for future feature)
- Add only when you wire up push notifications.

---

## 4. Deployment Target

| Target | Setting | Value |
|---|---|---|
| Runner | Build Settings → iOS Deployment Target | **13.0** |
| RunnerTests | Build Settings → iOS Deployment Target | **13.0** |

> The `Podfile` post-install hook enforces 13.0 on every Pod, but you must also
> set it on the Runner target manually in Xcode.

---

## 5. GoogleService-Info.plist (Google Sign‑In)

> Required if/when you re-enable Google Sign-In in `auth_screen.dart`.

1. Go to [Firebase Console](https://console.firebase.google.com) → your project → iOS app.
2. Download **`GoogleService-Info.plist`**.
3. In Xcode, right-click **Runner folder → Add Files to "Runner"**.
4. Select the `.plist` file. Ensure ✅ "Copy items if needed" and ✅ "Add to Runner target".
5. Verify it appears under `Runner/Runner/GoogleService-Info.plist` in the Project Navigator.

> 🚫 **Never commit `GoogleService-Info.plist` to a public repo.** Add it to `.gitignore`.

---

## 6. Supabase Auth — URL Scheme Verification

The custom URL scheme is already added to `ios/Runner/Info.plist`:
```
io.supabase.gtlzxkfkfzndfsuqiyge
```

Verify in Xcode → Runner → Info tab → URL Types:
- Identifier: `supabase-auth`
- URL Schemes: `io.supabase.gtlzxkfkfzndfsuqiyge`

Also verify in **Supabase Dashboard → Authentication → URL Configuration**:
- Site URL: `io.supabase.gtlzxkfkfzndfsuqiyge://login-callback`
- Redirect URLs: add `io.supabase.gtlzxkfkfzndfsuqiyge://login-callback`

---

## 7. App Icons

- Xcode requires icons in every required size for App Store submission.
- Flutter can generate them: add your 1024×1024 source icon to `assets/icon/app_icon.png`
  and run:

```bash
dart run flutter_launcher_icons
```

Check **Runner → Assets.xcassets → AppIcon** — all slots should be filled (no warnings).

---

## 8. Launch Screen

- Open `ios/Runner/Base.lproj/LaunchScreen.storyboard` in Xcode.
- Ensure it matches your app branding (logo, background color).
- The App Store **rejects** apps that use the default white Flutter splash.

---

## 9. Build Settings — Release Configuration

| Setting | Value | Why |
|---|---|---|
| Enable Bitcode | NO | Apple removed Bitcode support in Xcode 14 |
| Strip Swift Symbols | YES | Reduces binary size |
| Validate Workspace | YES | Catches code-signing issues early |

---

## 10. App Store Connect Setup

1. Log in to [App Store Connect](https://appstoreconnect.apple.com).
2. **My Apps → +** → New App.
   - Platform: iOS
   - Bundle ID: `com.yourcompany.patentebquiz` (must match Xcode)
   - SKU: any unique string, e.g. `patentebquiz2025`
3. Fill in: App Name, Subtitle, Keywords, Description (Italian + English).
4. Upload screenshots: iPhone 6.5" (iPhone 14 Pro Max) + iPhone 5.5" minimum.
5. Add Privacy Policy URL (App Store requires one for apps with user accounts).

---

## 11. First Build & Archive

```bash
# Clean build (run on Mac)
flutter clean
flutter pub get
cd ios && pod install && cd ..

# Build for device (attach a physical iPhone or use Simulator first)
flutter build ios --release

# Then in Xcode: Product → Archive → Distribute App → App Store Connect
```

---

## 12. Privacy Manifest (Required from Spring 2024+)

Apple now requires a **`PrivacyInfo.xcprivacy`** for any use of required-reason APIs.
Several Flutter packages (path_provider, shared_preferences) access the file system.

1. Verify `ios/Runner/PrivacyInfo.xcprivacy` is present in the Runner target resources.
2. Confirm required reasons for APIs your app uses. Minimum for this app:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <!-- File timestamp APIs — used by path_provider / shared_preferences -->
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>C617.1</string></array>
    </dict>
    <!-- UserDefaults — used by shared_preferences -->
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>CA92.1</string></array>
    </dict>
  </array>
  <key>NSPrivacyCollectedDataTypes</key>
  <array/>
  <key>NSPrivacyTracking</key>
  <false/>
</dict>
</plist>
```

---

## Quick Reference — Most Common Rejection Reasons

| Rejection Reason | Fix |
|---|---|
| Missing "Sign in with Apple" | Add capability in Xcode (Step 3a) |
| Invalid Bundle ID | Must match App Store Connect exactly |
| Missing privacy policy | Add URL in App Store Connect listing |
| App crashes on launch | Run `flutter analyze` + test on real device |
| Missing or incomplete icons | Re-run `flutter_launcher_icons` |
| Privacy manifest missing | Add `PrivacyInfo.xcprivacy` (Step 12) |
| Bitcode enabled | Disable in Build Settings (Step 9) |
