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
echo "Checking Release/Profile xcfilelists required by Runner [CP] phases..."
for f in \
  "ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks-Release-input-files.xcfilelist" \
  "ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks-Release-output-files.xcfilelist" \
  "ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-resources-Release-input-files.xcfilelist" \
  "ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-resources-Release-output-files.xcfilelist" \
  "ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks-Profile-input-files.xcfilelist" \
  "ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks-Profile-output-files.xcfilelist" \
  "ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-resources-Profile-input-files.xcfilelist" \
  "ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-resources-Profile-output-files.xcfilelist"
do
  if [ -f "$f" ]; then
    echo "✓ $f"
  else
    echo "✗ MISSING: $f"
    exit 1
  fi
done

for s in \
  "ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks.sh" \
  "ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-resources.sh"
do
  if [ -f "$s" ]; then
    echo "✓ $s"
  else
    echo "✗ MISSING: $s"
    exit 1
  fi
done

echo ""
echo "Checking release signing/build settings..."
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -showBuildSettings \
  | grep -E "CODE_SIGN_STYLE|DEVELOPMENT_TEAM|PRODUCT_BUNDLE_IDENTIFIER|CODE_SIGN_IDENTITY|PROVISIONING_PROFILE_SPECIFIER" \
  || true

echo ""
echo "Checking Flutter backend script wiring..."
if [ -f "ios/ci_scripts/flutter_xcode_backend.sh" ]; then
  echo "✓ ios/ci_scripts/flutter_xcode_backend.sh exists"
else
  echo "✗ MISSING: ios/ci_scripts/flutter_xcode_backend.sh"
  exit 1
fi

if [ -f "ios/Flutter/Generated.xcconfig" ]; then
  FLUTTER_ROOT_VALUE="$(grep '^FLUTTER_ROOT=' ios/Flutter/Generated.xcconfig | head -1 | sed 's/^FLUTTER_ROOT=//')"
  if [ -n "${FLUTTER_ROOT_VALUE:-}" ]; then
    echo "✓ FLUTTER_ROOT in Generated.xcconfig: $FLUTTER_ROOT_VALUE"
  else
    echo "✗ FLUTTER_ROOT missing in ios/Flutter/Generated.xcconfig"
    exit 1
  fi
fi

echo ""
echo "=========================================="
echo "✓ Pre-build verification passed"
echo "=========================================="
exit 0
