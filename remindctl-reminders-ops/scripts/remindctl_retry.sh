#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <command> [args...]" >&2
  exit 2
fi

max_retries="${REMINDCTL_MAX_RETRIES:-3}"
delays=(0.5 1 2)
attempt=1

while :; do
  tmp_out="$(mktemp)"
  set +e
  "$@" >"$tmp_out" 2>&1
  code=$?
  set -e

  out="$(cat "$tmp_out")"
  rm -f "$tmp_out"

  if [ $code -eq 0 ]; then
    printf "%s\n" "$out"
    exit 0
  fi

  if printf "%s" "$out" | grep -q "Mach error 4099"; then
    if [ "$attempt" -ge "$max_retries" ]; then
      printf "%s\n" "$out" >&2
      echo "retry-exhausted: Mach error 4099 (attempts=$attempt)" >&2
      exit $code
    fi
    idx=$((attempt - 1))
    sleep "${delays[$idx]}"
    attempt=$((attempt + 1))
    continue
  fi

  printf "%s\n" "$out" >&2
  exit $code
done
