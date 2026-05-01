#!/bin/bash
set -e

echo "=========================================="
echo "Xcode Cloud: Flutter iOS CI Setup"
echo "=========================================="

# Set working directory
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-.}"
cd "$REPO_ROOT" || { echo "ERROR: Failed to cd to repo root"; exit 1; }
echo "Working directory: $PWD"

# Install Flutter if not present
FLUTTER_ROOT="${FLUTTER_ROOT:-$HOME/flutter}"
echo "Flutter root: $FLUTTER_ROOT"

if [ ! -d "$FLUTTER_ROOT" ]; then
  echo "Installing Flutter SDK (stable channel)..."
  mkdir -p "$FLUTTER_ROOT"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_ROOT" || { echo "ERROR: Failed to clone Flutter"; exit 1; }
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"
export PUB_CACHE="$FLUTTER_ROOT/.pub-cache"

# Verify Flutter
echo "Flutter version:"
flutter --version || { echo "ERROR: Flutter not found"; exit 1; }

# Disable analytics
flutter config --no-analytics || true

# Get dependencies
echo ""
echo "Running: flutter pub get"
flutter pub get || { echo "ERROR: flutter pub get failed"; exit 1; }

echo ""
echo "Running: flutter precache --ios"
flutter precache --ios || { echo "ERROR: flutter precache failed"; exit 1; }

echo ""
echo "Generating Flutter iOS build files (config only)..."
flutter build ios --config-only 2>&1 || echo "WARNING: flutter build config had non-fatal warnings (continuing)"

# Install pods
echo ""
cd ios || { echo "ERROR: ios directory not found"; exit 1; }

echo "Running: pod repo update"
pod repo update || echo "WARNING: pod repo update had issues (continuing)"

echo "Running: pod install"
pod install --repo-update || { echo "ERROR: pod install failed"; exit 1; }

echo "Verifying CocoaPods xcfilelists..."
for f in \
  "Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks-Release-input-files.xcfilelist" \
  "Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks-Release-output-files.xcfilelist" \
  "Pods/Target Support Files/Pods-Runner/Pods-Runner-resources-Release-input-files.xcfilelist" \
  "Pods/Target Support Files/Pods-Runner/Pods-Runner-resources-Release-output-files.xcfilelist"
do
  if [ -f "$f" ]; then
    echo "✓ $f"
  else
    echo "ERROR: missing $f"
    exit 1
  fi
done

echo ""
echo "=========================================="
echo "✓ Xcode Cloud setup complete"
echo "=========================================="
exit 0
