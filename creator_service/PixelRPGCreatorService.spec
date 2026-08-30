# PyInstaller build recipe for the local-only Windows Creator Service.

from PyInstaller.utils.hooks import (
    collect_data_files,
    collect_dynamic_libs,
    collect_submodules,
    copy_metadata,
)

hiddenimports = (
    collect_submodules("uvicorn")
    + collect_submodules("pydantic")
    + collect_submodules("docling")
    + collect_submodules("sqlite_vec")
)

# Docling discovers its built-in pipeline classes through package metadata,
# while docling-parse and sqlite-vec load native resources relative to their
# package directories.  Imports alone do not make those resources part of a
# one-file PyInstaller build.
datas = (
    copy_metadata("docling")
    + copy_metadata("docling-slim")
    + collect_data_files("docling_parse")
    + collect_data_files("rapidocr")
    + collect_data_files("sqlite_vec")
)
binaries = collect_dynamic_libs("docling_parse") + collect_dynamic_libs("sqlite_vec")

analysis = Analysis(
    ["bundle_entry.py"],
    pathex=["."],
    binaries=binaries,
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
)
pyz = PYZ(analysis.pure)
exe = EXE(
    pyz,
    analysis.scripts,
    analysis.binaries,
    analysis.datas,
    [],
    name="PixelRPGCreatorService",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
)
