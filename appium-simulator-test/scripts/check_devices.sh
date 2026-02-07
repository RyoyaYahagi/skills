#!/usr/bin/env bash
set -euo pipefail

platform="${1:-}"

if [[ -z "$platform" ]]; then
  echo "Usage: check_devices.sh <ios|android>" >&2
  exit 1
fi

case "$platform" in
  ios)
    xcrun simctl list devices available 2>/dev/null
    ;;
  android)
    adb devices -l
    ;;
  *)
    echo "Unknown platform: $platform (use ios|android)" >&2
    exit 1
    ;;
esac
