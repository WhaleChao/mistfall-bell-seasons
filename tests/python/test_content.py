from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path

from jsonschema import Draft202012Validator


ROOT = Path(__file__).resolve().parents[2]


def test_release_content_validation() -> None:
    result = subprocess.run(
        [sys.executable, str(ROOT / "scripts/validate_content.py"), "--release"],
        cwd=ROOT, capture_output=True, text=True, check=False,
    )
    assert result.returncode == 0, result.stdout + result.stderr


def test_save_fixture_matches_schema() -> None:
    schema = json.loads((ROOT / "schemas/save_game.schema.json").read_text(encoding="utf-8"))
    fixture = {
        "schema_version": 3,
        "player": {"name": "旅人", "appearance": {"body": "neutral"}, "position": [320.0, 180.0], "stats": {"health": 72, "max_health": 100, "attack": 16}, "coins": 500},
        "map": "mistfall_farm", "flags": {"gate_open": True},
        "quests": {"silence_the_warden": "active"}, "inventory": {"health_potion": 2},
        "calendar": {"year": 1, "season_index": 0, "season": "spring", "day": 30, "minute_of_day": 360, "speed_mode": "standard"},
        "weather": {"current": "clear", "forecast": {}},
        "farm": {"rank": 1, "plots": {}, "seed_stock": {}, "produce": {}, "animals": [], "greenhouse_unlocked": False, "unlocked_upgrades": []},
        "relationships": {}, "marriage": {"spouse_id": "", "married_absolute_day": 0, "family_talk_seen": False},
        "child": {"exists": False, "name": "", "born_absolute_day": 0, "stage": "none"},
        "festivals": {"attended": {}}, "dungeon": {}, "story": {}, "procedural": {},
        "tools": {"stamina": 80, "tool_levels": {"hoe": 2, "watering_can": 1, "axe": 1, "pickaxe": 1, "fishing_rod": 1, "sickle": 1}, "equipped_tool": "hoe"},
        "economy": {"shipping_bin": {}, "total_earned": 500, "total_spent": 100, "purchase_counts": {}, "last_shipping_total": 0},
        "achievements": {"unlocked": ["first_harvest"]},
        "lifetime_stats": {"days_played": 3, "crops_harvested": 1},
        "settings": {"master_volume": 0.8, "text_speed": 1.0, "fullscreen": False, "control_prompts": "auto"},
        "saved_at_unix": 1,
    }
    Draft202012Validator(schema).validate(fixture)


def test_registered_asset_hashes_match_files() -> None:
    assets = json.loads((ROOT / "data/assets/index.json").read_text(encoding="utf-8"))["assets"]
    for record in assets:
        asset_path = ROOT / record["source_path"].removeprefix("res://")
        assert asset_path.is_file(), record["id"]
        assert hashlib.sha256(asset_path.read_bytes()).hexdigest() == record["sha256"], record["id"]


def test_runtime_release_audit() -> None:
    result = subprocess.run(
        [sys.executable, str(ROOT / "scripts/audit_release.py")],
        cwd=ROOT, capture_output=True, text=True, check=False,
    )
    assert result.returncode == 0, result.stdout + result.stderr
