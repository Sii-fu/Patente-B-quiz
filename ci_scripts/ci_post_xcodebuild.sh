#!/bin/bash
# Xcode Cloud post-xcodebuild error diagnostics

echo "====== POST-XCODEBUILD DIAGNOSTICS ======"
echo "Build failed. Attempting to extract error details..."
echo ""

# 1. Check xcresult bundle
RESULT_BUNDLE="/Volumes/workspace/resultbundle.xcresult"
if [ ! -d "$RESULT_BUNDLE" ]; then
  RESULT_BUNDLE="$(find /Volumes/workspace -maxdepth 3 -name "*.xcresult" -type d 2>/dev/null | head -1 || true)"
fi

if [ -n "${RESULT_BUNDLE:-}" ] && [ -d "$RESULT_BUNDLE" ]; then
  echo "[1] Found xcresult bundle: $RESULT_BUNDLE"
  echo "Extracting errors..."
  
  # Try to get all messages
  xcrun xcresulttool get --legacy --path "$RESULT_BUNDLE" 2>/dev/null | \
    grep -i "error\|failed\|phaseexecution" | tail -50 || true
  
  echo ""
fi

# 2. Check DerivedData logs
echo "[2] Checking DerivedData for build logs..."
if [ -d "/Volumes/workspace/DerivedData" ]; then
  find /Volumes/workspace/DerivedData -name "*.log" -o -name "build.log" 2>/dev/null | \
    while read logfile; do
      echo "Found: $logfile"
      tail -100 "$logfile" | grep -E "error|failed|Exit code|Phase" || true
    done
fi

# 3. Check for any script errors in CI workspace
echo ""
echo "[3] Searching for script errors in workspace..."
if [ -d "/Volumes/workspace" ]; then
  find /Volumes/workspace -name "*.log" 2>/dev/null -print0 | \
    xargs -0 grep -l "error\|failed" 2>/dev/null | head -5 | while read f; do
      echo "  -> Log file: $f"
      tail -20 "$f"
    done
fi

# 4. Check CocoaPods specifically
echo ""
echo "[4] CocoaPods diagnostic..."
if [ -f "/Volumes/workspace/ios/Pods/Manifest.lock" ]; then
  echo "Pods installed. Pod count:"
  find /Volumes/workspace/ios/Pods -maxdepth 1 -type d | wc -l
else
  echo "WARNING: Pods directory not found or Manifest.lock missing!"
fi

# 5. Check Generated.xcconfig
echo ""
echo "[5] Flutter Generated.xcconfig check..."
ls -la /Volumes/workspace/ios/Flutter/ | grep -E "xcconfig|Generated" || \
  echo "WARNING: Expected xcconfig files not found!"

echo ""
echo "====== END DIAGNOSTICS ======"
