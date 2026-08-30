#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"
version="$(tr -d '\r\n' < "$project_root/VERSION")"
godot_path="${GODOT_PATH:-}"
if [[ -z "$godot_path" || ! -x "$godot_path" ]]; then
  printf 'GODOT_PATH must point to the executable inside Godot.app.\n' >&2
  exit 1
fi
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'Invalid VERSION: %s\n' "$version" >&2
  exit 1
fi

build_root="$project_root/build"
dist_root="$project_root/dist"
work_root="$project_root/work/macos-release"
raw_archive="$build_root/Mistfall-Bell-Seasons-macOS.zip"
final_archive="$dist_root/Mistfall-Bell-Seasons-v${version}-macOS-Universal.zip"
report_root="$project_root/reports/macos_archive"

case "$work_root" in
  "$project_root"/work/*) ;;
  *) printf 'Refusing unsafe work path: %s\n' "$work_root" >&2; exit 1 ;;
esac
rm -rf "$work_root"
mkdir -p "$build_root" "$dist_root" "$work_root/extracted" "$work_root/runtime-home" "$report_root"
rm -f "$raw_archive" "$final_archive"

cd "$project_root"
python3 scripts/validate_content.py --release
python3 scripts/audit_release.py
python3 scripts/generate_license_report.py
"$godot_path" --headless --path . --editor --quit
"$godot_path" --headless --path . --script res://tests/godot/smoke_test.gd
"$godot_path" --headless --path . --script res://tests/godot/image_integrity_test.gd
"$godot_path" --headless --path . --script res://tests/godot/commercial_stress_test.gd
"$godot_path" --headless --path . --export-release "macOS Universal" "$raw_archive"
python3 scripts/audit_macos_archive.py "$raw_archive" --version "$version" --report "$report_root/raw_export.json"

ditto -x -k "$raw_archive" "$work_root/extracted"
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
chmod +x "$game_executable"

architectures="$(lipo -archs "$game_executable")"
grep -qw 'x86_64' <<<"$architectures"
grep -qw 'arm64' <<<"$architectures"

licenses="$app_bundle/Contents/Resources/Licenses"
mkdir -p "$licenses"
cp "$project_root/README.md" "$licenses/README.md"
cp "$project_root/LICENSE" "$licenses/LICENSE.txt"
cp "$project_root/GODOT_ENGINE_LICENSE.txt" "$licenses/GODOT_ENGINE_LICENSE.txt"
cp "$project_root/GODOT_ENGINE_COPYRIGHT.txt" "$licenses/GODOT_ENGINE_COPYRIGHT.txt"
cp "$project_root/THIRD_PARTY.md" "$licenses/THIRD_PARTY_NOTICES.md"
cp "$project_root/.creator/ASSET_LICENSES.md" "$licenses/ASSET_LICENSES.md"
cp "$project_root/PRIVACY.md" "$licenses/PRIVACY.md"
cp "$project_root/SUPPORT.md" "$licenses/SUPPORT.md"
cp "$project_root/SERVER_GUIDE.md" "$licenses/SERVER_GUIDE.md"

codesign --force --deep --sign - "$app_bundle"
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
  printf 'Exported macOS game exited with status %d.\n' "$runtime_exit" >&2
  exit 1
fi
if grep -Eqi '^\s*(SCRIPT ERROR:|ERROR:)|Parse Error|Compile Error|Failed to load script|Failed to load resource' "$runtime_stdout" "$runtime_stderr"; then
  printf 'Exported macOS game emitted engine errors.\n' >&2
  exit 1
fi
if [[ -s "$network_log" ]]; then
  printf 'Exported macOS game opened a network endpoint in default offline mode:\n' >&2
  cat "$network_log" >&2
  exit 1
fi

ditto -c -k --sequesterRsrc --keepParent "$app_bundle" "$final_archive"
python3 scripts/audit_macos_archive.py "$final_archive" --version "$version" --require-licenses --report "$report_root/report.json"
archive_hash="$(shasum -a 256 "$final_archive" | awk '{print $1}')"
printf '%s  %s\n' "$archive_hash" "$(basename "$final_archive")" > "$dist_root/SHA256SUMS-macOS.txt"
python3 - "$report_root/runtime.json" "$runtime_exit" "$network_samples" "$architectures" <<'PY'
import json
import platform
import sys
from datetime import datetime, timezone
from pathlib import Path

path, exit_code, samples, architectures = sys.argv[1:]
Path(path).write_text(json.dumps({
    "passed": True,
    "tested_at": datetime.now(timezone.utc).isoformat(),
    "os": platform.platform(),
    "runtime_exit_code": int(exit_code),
    "network_samples": int(samples),
    "network_endpoints": [],
    "architectures": architectures.split(),
    "codesign": "ad-hoc verified",
    "notarized": False,
}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
printf 'macOS Universal commercial archive passed structure, Universal 2, ad-hoc signature, launch, and offline checks: %s\n' "$final_archive"
