#!/bin/bash
set -e

echo "=========================================="
echo "Xcode Cloud: Pre-Build Verification"
echo "=========================================="

REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-.}"
cd "$REPO_ROOT"

echo ""
echo "Checking required Flutter/CocoaPods files..."

# Check Generated.xcconfig
if [ -f "ios/Flutter/Generated.xcconfig" ]; then
  echo "✓ ios/Flutter/Generated.xcconfig exists"
else
  echo "✗ MISSING: ios/Flutter/Generated.xcconfig"
  exit 1
fi

# Check Podfile.lock
if [ -f "ios/Podfile.lock" ]; then
  echo "✓ ios/Podfile.lock exists"
else
  echo "✗ MISSING: ios/Podfile.lock"
  exit 1
fi

# List Target Support Files to verify Pods were installed
if [ -d "ios/Pods/Target Support Files" ]; then
  echo "✓ ios/Pods/Target Support Files exists"
  ls -la ios/Pods/Target Support Files/Pods-Runner/ 2>/dev/null | head -10 || echo "  (contents listed above)"
else
  echo "✗ MISSING: ios/Pods/Target Support Files"
  exit 1
fi

echo ""
echo "Checking release signing/build settings..."
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -showBuildSettings \
  | grep -E "CODE_SIGN_STYLE|DEVELOPMENT_TEAM|PRODUCT_BUNDLE_IDENTIFIER|CODE_SIGN_IDENTITY|PROVISIONING_PROFILE_SPECIFIER" \
  || true

echo ""
echo "=========================================="
echo "✓ Pre-build verification passed"
echo "=========================================="
exit 0
