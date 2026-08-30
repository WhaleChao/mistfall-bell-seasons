from __future__ import annotations

import argparse
import hashlib
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
    "release cheat input": re.compile(r"\b(?:advance_day_debug|KEY_F4)\b"),
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
    "steam/*",
    "tools/*",
    "work/*",
    "assets/source/*",
    ".creator/*",
    ".venv/*",
}
TEXT_SUFFIXES = {".gd", ".json", ".cfg", ".godot", ".tscn", ".tres"}
SECRET_PATTERNS = {
    "GitHub token": re.compile(r"\b(?:ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})\b"),
    "OpenAI-style API key": re.compile(r"\bsk-[A-Za-z0-9_-]{20,}\b"),
    "AWS access key": re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    "private key": re.compile(r"-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----"),
}
SECRET_SCAN_EXCLUDES = {".git", ".godot", ".venv", "build", "dist", "tools", "work"}
PRIVATE_KEY_SUFFIXES = {".pfx", ".p12", ".key", ".pem"}
LEGAL_NOTICE_HASHES = {
    "GODOT_ENGINE_LICENSE.txt": "b0435e3b3e4e55238f05f4b306f30524a1b2e20147810d436eaa554fa6855c80",
    "GODOT_ENGINE_COPYRIGHT.txt": "cb1980c88089573bcacd7221d777c689bb8bbd778799f24c27fca0fe5f774d6d",
}


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


def audit_repository_secrets(errors: list[str]) -> None:
    for path in ROOT.rglob("*"):
        if not path.is_file() or any(part in SECRET_SCAN_EXCLUDES for part in path.relative_to(ROOT).parts):
            continue
        if path.suffix.lower() in PRIVATE_KEY_SUFFIXES:
            errors.append(f"{path.relative_to(ROOT)}: private signing/key material must not be stored in the repository")
            continue
        if path.stat().st_size > 2 * 1024 * 1024:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        for label, pattern in SECRET_PATTERNS.items():
            if pattern.search(text):
                errors.append(f"{path.relative_to(ROOT)}: possible {label} committed to repository")


def audit_legal_notices(errors: list[str]) -> None:
    for relative_path, expected_hash in LEGAL_NOTICE_HASHES.items():
        path = ROOT / relative_path
        if not path.is_file():
            errors.append(f"missing Godot 4.7.2 legal notice: {relative_path}")
            continue
        actual_hash = hashlib.sha256(path.read_bytes()).hexdigest()
        if actual_hash != expected_hash:
            errors.append(f"Godot 4.7.2 legal notice hash mismatch: {relative_path}")


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
    for exe in exes:
        payload = exe.read_bytes()
        if len(payload) < 1_000_000 or payload[:2] != b"MZ":
            errors.append(f"release executable is truncated or not a Windows PE file: {exe.name}")
    for pck in pcks:
        payload = pck.read_bytes()
        if len(payload) < 1_000_000 or len(payload) > 256 * 1024 * 1024 or payload[:4] != b"GDPC":
            errors.append(f"release PCK has invalid magic or unreasonable size: {pck.name} ({len(payload)} bytes)")


def audit_pck_strings(build_dir: Path, errors: list[str]) -> None:
    for pck in build_dir.glob("*.pck"):
        payload = pck.read_bytes().lower()
        # 127.0.0.1 is an intentional default for the optional player-hosted
        # ENet server. Keep auditing the specific Creator Service / AI markers
        # so multiplayer support cannot hide an accidental authoring-runtime
        # dependency in the commercial game package.
        for marker in (b"creator_service", b"creator_client", b"ollama", b"httprequest", b"/api/v1/assist", b".gguf", b"res://knowledge/", b"res://screenshots/", b"res://reports/", b"res://tests/", b"res://launcher/", b"res://scripts/", b"res://tools/", b"res://work/", b"res://schemas/", b"res://assets/source/", b"res://.creator/", b"res://.venv/"):
            if marker in payload:
                errors.append(f"release PCK contains forbidden marker {marker.decode(errors='replace')}")
        for marker in (b"project.binary", b"res://sample/main", b"res://runtime/autoload/game_state", b"res://assets/runtime/backgrounds/mistfall_farm_commercial"):
            if marker not in payload:
                errors.append(f"release PCK is missing required runtime marker {marker.decode(errors='replace')}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit PixelRPG's cloud-free runtime and export boundary")
    parser.add_argument("--build-dir", type=Path, help="also verify an exported Windows build")
    args = parser.parse_args()
    errors: list[str] = []
    audit_source(errors)
    audit_export_boundary(errors)
    audit_repository_secrets(errors)
    audit_legal_notices(errors)
    if args.build_dir is not None:
        audit_build(args.build_dir.resolve(), errors)
        audit_pck_strings(args.build_dir.resolve(), errors)
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        print(f"Release audit failed with {len(errors)} error(s).")
        return 1
    print("Release audit passed: runtime has no cloud/AI clients; optional player-hosted ENet is allowed; AI/design sources are excluded.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
