from __future__ import annotations

import argparse
import hashlib
import json
import plistlib
import struct
import sys
import zipfile
from pathlib import Path


EXPECTED_BUNDLE_ID = "com.whalechao.mistfall-bell-seasons"
CPU_X86_64 = 0x01000007
CPU_ARM64 = 0x0100000C
REQUIRED_LICENSES = {
    "README.md",
    "LICENSE.txt",
    "GODOT_ENGINE_LICENSE.txt",
    "GODOT_ENGINE_COPYRIGHT.txt",
    "THIRD_PARTY_NOTICES.md",
    "ASSET_LICENSES.md",
    "PRIVACY.md",
    "SUPPORT.md",
    "SERVER_GUIDE.md",
}
FORBIDDEN_NAMES = (
    "creator_service/",
    "knowledge/",
    "schemas/",
    "tests/",
    "screenshots/",
    "reports/",
    "launcher/",
    "scripts/",
    "steam/",
    "tools/",
    "assets/source/",
    ".creator/",
    ".venv/",
)
FORBIDDEN_PCK_MARKERS = (
    b"creator_service",
    b"creator_client",
    b"ollama",
    b"httprequest",
    b"/api/v1/assist",
    b".gguf",
    b"res://knowledge/",
    b"res://tests/",
    b"res://reports/",
    b"res://scripts/",
    b"res://assets/source/",
)
REQUIRED_PCK_MARKERS = (
    b"project.binary",
    b"res://sample/main",
    b"res://runtime/autoload/game_state",
    b"res://assets/runtime/backgrounds/mistfall_farm_commercial",
)


def display_zip_path(path: str) -> str:
    """Restore UTF-8 names from ZIPs whose Unicode flag was omitted by ditto."""
    try:
        return path.encode("cp437").decode("utf-8")
    except (UnicodeEncodeError, UnicodeDecodeError):
        return path


def universal_architectures(payload: bytes) -> set[int]:
    if len(payload) < 8:
        return set()
    magic = payload[:4]
    if magic == b"\xca\xfe\xba\xbe":
        endian, entry_size = ">", 20
    elif magic == b"\xbe\xba\xfe\xca":
        endian, entry_size = "<", 20
    elif magic == b"\xca\xfe\xba\xbf":
        endian, entry_size = ">", 32
    elif magic == b"\xbf\xba\xfe\xca":
        endian, entry_size = "<", 32
    else:
        return set()
    count = struct.unpack_from(f"{endian}I", payload, 4)[0]
    if count < 1 or count > 16 or len(payload) < 8 + count * entry_size:
        return set()
    return {struct.unpack_from(f"{endian}I", payload, 8 + index * entry_size)[0] for index in range(count)}


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit a Godot macOS Universal release ZIP")
    parser.add_argument("archive", type=Path)
    parser.add_argument("--version", required=True)
    parser.add_argument("--require-licenses", action="store_true")
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()

    archive = args.archive.resolve()
    errors: list[str] = []
    if not archive.is_file():
        print(f"ERROR: archive not found: {archive}")
        return 1

    with zipfile.ZipFile(archive) as package:
        infos = [entry for entry in package.infolist() if not entry.is_dir() and not entry.filename.startswith("__MACOSX/")]
        names = [entry.filename for entry in infos]
        app_roots = sorted({name.split("/", 1)[0] for name in names if name.split("/", 1)[0].endswith(".app")})
        if len(app_roots) != 1:
            errors.append(f"archive must contain exactly one top-level .app bundle; found {app_roots}")
            app_root = "Mistfall-Bell-Seasons.app"
        else:
            app_root = app_roots[0]

        plist_path = f"{app_root}/Contents/Info.plist"
        if plist_path not in names:
            errors.append("Info.plist is missing")
            plist: dict[str, object] = {}
        else:
            try:
                plist = plistlib.loads(package.read(plist_path))
            except Exception as error:  # pragma: no cover - exact parser failure is reported
                errors.append(f"Info.plist is invalid: {error}")
                plist = {}

        executable_name = str(plist.get("CFBundleExecutable", "Mistfall-Bell-Seasons"))
        expected_executable_path = f"{app_root}/Contents/MacOS/{executable_name}"
        macos_root = f"{app_root}/Contents/MacOS/"
        executable_candidates = [
            name for name in names
            if name.startswith(macos_root)
            and name != macos_root
            and "/" not in name.removeprefix(macos_root)
            and not name.rsplit("/", 1)[-1].startswith("._")
        ]
        # ditto writes Unicode ZIP entry names in the platform encoding without
        # always setting the UTF-8 flag. Info.plist remains authoritative, while
        # Python's zipfile may decode the one executable entry as CP437 mojibake.
        # Require exactly one Contents/MacOS file and audit that actual payload;
        # this keeps the structural gate strict without depending on a lossy
        # filename decoder.
        used_filename_encoding_fallback = False
        if expected_executable_path in names:
            executable_path = expected_executable_path
        elif len(executable_candidates) == 1:
            executable_path = executable_candidates[0]
            used_filename_encoding_fallback = True
        else:
            executable_path = expected_executable_path
        pck_candidates = [name for name in names if name.startswith(f"{app_root}/Contents/Resources/") and name.endswith(".pck")]
        if executable_path not in names:
            errors.append(f"bundle must contain exactly one main executable; found {executable_candidates}")
            executable = b""
            executable_mode = 0
            architectures: set[int] = set()
        else:
            executable = package.read(executable_path)
            executable_mode = package.getinfo(executable_path).external_attr >> 16
            architectures = universal_architectures(executable)
            if executable_mode & 0o111 == 0:
                errors.append(f"main executable lacks POSIX execute permissions: {oct(executable_mode)}")
            if architectures != {CPU_X86_64, CPU_ARM64}:
                errors.append(f"main executable is not Universal 2: {[hex(value) for value in sorted(architectures)]}")

        if len(pck_candidates) != 1:
            errors.append(f"bundle must contain exactly one PCK; found {pck_candidates}")
            pck_payload = b""
            pck_path = ""
        else:
            pck_path = pck_candidates[0]
            pck_payload = package.read(pck_path)
            if len(pck_payload) < 1_000_000 or pck_payload[:4] != b"GDPC":
                errors.append(f"PCK is truncated or invalid: {pck_path} ({len(pck_payload)} bytes)")
            lowered = pck_payload.lower()
            for marker in FORBIDDEN_PCK_MARKERS:
                if marker in lowered:
                    errors.append(f"PCK contains forbidden authoring marker: {marker.decode(errors='replace')}")
            for marker in REQUIRED_PCK_MARKERS:
                if marker not in lowered:
                    errors.append(f"PCK is missing runtime marker: {marker.decode(errors='replace')}")

        if plist.get("CFBundleIdentifier") != EXPECTED_BUNDLE_ID:
            errors.append(f"unexpected bundle identifier: {plist.get('CFBundleIdentifier')!r}")
        if str(plist.get("CFBundleShortVersionString", "")) != args.version:
            errors.append(f"unexpected short version: {plist.get('CFBundleShortVersionString')!r}")
        if str(plist.get("CFBundleVersion", "")) != args.version:
            errors.append(f"unexpected bundle version: {plist.get('CFBundleVersion')!r}")
        if plist.get("CFBundlePackageType") != "APPL":
            errors.append(f"unexpected bundle package type: {plist.get('CFBundlePackageType')!r}")

        lowered_names = [name.lower() for name in names]
        for forbidden in FORBIDDEN_NAMES:
            if any(forbidden in name for name in lowered_names):
                errors.append(f"archive contains forbidden authoring path: {forbidden}")

        license_root = f"{app_root}/Contents/Resources/Licenses/"
        bundled_licenses = {Path(name).name for name in names if name.startswith(license_root)}
        if args.require_licenses:
            missing_licenses = sorted(REQUIRED_LICENSES - bundled_licenses)
            if missing_licenses:
                errors.append(f"bundle is missing commercial notices: {missing_licenses}")

    report = {
        "passed": not errors,
        "archive": archive.name,
        "archive_bytes": archive.stat().st_size,
        "archive_sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
        "app_bundle": display_zip_path(app_root),
        "bundle_identifier": plist.get("CFBundleIdentifier"),
        "version": args.version,
        "executable": display_zip_path(executable_path),
        "plist_executable_name": executable_name,
        "zip_filename_encoding_fallback": used_filename_encoding_fallback,
        "executable_mode": oct(executable_mode),
        "architectures": ["x86_64" if value == CPU_X86_64 else "arm64" if value == CPU_ARM64 else hex(value) for value in sorted(architectures)],
        "pck": display_zip_path(pck_path),
        "pck_sha256": hashlib.sha256(pck_payload).hexdigest() if pck_payload else "",
        "commercial_notices": sorted(bundled_licenses),
        "errors": errors,
    }
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(
        f"macOS archive audit passed: {archive.name}; Universal 2; bundle {EXPECTED_BUNDLE_ID}; "
        f"{len(bundled_licenses)} commercial notices."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
