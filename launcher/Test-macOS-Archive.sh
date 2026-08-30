#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  printf 'Usage: %s ARCHIVE VERSION [REPORT_DIRECTORY]\n' "$0" >&2
  exit 2
fi
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"
archive="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
version="$2"
report_root="${3:-$project_root/reports/macos_archive_verification}"
work_root="$project_root/work/macos-archive-verification"
case "$work_root" in
  "$project_root"/work/*) ;;
  *) printf 'Refusing unsafe work path: %s\n' "$work_root" >&2; exit 1 ;;
esac
rm -rf "$work_root"
mkdir -p "$work_root/extracted" "$work_root/runtime-home" "$report_root"

python3 "$project_root/scripts/audit_macos_archive.py" "$archive" --version "$version" --require-licenses --report "$report_root/archive.json"
ditto -x -k "$archive" "$work_root/extracted"
app_count="$(find "$work_root/extracted" -maxdepth 1 -type d -name '*.app' -print | wc -l | tr -d ' ')"
if [[ "$app_count" -ne 1 ]]; then
  printf 'Expected exactly one app bundle, found %d.\n' "$app_count" >&2
  exit 1
fi
app_bundle="$(find "$work_root/extracted" -maxdepth 1 -type d -name '*.app' -print -quit)"
plist="$app_bundle/Contents/Info.plist"
plutil -lint "$plist"
executable_name="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist")"
game_executable="$app_bundle/Contents/MacOS/$executable_name"
test -x "$game_executable"
architectures="$(lipo -archs "$game_executable")"
grep -qw 'x86_64' <<<"$architectures"
grep -qw 'arm64' <<<"$architectures"
codesign --verify --deep --strict --verbose=2 "$app_bundle"

runtime_stdout="$report_root/runtime.stdout.txt"
runtime_stderr="$report_root/runtime.stderr.txt"
network_log="$report_root/runtime_network.txt"
: > "$network_log"
HOME="$work_root/runtime-home" "$game_executable" --headless --quit-after 3600 >"$runtime_stdout" 2>"$runtime_stderr" &
game_pid=$!
network_samples=0
for _sample in $(seq 1 200); do
  if ! kill -0 "$game_pid" 2>/dev/null; then
    break
  fi
  network_samples=$((network_samples + 1))
  lsof -nP -a -p "$game_pid" -i >> "$network_log" 2>/dev/null || true
  sleep 0.05
done
set +e
wait "$game_pid"
runtime_exit=$?
set -e
cat "$runtime_stdout"
cat "$runtime_stderr" >&2
if [[ $runtime_exit -ne 0 ]]; then
  printf 'Published macOS game exited with status %d.\n' "$runtime_exit" >&2
  exit 1
fi
if grep -Eqi '^\s*(SCRIPT ERROR:|ERROR:)|Parse Error|Compile Error|Failed to load script|Failed to load resource' "$runtime_stdout" "$runtime_stderr"; then
  printf 'Published macOS game emitted engine errors.\n' >&2
  exit 1
fi
if [[ -s "$network_log" ]]; then
  printf 'Published macOS game opened a network endpoint in default offline mode.\n' >&2
  cat "$network_log" >&2
  exit 1
fi

archive_hash="$(shasum -a 256 "$archive" | awk '{print $1}')"
python3 - "$report_root/report.json" "$archive_hash" "$runtime_exit" "$network_samples" "$architectures" <<'PY'
import json
import platform
import sys
from datetime import datetime, timezone
from pathlib import Path

path, archive_hash, exit_code, samples, architectures = sys.argv[1:]
Path(path).write_text(json.dumps({
    "passed": True,
    "verified_at": datetime.now(timezone.utc).isoformat(),
    "os": platform.platform(),
    "archive_sha256": archive_hash,
    "runtime_exit_code": int(exit_code),
    "network_samples": int(samples),
    "network_endpoints": [],
    "architectures": architectures.split(),
    "codesign": "verified",
    "notarized": False,
}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
printf 'Published macOS archive passed Universal 2, signature, launch, and offline checks.\n'
