# Xcode Cloud Build Troubleshooting - PhaseScriptExecution Errors

## Current Issue
Build failing with: `Command PhaseScriptExecution failed with nonzero exit code 65`

This typically occurs during CocoaPods framework embedding or resource copying phases, or during Flutter build scripts.

## Recent Changes Applied

### 1. Enhanced CI Post-Build Diagnostics
**File**: `ci_scripts/ci_post_xcodebuild.sh`
- Added comprehensive error logging to capture exact failing script phase names
- Now searches multiple locations for build logs and xcresult bundles
- Provides detailed CocoaPods diagnostic information

### 2. Improved Post-Clone Setup
**File**: `ci_scripts/ci_post_clone.sh`
- Relaxed Flutter build config-only constraint (was causing upstream failures)
- Added better error handling with warnings instead of hard failures
- Now continues on non-fatal Flutter config issues

### 3. Enhanced Podfile Post-Install Hooks
**File**: `ios/Podfile`
- Added explicit `SHELL = '/bin/bash'` setting to prevent PATH issues in CI
- Added `SWIFT_VERSION = '5.0'` to all pod targets for consistency
- Added project-level build setting for CI environment detection

### 4. Project-Level Script Sandboxing (Already Applied)
**File**: `ios/Runner.xcodeproj/project.pbxproj`
- `ENABLE_USER_SCRIPT_SANDBOXING = NO` already set in both Debug (line 611) and Release (line 670) configurations at project level

## Next Steps to Diagnose and Fix

### Step 1: Re-run Xcode Cloud Build with Enhanced Logging
1. Commit all changes:
   ```bash
   cd /path/to/repo
   git add -A
   git commit -m "Enhanced Xcode Cloud CI scripts for better error diagnostics"
   git push origin main  # or your branch
   ```

2. Trigger a new Xcode Cloud build in App Store Connect

3. **IMPORTANT**: Wait for the build to complete (fail), then check the **post-xcodebuild logs** for the enhanced diagnostics output. This will show:
   - Exact script phase that's failing (e.g., "[CP] Embed Pods Frameworks")
   - Full error message and stderr
   - CocoaPods manifest information
   - Generated xcconfig file status

### Step 2: Interpret Diagnostics Output
Once you see the post-xcodebuild log output, look for:

**If you see "missing xcfilelist"**:
- Means `pod install` didn't run or failed
- Solution: Check `ci_post_clone.sh` output - pod install might need `--repo-update` flag or retry logic

**If you see "command not found" in script phase**:
- PATH issue in CI environment
- Solution: The new `SHELL` setting in Podfile should fix this; if not, we may need to explicitly set PATH in build settings

**If you see specific pod name failing**:
- Example: "FirebaseAuth pod script failed"
- Solution: May need pod-specific fixes or investigate that pod's compatibility with static frameworks

**If you see signing-related error**:
- Solution: Verify `CODE_SIGN_STYLE = Automatic` and `DEVELOPMENT_TEAM` are set correctly
- These are already configured but may need adjustment

### Step 3: Apply Targeted Fix (Based on Diagnostics)

#### Scenario A: Pod Install Not Running/Missing Files
```bash
# In ci_scripts/ci_post_clone.sh, update pod install line:
pod install --repo-update --verbose 2>&1 | head -200
```

#### Scenario B: PATH Issues in Script Phases
The Podfile changes should handle this. If not, we may need to add an export to the build settings.

#### Scenario C: Dynamic vs Static Framework Conflict
If specific pods don't work with static linkage, revert in Podfile:
```ruby
# REVERT FROM: use_frameworks! :linkage => :static
# TO:
use_frameworks!
```

#### Scenario D: Xcode Version Incompatibility
If Xcode Cloud is using Xcode 15.x, we may need to add:
```ruby
# In post_install block:
config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
```

## Files That Were Modified

1. **ci_scripts/ci_post_xcodebuild.sh** - Enhanced error extraction
2. **ci_scripts/ci_post_clone.sh** - Improved Flutter setup, better error handling
3. **ios/Podfile** - Added SHELL setting, SWIFT_VERSION, CI environment detection
4. **ios/Runner.xcodeproj/project.pbxproj** - (Already has ENABLE_USER_SCRIPT_SANDBOXING)

## Checklist Before Re-Running Build

- [ ] All changes committed to git
- [ ] Branch pushed to remote
- [ ] CI scripts have execute permissions (should be fine via git)
- [ ] No local uncommitted changes that might affect build
- [ ] Xcode Cloud workflow is configured to use correct branch
- [ ] Provisioning profile and signing certificate are still valid in Apple Developer account

## If Build Still Fails

If the new diagnostics still don't provide enough information, you may need to:

1. **Enable verbose build logging** in Xcode Cloud workflow settings if available
2. **Test locally** with an equivalent setup:
   ```bash
   rm -rf ios/Pods ios/Podfile.lock DerivedData
   flutter pub get
   cd ios
   pod install
   cd ..
   xcodebuild archive -workspace ios/Runner.xcworkspace -scheme Runner -destination generic/platform=iOS -archivePath build.xcarchive
   ```

3. **Try dynamic frameworks instead of static** to narrow down if it's a framework linkage issue

## Support Documentation

- [Xcode Cloud Troubleshooting](https://developer.apple.com/documentation/xcode-cloud/building-with-xcode-cloud)
- [CocoaPods Script Phase Issues](https://github.com/CocoaPods/CocoaPods/issues)
- [Flutter iOS Build Configuration](https://flutter.dev/docs/deployment/ios)

---

**Last Updated**: $(date)
**Issue**: `PhaseScriptExecution failed` during `xcodebuild archive`
**Status**: Awaiting diagnostics from next Xcode Cloud build run
