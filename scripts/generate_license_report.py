from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    assets = json.loads((ROOT / "data/assets/index.json").read_text(encoding="utf-8"))["assets"]
    lines = ["# PixelRPG Asset License Report", "", "Generated from `data/assets/index.json`.", "", "| ID | Type | License | Author | Source |", "|---|---|---|---|---|"]
    for asset in sorted(assets, key=lambda item: item["id"]):
        license_info = asset.get("license", {})
        cells = [asset["id"], asset.get("kind", ""), license_info.get("spdx", "UNSPECIFIED"), license_info.get("author", ""), license_info.get("source", "")]
        lines.append("| " + " | ".join(str(cell).replace("|", "\\|") for cell in cells) + " |")
    output = ROOT / ".creator" / "ASSET_LICENSES.md"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(output)


if __name__ == "__main__":
    main()
