# Xcode Cloud Exit Code 65 - Common Fixes Quick Reference

## Exit Code 65 Usually Means:
- Script phase failed (PhaseScriptExecution)
- Most likely in CocoaPods phases: `[CP] Embed Pods Frameworks`, `[CP] Copy Pods Resources`, or `[CP] Copy Pods Frameworks`

## What We've Already Applied ✓

1. **Disabled User Script Sandboxing**
   - `ENABLE_USER_SCRIPT_SANDBOXING = NO` in Xcode project AND Podfile
   - This is the #1 fix for Xcode 14+

2. **Switched to Static Frameworks**
   - `use_frameworks! :linkage => :static` in Podfile
   - More stable than dynamic on CI environments

3. **Set Proper iOS Deployment Target**
   - iOS 13.0 everywhere (project, pods, xcconfig)
   - Prevents version mismatch errors

4. **Normalized Signing**
   - `CODE_SIGN_STYLE = Automatic` with `DEVELOPMENT_TEAM = K3N8B9XQGC`
   - No manual signing issues

5. **Added CI Environment Preparation**
   - `ci_scripts/ci_post_clone.sh` runs flutter pub get and pod install
   - `ci_post_xcodebuild.sh` extracts and logs failures for debugging

## If Build STILL Fails with Exit 65

Try these in order:

### Option 1: Add PATH Fallback (Quick)
Add to `ios/Podfile` post_install:
```ruby
config.build_settings['PATH'] = "#{config.build_settings['PATH']}:/usr/local/bin"
```

### Option 2: Revert to Dynamic Frameworks (If Static Breaks)
Change in `ios/Podfile`:
```ruby
# FROM:
use_frameworks! :linkage => :static

# TO:
use_frameworks!
```
Then run:
```bash
cd ios && rm -rf Pods Podfile.lock && pod install
```

### Option 3: Skip Problematic Pod (Nuclear Option)
If one pod causes all failures, try excluding it temporarily:
```ruby
# In target 'Runner' do
pod 'problematic_pod', :inhibit_warnings => true  # suppress warnings
```

### Option 4: Check for Node Compatibility
Some pods with native modules need Xcode 15.x specific settings:
```ruby
config.build_settings['CLANG_CXX_LANGUAGE_DIALECT'] = 'c++17'
```

## How to Read the Logs

1. Go to App Store Connect → Xcode Cloud → [Your Workflow] → Most Recent Build
2. Click on the failed "archive" step
3. Scroll to "post-xcodebuild" phase (near bottom)
4. Look for:
   - **Line with `ERROR:`** - That's your problem
   - **Line with `[CP]`** - That's the failing script
   - **Line with `failed:`** - Specific error message

## Typical Error Messages & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `command not found: xcrun` | PATH not set in CI | Already fixed (SHELL setting) |
| `No such file or directory` (.xcfilelist) | Pod install didn't run | Re-run `pod install` |
| `code sign invalid` | Signing cert expired | Renew cert in Apple Developer |
| `Unsupported Swift version` | Pod requires newer Swift | Update pod in pubspec.yaml |
| `Duplicate symbol` | Framework linked twice | Check use_frameworks! setting |
| `Module not found` | Pod not installed | Run `flutter pub get` first |

## Last Resort: Build Locally First

To test before pushing to Xcode Cloud:

```bash
# Clean everything
rm -rf ios/Pods ios/Podfile.lock DerivedData

# Setup
flutter pub get
cd ios && pod install && cd ..

# Try archive locally (requires Mac)
xcodebuild archive \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -destination generic/platform=iOS \
  -archivePath build.xcarchive

# If this succeeds, issue is CI-specific
# If this fails, fix locally then push
```

## Key Files to Check

- **ios/Podfile** - Pod configuration
- **ios/Flutter/Debug.xcconfig** & **Release.xcconfig** - Flutter build config
- **ios/Runner.xcodeproj/project.pbxproj** - Xcode project settings
- **ci_scripts/ci_post_clone.sh** - Pre-build setup in CI
- **pubspec.yaml** - Flutter/Dart dependencies (may include pods)

---

**Quick Checklist Before Retrying Build:**
- [ ] Run `flutter pub get` locally
- [ ] Run `cd ios && pod install` locally
- [ ] Verify it builds locally with `xcodebuild ... -scheme Runner`
- [ ] Commit changes: `git add -A && git commit -m "iOS build fixes" && git push`
- [ ] Trigger new Xcode Cloud build
