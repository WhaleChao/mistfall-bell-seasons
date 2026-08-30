from __future__ import annotations

import json
import plistlib
import stat
import struct
import subprocess
import sys
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
AUDIT_SCRIPT = ROOT / "scripts/audit_macos_archive.py"
VERSION = "1.2.0"
SUPPORTED_MINIMUM_SYSTEM_VERSIONS = {
    "x86_64": "11.0",
    "arm64": "13.0",
}
CPU_X86_64 = 0x01000007
CPU_ARM64 = 0x0100000C


def _fat_universal_executable() -> bytes:
    header = b"\xca\xfe\xba\xbe" + struct.pack(">I", 2)
    header += struct.pack(">IIIII", CPU_X86_64, 0, 0, 0, 0)
    header += struct.pack(">IIIII", CPU_ARM64, 0, 0, 0, 0)
    return header.ljust(1_000_000, b"\0")


def _runtime_pck() -> bytes:
    markers = b"\0".join((
        b"project.binary",
        b"res://sample/main",
        b"res://runtime/autoload/game_state",
        b"res://assets/runtime/backgrounds/mistfall_farm_commercial",
    ))
    return (b"GDPC" + markers).ljust(1_000_000, b"\0")


def _write_archive(path: Path, minimum_system_versions: dict[str, str]) -> None:
    app_root = "Mistfall.app"
    executable_name = "Mistfall"
    plist = plistlib.dumps({
        "CFBundleExecutable": executable_name,
        "CFBundleIdentifier": "com.whalechao.mistfall-bell-seasons",
        "CFBundlePackageType": "APPL",
        "CFBundleShortVersionString": VERSION,
        "CFBundleVersion": VERSION,
        "LSMinimumSystemVersionByArchitecture": minimum_system_versions,
    })
    executable_info = zipfile.ZipInfo(f"{app_root}/Contents/MacOS/{executable_name}")
    executable_info.create_system = 3
    executable_info.external_attr = (stat.S_IFREG | 0o755) << 16
    with zipfile.ZipFile(path, "w") as package:
        package.writestr(f"{app_root}/Contents/Info.plist", plist)
        package.writestr(executable_info, _fat_universal_executable())
        package.writestr(f"{app_root}/Contents/Resources/Mistfall.pck", _runtime_pck())


def _run_audit(archive: Path, report: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            sys.executable,
            str(AUDIT_SCRIPT),
            str(archive),
            "--version",
            VERSION,
            "--report",
            str(report),
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )


def test_macos_export_preset_uses_godot_47_supported_baselines() -> None:
    preset = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
    assert 'application/min_macos_version_x86_64="11.0"' in preset
    assert 'application/min_macos_version_arm64="13.0"' in preset


def test_macos_archive_audit_accepts_supported_baselines(tmp_path: Path) -> None:
    archive = tmp_path / "supported.zip"
    report = tmp_path / "supported.json"
    _write_archive(archive, SUPPORTED_MINIMUM_SYSTEM_VERSIONS)

    result = _run_audit(archive, report)

    assert result.returncode == 0, result.stdout + result.stderr
    payload = json.loads(report.read_text(encoding="utf-8"))
    assert payload["passed"] is True
    assert payload["minimum_system_versions"] == SUPPORTED_MINIMUM_SYSTEM_VERSIONS


def test_macos_archive_audit_rejects_legacy_baselines(tmp_path: Path) -> None:
    archive = tmp_path / "legacy.zip"
    report = tmp_path / "legacy.json"
    legacy_versions = {"x86_64": "10.13", "arm64": "11.0"}
    _write_archive(archive, legacy_versions)

    result = _run_audit(archive, report)

    assert result.returncode == 1
    assert "unexpected minimum macOS versions" in result.stdout
    payload = json.loads(report.read_text(encoding="utf-8"))
    assert payload["passed"] is False
    assert payload["minimum_system_versions"] == legacy_versions
