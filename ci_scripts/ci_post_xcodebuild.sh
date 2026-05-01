#!/bin/bash
set -e
echo "Xcode Cloud post-xcodebuild step completed."

RESULT_BUNDLE="/Volumes/workspace/resultbundle.xcresult"
if [ ! -d "$RESULT_BUNDLE" ]; then
  RESULT_BUNDLE="$(find /Volumes/workspace -maxdepth 3 -name "*.xcresult" -type d | head -1 || true)"
fi

if [ -n "${RESULT_BUNDLE:-}" ] && [ -d "$RESULT_BUNDLE" ]; then
  echo "Inspecting xcresult at: $RESULT_BUNDLE"
  xcrun xcresulttool get --legacy --path "$RESULT_BUNDLE" --format json > /tmp/xcresult.json || true
  if [ -f /tmp/xcresult.json ]; then
    echo "---- Extracted errors/warnings (tail) ----"
    grep -E "\"message\"|PhaseScriptExecution|error:|warning:" /tmp/xcresult.json | tail -120 || true
    echo "------------------------------------------"
  fi
fi

echo "Searching workspace logs for PhaseScriptExecution..."
grep -R "PhaseScriptExecution" /Volumes/workspace 2>/dev/null | tail -50 || true
