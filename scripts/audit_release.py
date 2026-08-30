from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUNTIME_ROOTS = (ROOT / "runtime", ROOT / "data", ROOT / "project.godot")
FORBIDDEN_PATTERNS = {
    "HTTP URL": re.compile(r"https?://", re.IGNORECASE),
    "network client": re.compile(r"\b(?:HTTPRequest|HTTPClient|WebSocketPeer|TCPServer|PacketPeerUDP)\b"),
    "creator service": re.compile(r"\bcreator[_ -]?service\b", re.IGNORECASE),
    "Ollama": re.compile(r"\bollama\b", re.IGNORECASE),
    "model payload": re.compile(r"\.(?:gguf|safetensors|onnx)\b", re.IGNORECASE),
}
REQUIRED_EXCLUDES = {
	"addons/*",
    "creator_service/*",
    "knowledge/*",
    "schemas/*",
    "tests/*",
    "screenshots/*",
    "reports/*",
    "launcher/*",
    "scripts/*",
    "tools/*",
	"work/*",
    "assets/source/*",
    ".creator/*",
    ".venv/*",
}
TEXT_SUFFIXES = {".gd", ".json", ".cfg", ".godot", ".tscn", ".tres"}


def iter_runtime_files() -> list[Path]:
    files: list[Path] = []
    for root in RUNTIME_ROOTS:
        if root.is_file():
            files.append(root)
        elif root.is_dir():
            files.extend(path for path in root.rglob("*") if path.is_file() and path.suffix.lower() in TEXT_SUFFIXES)
    return files


def audit_source(errors: list[str]) -> None:
    for path in iter_runtime_files():
        text = path.read_text(encoding="utf-8", errors="replace")
        for label, pattern in FORBIDDEN_PATTERNS.items():
            for match in pattern.finditer(text):
                line = text.count("\n", 0, match.start()) + 1
                errors.append(f"{path.relative_to(ROOT)}:{line}: forbidden {label}: {match.group(0)}")


def audit_export_boundary(errors: list[str]) -> None:
    preset = ROOT / "export_presets.cfg"
    text = preset.read_text(encoding="utf-8") if preset.is_file() else ""
    missing = sorted(pattern for pattern in REQUIRED_EXCLUDES if pattern not in text)
    for pattern in missing:
        errors.append(f"export_presets.cfg: missing exclusion {pattern}")


def audit_build(build_dir: Path, errors: list[str]) -> None:
    if not build_dir.exists():
        errors.append(f"release build directory does not exist: {build_dir}")
        return
    exes = list(build_dir.glob("*.exe"))
    pcks = list(build_dir.glob("*.pck"))
    if len(exes) != 1 or len(pcks) != 1:
        errors.append(f"release build must contain exactly one EXE and one PCK; found {len(exes)} EXE/{len(pcks)} PCK")
    forbidden_suffixes = {".gguf", ".safetensors", ".onnx", ".pdf", ".docx", ".pptx", ".xlsx"}
    for path in build_dir.rglob("*"):
        if path.is_file() and path.suffix.lower() in forbidden_suffixes:
            errors.append(f"release build contains forbidden design/model file: {path.relative_to(build_dir)}")


def audit_pck_strings(build_dir: Path, errors: list[str]) -> None:
	for pck in build_dir.glob("*.pck"):
		payload = pck.read_bytes().lower()
		for marker in (b"creator_service", b"creator_client", b"ollama", b"httprequest", b"127.0.0.1", b"/api/v1/assist", b".gguf", b"knowledge/", b"screenshots/", b"work/"):
			if marker in payload:
				errors.append(f"release PCK contains forbidden marker {marker.decode(errors='replace')}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit PixelRPG's offline runtime and export boundary")
    parser.add_argument("--build-dir", type=Path, help="also verify an exported Windows build")
    args = parser.parse_args()
    errors: list[str] = []
    audit_source(errors)
    audit_export_boundary(errors)
    if args.build_dir is not None:
        audit_build(args.build_dir.resolve(), errors)
        audit_pck_strings(args.build_dir.resolve(), errors)
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        print(f"Release audit failed with {len(errors)} error(s).")
        return 1
    print("Release audit passed: runtime is offline-only and AI/design sources are excluded.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
