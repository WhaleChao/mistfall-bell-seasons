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
mkdir -p "$project_root/work"
lock_dir="$project_root/work/.macos-commercial.lock"
if ! mkdir "$lock_dir" 2>/dev/null; then
	printf 'Another macOS commercial build is already using this worktree: %s\n' "$lock_dir" >&2
	if [[ -f "$lock_dir/owner" ]]; then
		printf 'Recorded owner: %s\n' "$(tr '\n' ' ' < "$lock_dir/owner")" >&2
	fi
	printf 'If no build is running, remove this stale lock directory and retry.\n' >&2
	exit 1
fi
game_pid=""
temp_base="${TMPDIR:-/tmp}"
temp_base="${temp_base%/}"
launch_tmp=""
cleanup() {
	if [[ -n "${game_pid:-}" ]] && kill -0 "$game_pid" 2>/dev/null; then
		kill "$game_pid" 2>/dev/null || true
		wait "$game_pid" 2>/dev/null || true
	fi
	if [[ -n "${launch_tmp:-}" ]]; then
		case "$launch_tmp" in
			"$temp_base"/mistfall-macos-launch.*) rm -rf "$launch_tmp" ;;
		esac
	fi
	rm -f "$lock_dir/owner"
	rmdir "$lock_dir" 2>/dev/null || true
}
trap cleanup EXIT
printf 'pid=%d\nstarted=%s\n' "$$" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$lock_dir/owner"
rm -rf "$work_root"
mkdir -p "$build_root" "$dist_root" "$work_root/extracted" "$work_root/runtime-home" "$report_root"
mkdir -p "$work_root/editor-home" "$work_root/smoke-home" "$work_root/image-home" "$work_root/commercial-home" "$work_root/resolution-home" "$work_root/acceptance-home" "$work_root/export-home"
rm -f "$raw_archive" "$final_archive"

godot_version="$("$godot_path" --version)"
template_version="${godot_version%%.official*}"
template_source=""
for candidate in \
	"$project_root/work/deps/export-templates/templates" \
	"$HOME/Library/Application Support/Godot/export_templates/$template_version"; do
	if [[ -f "$candidate/macos.zip" ]]; then
		template_source="$candidate"
		break
	fi
done
if [[ -z "$template_source" ]]; then
	printf 'Godot %s macOS export template was not found in project dependencies or the user template directory.\n' "$template_version" >&2
	exit 1
fi
export_template_root="$work_root/export-home/Library/Application Support/Godot/export_templates/$template_version"
mkdir -p "$export_template_root"
cp "$template_source/macos.zip" "$export_template_root/macos.zip"
if [[ -f "$template_source/version.txt" ]]; then
	cp "$template_source/version.txt" "$export_template_root/version.txt"
fi

run_godot_gate() {
	local gate_name="$1"
	local gate_home="$2"
	shift 2
	local gate_log="$work_root/${gate_name}.log"
	local gate_exit=0
	set +e
	PIXELRPG_TEST_ISOLATED=1 HOME="$gate_home" "$godot_path" "$@" > "$gate_log" 2>&1
	gate_exit=$?
	set -e
	cat "$gate_log"
	if [[ $gate_exit -ne 0 ]]; then
		printf 'Godot gate %s exited with status %d.\n' "$gate_name" "$gate_exit" >&2
		exit 1
	fi
	if grep -Eqi 'SCRIPT ERROR:|Parse Error|Compile Error|Failed to load script|Failed to load resource' "$gate_log"; then
		printf 'Godot gate %s emitted script or resource errors.\n' "$gate_name" >&2
		exit 1
	fi
}

cd "$project_root"
python3 scripts/validate_content.py --release
python3 scripts/audit_release.py
python3 scripts/generate_license_report.py
run_godot_gate editor "$work_root/editor-home" --headless --path . --editor --quit
run_godot_gate smoke "$work_root/smoke-home" --headless --path . --script res://tests/godot/smoke_test.gd
run_godot_gate commercial "$work_root/commercial-home" --headless --path . --script res://tests/godot/commercial_stress_test.gd
run_godot_gate resolution "$work_root/resolution-home" --path . --rendering-method gl_compatibility --position 4000,4000 --script res://tests/godot/resolution_layout_test.gd
run_godot_gate acceptance "$work_root/acceptance-home" --path . --rendering-method gl_compatibility --resolution 1280x720 --script res://tests/godot/full_feature_acceptance.gd
run_godot_gate image "$work_root/image-home" --headless --path . --script res://tests/godot/image_integrity_test.gd
run_godot_gate export "$work_root/export-home" --headless --path . --log-file "$work_root/export.godot.log" --export-release "macOS Universal" "$raw_archive"
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
mkdir -p "$licenses/docs"
cp "$project_root/README.md" "$licenses/README.md"
cp "$project_root/docs/BEGINNER_GUIDE.md" "$licenses/docs/BEGINNER_GUIDE.md"
cp "$project_root/docs/GAMEPLAY_GUIDE.md" "$licenses/docs/GAMEPLAY_GUIDE.md"
cp "$project_root/LICENSE" "$licenses/LICENSE.txt"
cp "$project_root/GODOT_ENGINE_LICENSE.txt" "$licenses/GODOT_ENGINE_LICENSE.txt"
cp "$project_root/GODOT_ENGINE_COPYRIGHT.txt" "$licenses/GODOT_ENGINE_COPYRIGHT.txt"
cp "$project_root/THIRD_PARTY.md" "$licenses/THIRD_PARTY_NOTICES.md"
cp "$project_root/.creator/ASSET_LICENSES.md" "$licenses/ASSET_LICENSES.md"
cp "$project_root/PRIVACY.md" "$licenses/PRIVACY.md"
cp "$project_root/SUPPORT.md" "$licenses/SUPPORT.md"
cp "$project_root/SERVER_GUIDE.md" "$licenses/SERVER_GUIDE.md"

# Export templates downloaded by CI or a developer can carry provenance or
# quarantine attributes into the generated bundle. Strip inherited metadata
# before signing so a locally built app can be opened through LaunchServices.
xattr -cr "$app_bundle"
codesign --force --deep --sign - "$app_bundle"
codesign --verify --deep --strict --verbose=2 "$app_bundle"
command -v lsof >/dev/null

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
game_pid=""
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

# Exercise the same LaunchServices path as opening the app from Finder. Keep the
# direct headless launch above for PID-scoped offline monitoring, then require a
# visible renderer here so a broken window/display startup cannot pass the gate.
gui_stdout="$report_root/gui.stdout.txt"
gui_stderr="$report_root/gui.stderr.txt"
gui_log="$report_root/gui.godot.log"
# LaunchServices-spawned apps do not inherit the terminal's Files & Folders
# permission. Capture under TMPDIR first so projects checked out in Documents
# are not rejected by System Policy, then copy the evidence into the report.
launch_tmp="$(mktemp -d "$temp_base/mistfall-macos-launch.XXXXXX")"
gui_home="$launch_tmp/home"
gui_stdout_tmp="$launch_tmp/gui.stdout.txt"
gui_stderr_tmp="$launch_tmp/gui.stderr.txt"
gui_log_tmp="$launch_tmp/gui.godot.log"
mkdir -p "$gui_home"
lsregister_path="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ -x "$lsregister_path" ]]; then
	"$lsregister_path" -f "$app_bundle" >/dev/null 2>&1 || true
	sleep 1
fi
gui_exit=1
for gui_attempt in 1 2 3 4 5; do
	: > "$gui_stdout_tmp"
	: > "$gui_stderr_tmp"
	: > "$gui_log_tmp"
	set +e
	open -n -F -W -o "$gui_stdout_tmp" --stderr "$gui_stderr_tmp" --env "HOME=$gui_home" "$app_bundle" --args --quit-after 600 --log-file "$gui_log_tmp"
	gui_exit=$?
	set -e
	if [[ $gui_exit -eq 0 ]]; then
		break
	fi
	if [[ $gui_attempt -lt 5 ]]; then
		printf 'LaunchServices attempt %d failed with status %d; retrying after registration settles.\n' "$gui_attempt" "$gui_exit" >&2
		sleep 2
	fi
done
cp "$gui_stdout_tmp" "$gui_stdout"
cp "$gui_stderr_tmp" "$gui_stderr"
cp "$gui_log_tmp" "$gui_log"
cat "$gui_stdout"
cat "$gui_stderr" >&2
if [[ $gui_exit -ne 0 ]]; then
  printf 'Exported macOS app failed to launch through LaunchServices (status %d).\n' "$gui_exit" >&2
  exit 1
fi
if grep -Eqi '^\s*(SCRIPT ERROR:|ERROR:)|Parse Error|Compile Error|Failed to load script|Failed to load resource' "$gui_stdout" "$gui_stderr" "$gui_log"; then
  printf 'Exported macOS GUI launch emitted engine errors.\n' >&2
  exit 1
fi
if ! grep -Eq 'OpenGL API|Metal API|Vulkan API' "$gui_stdout" "$gui_log"; then
  printf 'Exported macOS GUI launch did not initialize a visible renderer.\n' >&2
  exit 1
fi

ditto -c -k --sequesterRsrc --keepParent "$app_bundle" "$final_archive"
python3 scripts/audit_macos_archive.py "$final_archive" --version "$version" --require-licenses --report "$report_root/report.json"
archive_hash="$(shasum -a 256 "$final_archive" | awk '{print $1}')"
printf '%s  %s\n' "$archive_hash" "$(basename "$final_archive")" > "$dist_root/SHA256SUMS-macOS.txt"
bash "$script_dir/Test-macOS-Archive.sh" "$final_archive" "$version" "$report_root/final_archive"
python3 - "$report_root/runtime.json" "$runtime_exit" "$gui_exit" "$network_samples" "$architectures" <<'PY'
import json
import platform
import sys
from datetime import datetime, timezone
from pathlib import Path

path, exit_code, gui_exit_code, samples, architectures = sys.argv[1:]
Path(path).write_text(json.dumps({
    "passed": True,
    "tested_at": datetime.now(timezone.utc).isoformat(),
    "os": platform.platform(),
    "runtime_exit_code": int(exit_code),
    "launchservices_gui_exit_code": int(gui_exit_code),
    "visible_renderer_verified": True,
    "network_samples": int(samples),
    "network_endpoints": [],
    "architectures": architectures.split(),
    "codesign": "ad-hoc verified",
    "notarized": False,
}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
printf 'macOS Universal commercial archive passed structure, Universal 2, ad-hoc signature, launch, and offline checks: %s\n' "$final_archive"
