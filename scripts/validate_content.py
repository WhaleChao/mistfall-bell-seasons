from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator


ROOT = Path(__file__).resolve().parents[1]
TYPE_SCHEMAS = {
    "characters": "character_definition.schema.json",
    "enemies": "enemy_definition.schema.json",
    "items": "item_definition.schema.json",
    "skills": "skill_definition.schema.json",
    "sprites": "sprite_import.schema.json",
    "quests": "quest_definition.schema.json",
    "dialogues": "dialogue_graph.schema.json",
    "world_events": "world_event.schema.json",
    "seasons": "season_definition.schema.json",
    "crops": "crop_definition.schema.json",
    "fish": "fish_definition.schema.json",
    "animals": "animal_definition.schema.json",
    "npc_schedules": "npc_schedule.schema.json",
    "npc_dialogues": "npc_dialogue_bank.schema.json",
    "festivals": "festival_definition.schema.json",
    "farm_upgrades": "farm_upgrade.schema.json",
    "dungeons": "dungeon_definition.schema.json",
    "request_templates": "procedural_request_template.schema.json",
    "recipes": "recipe_definition.schema.json",
    "story_arcs": "story_arc_definition.schema.json",
    "relationship_events": "relationship_event_definition.schema.json",
    "tools": "tool_definition.schema.json",
    "shops": "shop_definition.schema.json",
    "achievements": "achievement_definition.schema.json",
}
STABLE_ID = re.compile(r"^[a-z][a-z0-9_]*$")


def load_json(path: Path, errors: list[str]) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"{path.relative_to(ROOT)}: {exc}")
        return None


def validate_schema(path: Path, value: Any, schema_name: str, errors: list[str]) -> None:
    schema = load_json(ROOT / "schemas" / schema_name, errors)
    if schema is None:
        return
    for error in Draft202012Validator(schema).iter_errors(value):
        location = "/".join(str(part) for part in error.absolute_path) or "$"
        errors.append(f"{path.relative_to(ROOT)}#{location}: {error.message}")


def collect_content(errors: list[str]) -> dict[str, dict[str, dict[str, Any]]]:
    content: dict[str, dict[str, dict[str, Any]]] = {}
    for artifact_type, schema_name in TYPE_SCHEMAS.items():
        content[artifact_type] = {}
        for path in sorted((ROOT / "data" / artifact_type).glob("*.json")):
            value = load_json(path, errors)
            if not isinstance(value, dict):
                continue
            validate_schema(path, value, schema_name, errors)
            records = value.get("definitions") if isinstance(value.get("definitions"), list) else [value]
            for record in records:
                if not isinstance(record, dict):
                    errors.append(f"{path.relative_to(ROOT)}: definition must be an object")
                    continue
                artifact_id = record.get("id", "")
                if not STABLE_ID.fullmatch(str(artifact_id)):
                    errors.append(f"{path.relative_to(ROOT)}: unstable id {artifact_id!r}")
                    continue
                if artifact_id in content[artifact_type]:
                    errors.append(f"{path.relative_to(ROOT)}: duplicate {artifact_type} id {artifact_id}")
                content[artifact_type][artifact_id] = record
    return content


def check_references(content: dict[str, dict[str, dict[str, Any]]], errors: list[str]) -> None:
    items = content["items"]
    dialogues = content["dialogues"]
    characters = content["characters"]
    quests = content["quests"]
    enemies = content["enemies"]
    for enemy in enemies.values():
        for drop in enemy.get("drops", []):
            if drop.get("item_id") not in items:
                errors.append(f"enemy {enemy['id']}: missing drop item {drop.get('item_id')}")
    for quest in quests.values():
        for reward in quest.get("rewards", []):
            if reward.get("type") == "item" and reward.get("id") not in items:
                errors.append(f"quest {quest['id']}: missing reward item {reward.get('id')}")
        for dialogue_id in quest.get("dialogue_refs", []):
            if dialogue_id not in dialogues:
                errors.append(f"quest {quest['id']}: missing dialogue {dialogue_id}")
    for dialogue in dialogues.values():
        for character_id in dialogue.get("characters", []):
            if character_id not in characters:
                errors.append(f"dialogue {dialogue['id']}: missing character {character_id}")
        nodes = {node.get("id") for node in dialogue.get("nodes", [])}
        if dialogue.get("start_node") not in nodes:
            errors.append(f"dialogue {dialogue['id']}: start node does not exist")
        for node in dialogue.get("nodes", []):
            next_ids = [node.get("next")] if node.get("next") else []
            next_ids.extend(option.get("next") for option in node.get("options", []))
            for next_id in next_ids:
                if next_id not in nodes:
                    errors.append(f"dialogue {dialogue['id']}/{node.get('id')}: missing next node {next_id}")
    for event in content["world_events"].values():
        for action in event.get("actions", []):
            if action.get("type") == "dialogue" and action.get("dialogue_id") not in dialogues:
                errors.append(f"world event {event['id']}: missing dialogue {action.get('dialogue_id')}")
            if action.get("type") == "quest" and action.get("quest_id") not in quests:
                errors.append(f"world event {event['id']}: missing quest {action.get('quest_id')}")
            if action.get("type") in {"give_item", "take_item"} and action.get("item_id") not in items:
                errors.append(f"world event {event['id']}: missing item {action.get('item_id')}")
    seasons = {definition.get("id") for definition in content["seasons"].values()}
    if seasons != {"spring", "summer", "autumn", "winter"}:
        errors.append("season catalog must define spring, summer, autumn, and winter")
    for season in seasons:
        crop_count = sum(season in crop.get("seasons", []) for crop in content["crops"].values())
        festival_days = sorted(festival.get("day") for festival in content["festivals"].values() if festival.get("season") == season)
        if crop_count != 12:
            errors.append(f"season {season}: expected 12 crops, found {crop_count}")
        if festival_days != [8, 18, 28]:
            errors.append(f"season {season}: festival days must be 8, 18, 28")
    dungeon = content["dungeons"].get("mistfall_depths")
    if not dungeon or dungeon.get("max_floor") != 40 or dungeon.get("boss_floors") != [10, 20, 30, 40]:
        errors.append("dungeon mistfall_depths must define 40 floors and bosses at 10/20/30/40")
    if dungeon:
        for enemy_id in dungeon.get("enemy_ids", []) + dungeon.get("boss_ids", []):
            if enemy_id not in enemies:
                errors.append(f"dungeon mistfall_depths: missing enemy {enemy_id}")
        boss_ids = dungeon.get("boss_ids", [])
        if len(boss_ids) != 4 or not all(enemies.get(enemy_id, {}).get("is_boss") for enemy_id in boss_ids):
            errors.append("dungeon mistfall_depths must reference four boss definitions")
    for shop in content["shops"].values():
        for offer in shop.get("offers", []):
            if offer.get("kind") == "item" and offer.get("target_id") not in items:
                errors.append(f"shop {shop['id']}: missing item {offer.get('target_id')}")
    if set(content["tools"]) != {"hoe", "watering_can", "axe", "pickaxe", "fishing_rod", "sickle"}:
        errors.append("tool catalog must define the six commercial tool types")
    npc_ids = {npc_id for npc_id in content["characters"] if npc_id != "hero"}
    if set(content["npc_schedules"]) != npc_ids:
        errors.append("NPC schedules must match the ten non-player character definitions")
    if set(content["npc_dialogues"]) != npc_ids:
        errors.append("NPC dialogue banks must match the ten non-player character definitions")
    for candidate in ("mira", "lian", "soren", "yuna"):
        heart_levels = sorted(event.get("hearts") for event in content["relationship_events"].values() if event.get("npc_id") == candidate)
        if heart_levels != [2, 4, 6, 8, 10]:
            errors.append(f"romance candidate {candidate}: expected heart events at 2/4/6/8/10")


def check_assets(release: bool, errors: list[str], warnings: list[str]) -> None:
    path = ROOT / "data" / "assets" / "index.json"
    value = load_json(path, errors)
    if not isinstance(value, dict) or not isinstance(value.get("assets"), list):
        errors.append("data/assets/index.json: expected assets array")
        return
    schema = load_json(ROOT / "schemas" / "asset_record.schema.json", errors)
    if schema is None:
        return
    validator = Draft202012Validator(schema)
    ids: set[str] = set()
    registered_paths: set[str] = set()
    for record in value["assets"]:
        for error in validator.iter_errors(record):
            errors.append(f"asset {record.get('id', '?')}: {error.message}")
        asset_id = str(record.get("id", ""))
        if asset_id in ids:
            errors.append(f"duplicate asset id {asset_id}")
        ids.add(asset_id)
        spdx = str(record.get("license", {}).get("spdx", "UNSPECIFIED"))
        if spdx in {"", "UNSPECIFIED"}:
            message = f"asset {asset_id}: license is unspecified"
            (errors if release else warnings).append(message)
        source_path = str(record.get("source_path", ""))
        if not source_path.startswith("res://"):
            errors.append(f"asset {asset_id}: source_path must use res://")
            continue
        registered_paths.add(source_path)
        asset_path = ROOT / source_path.removeprefix("res://")
        if not asset_path.is_file():
            errors.append(f"asset {asset_id}: source file does not exist: {source_path}")
            continue
        actual_sha256 = hashlib.sha256(asset_path.read_bytes()).hexdigest()
        expected_sha256 = str(record.get("sha256", ""))
        if actual_sha256 != expected_sha256:
            errors.append(
                f"asset {asset_id}: SHA-256 mismatch; expected {expected_sha256}, got {actual_sha256}"
            )
    runtime_asset_files = [
        *(path for path in (ROOT / "assets" / "runtime").rglob("*") if path.is_file() and not path.name.endswith(".import")),
        *(path for path in (ROOT / "assets" / "shaders").rglob("*") if path.is_file() and not path.name.endswith(".uid")),
        ROOT / "icon.svg",
    ]
    for asset_path in runtime_asset_files:
        source_path = "res://" + asset_path.relative_to(ROOT).as_posix()
        if source_path not in registered_paths:
            errors.append(f"unregistered runtime asset: {source_path}")


def check_manifest(errors: list[str]) -> None:
    path = ROOT / "data" / "project_manifest.json"
    value = load_json(path, errors)
    if value is not None:
        validate_schema(path, value, "project_manifest.schema.json", errors)


def check_export_boundary(errors: list[str]) -> None:
    path = ROOT / "export_presets.cfg"
    text = path.read_text(encoding="utf-8") if path.exists() else ""
    required = ["creator_service/*", "knowledge/*", ".creator/*", "schemas/*", "tools/*", "work/*", "assets/source/*"]
    for pattern in required:
        if pattern not in text:
            errors.append(f"export_presets.cfg: missing exclusion {pattern}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate PixelRPG versioned content and release boundaries")
    parser.add_argument("--release", action="store_true", help="treat missing asset licenses as errors")
    args = parser.parse_args()
    errors: list[str] = []
    warnings: list[str] = []
    check_manifest(errors)
    content = collect_content(errors)
    check_references(content, errors)
    check_assets(args.release, errors, warnings)
    check_export_boundary(errors)
    for warning in warnings:
        print(f"WARNING: {warning}")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        print(f"Validation failed with {len(errors)} error(s).")
        return 1
    count = sum(len(group) for group in content.values())
    print(f"Validated {count} content artifacts; release={args.release}; no errors.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
