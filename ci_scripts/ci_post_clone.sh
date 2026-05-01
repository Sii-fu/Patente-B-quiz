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
XCFILELIST_DIR="Pods/Target Support Files/Pods-Runner"
if [ ! -d "$XCFILELIST_DIR" ]; then
  echo "ERROR: missing directory: $XCFILELIST_DIR"
  exit 1
fi

XCFILELIST_COUNT=$(find "$XCFILELIST_DIR" -maxdepth 1 -name "*.xcfilelist" | wc -l | tr -d ' ')
if [ "${XCFILELIST_COUNT:-0}" -eq 0 ]; then
  echo "ERROR: no .xcfilelist files found in $XCFILELIST_DIR"
  ls -la "$XCFILELIST_DIR" || true
  exit 1
fi

echo "✓ Found $XCFILELIST_COUNT xcfilelist files in $XCFILELIST_DIR"
find "$XCFILELIST_DIR" -maxdepth 1 -name "*.xcfilelist" -print | sed 's#^#  - #'

echo ""
echo "=========================================="
echo "✓ Xcode Cloud setup complete"
echo "=========================================="
exit 0
