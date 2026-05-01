#!/bin/bash
set -euo pipefail

echo "==> Xcode Cloud: preparing Flutter iOS environment"

REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$PWD}"
cd "$REPO_ROOT"

FLUTTER_ROOT="${FLUTTER_ROOT:-$HOME/flutter}"
if [ ! -d "$FLUTTER_ROOT/bin" ]; then
  echo "==> Installing Flutter SDK (stable)"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_ROOT"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"

flutter --version
flutter config --no-analytics || true
flutter pub get
flutter precache --ios
flutter build ios --release --no-codesign --config-only

cd ios
pod install --repo-update

echo "==> Xcode Cloud: Flutter + CocoaPods setup complete"
