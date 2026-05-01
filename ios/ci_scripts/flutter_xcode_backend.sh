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

BACKEND_SCRIPT="$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh"
if [ ! -f "$BACKEND_SCRIPT" ]; then
  echo "error: Flutter backend script not found at $BACKEND_SCRIPT" >&2
  exit 1
fi

echo "Flutter Xcode backend action: $ACTION"
echo "Using FLUTTER_ROOT: $FLUTTER_ROOT"
echo "Using backend script: $BACKEND_SCRIPT"

exec /bin/sh "$BACKEND_SCRIPT" "$ACTION"
