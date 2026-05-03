#!/bin/sh
set -e
set -x

ACTION="$1"
if [ -z "${ACTION:-}" ]; then
  echo "error: missing action. Usage: flutter_xcode_backend.sh <build|embed_and_thin>" >&2
  exit 1
fi

IOS_DIR="${SRCROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
GENERATED_XCCONFIG="$IOS_DIR/Flutter/Generated.xcconfig"

if [ -z "${FLUTTER_ROOT:-}" ] && [ -f "$GENERATED_XCCONFIG" ]; then
  FLUTTER_ROOT="$(sed -n 's/^FLUTTER_ROOT=//p' "$GENERATED_XCCONFIG" | tail -n 1)"
  export FLUTTER_ROOT
fi

if [ -z "${FLUTTER_ROOT:-}" ]; then
  echo "error: FLUTTER_ROOT is not set and could not be read from $GENERATED_XCCONFIG" >&2
  exit 1
fi

if echo "$FLUTTER_ROOT" | grep -q '\\'; then
  echo "error: FLUTTER_ROOT appears to be a Windows path: $FLUTTER_ROOT" >&2
  echo "error: Regenerate ios/Flutter/Generated.xcconfig on macOS." >&2
  exit 1
fi

if [ -n "${FLUTTER_APPLICATION_PATH:-}" ] && echo "$FLUTTER_APPLICATION_PATH" | grep -q '\\'; then
  echo "error: FLUTTER_APPLICATION_PATH appears to be a Windows path: $FLUTTER_APPLICATION_PATH" >&2
  echo "error: Regenerate ios/Flutter/Generated.xcconfig on macOS." >&2
  exit 1
fi

BACKEND_SCRIPT="$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh"
if [ ! -f "$BACKEND_SCRIPT" ]; then
  echo "error: Flutter backend script not found at $BACKEND_SCRIPT" >&2
  exit 1
fi

echo "Flutter Xcode backend action: $ACTION"
echo "Using FLUTTER_ROOT: $FLUTTER_ROOT"
echo "Using backend script: $BACKEND_SCRIPT"
LOG_DIR="$IOS_DIR/Flutter"
LOG_FILE="$LOG_DIR/flutter_backend_${ACTION}.log"

echo "Logging Flutter backend output to: $LOG_FILE"

set -o pipefail
/bin/sh "$BACKEND_SCRIPT" "$ACTION" 2>&1 | tee "$LOG_FILE"
STATUS=$?
set +o pipefail

if [ "$STATUS" -ne 0 ]; then
  echo "error: Flutter Xcode backend failed with status $STATUS" >&2
  echo "error: Flutter config snapshot:" >&2
  echo "error:  FLUTTER_ROOT=$FLUTTER_ROOT" >&2
  echo "error:  FLUTTER_APPLICATION_PATH=${FLUTTER_APPLICATION_PATH:-<unset>}" >&2
  echo "error:  FLUTTER_BUILD_DIR=${FLUTTER_BUILD_DIR:-<unset>}" >&2
  ls -la "$LOG_DIR" >&2 || true
  exit "$STATUS"
fi

exit 0
