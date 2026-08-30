#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$script_dir"
godot_path="${GODOT_PATH:-}"

if [[ -z "$godot_path" ]]; then
	for candidate in \
		"$project_root/tools/Godot.app/Contents/MacOS/Godot" \
		"/Applications/Godot.app/Contents/MacOS/Godot"; do
		if [[ -x "$candidate" ]]; then
			godot_path="$candidate"
			break
		fi
	done
fi

if [[ -z "$godot_path" ]]; then
	for command_name in godot godot4; do
		if command -v "$command_name" >/dev/null 2>&1; then
			godot_path="$(command -v "$command_name")"
			break
		fi
	done
fi

if [[ -z "$godot_path" || ! -x "$godot_path" ]]; then
	printf '找不到 Godot。請安裝 Godot 4.7.2，或以 GODOT_PATH 指向 Godot.app/Contents/MacOS/Godot。\n' >&2
	printf '按 Enter 關閉。\n' >&2
	read -r
	exit 1
fi

godot_version="$("$godot_path" --version)"
if [[ "$godot_version" != 4.7.2.* ]]; then
	printf '需要 Godot 4.7.2，目前找到：%s\n' "$godot_version" >&2
	printf '請設定 GODOT_PATH 後重試。按 Enter 關閉。\n' >&2
	read -r
	exit 1
fi

exec "$godot_path" --path "$project_root" "$@"
