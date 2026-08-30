from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator

from .models import ValidationResult
from .settings import settings


SCHEMAS = {
    "characters": "character_definition.schema.json",
    "enemies": "enemy_definition.schema.json",
    "items": "item_definition.schema.json",
    "skills": "skill_definition.schema.json",
    "quests": "quest_definition.schema.json",
    "dialogues": "dialogue_graph.schema.json",
    "world_events": "world_event.schema.json",
}


def validate_draft(artifact_type: str, draft: dict[str, Any]) -> ValidationResult:
    if artifact_type == "answer":
        return ValidationResult(valid=True, errors=[])
    schema_name = SCHEMAS.get(artifact_type)
    if not schema_name:
        return ValidationResult(valid=False, errors=[f"Unknown artifact type: {artifact_type}"])
    path = settings.project_root / "schemas" / schema_name
    try:
        schema = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return ValidationResult(valid=False, errors=[f"Cannot load schema {schema_name}: {exc}"])
    validator = Draft202012Validator(schema)
    errors = [
        f"{'/'.join(str(part) for part in error.absolute_path) or '$'}: {error.message}"
        for error in sorted(validator.iter_errors(draft), key=lambda item: list(item.absolute_path))
    ]
    errors.extend(_reference_errors(artifact_type, draft))
    warnings: list[str] = []
    if not draft.get("id"):
        warnings.append("Draft has no stable id")
    return ValidationResult(valid=not errors, errors=errors, warnings=warnings)


def schema_for(artifact_type: str) -> dict[str, Any] | None:
    schema_name = SCHEMAS.get(artifact_type)
    if not schema_name:
        return None
    path: Path = settings.project_root / "schemas" / schema_name
    return json.loads(path.read_text(encoding="utf-8"))


def reference_catalog() -> dict[str, list[str]]:
    return {
        artifact_type: sorted(_load_ids(artifact_type))
        for artifact_type in ("characters", "enemies", "items", "skills", "quests", "dialogues")
    }


def _load_ids(artifact_type: str) -> set[str]:
    directory = settings.project_root / "data" / artifact_type
    ids: set[str] = set()
    if not directory.exists():
        return ids
    for path in directory.glob("*.json"):
        try:
            value = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if isinstance(value, dict) and value.get("id"):
            ids.add(str(value["id"]))
    return ids


def _reference_errors(artifact_type: str, draft: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if artifact_type == "dialogues":
        character_ids = _load_ids("characters")
        for character_id in draft.get("characters", []):
            if character_id not in character_ids:
                errors.append(f"characters: unknown character id {character_id!r}; use one of {sorted(character_ids)}")
        nodes = draft.get("nodes", [])
        node_ids = {node.get("id") for node in nodes if isinstance(node, dict)}
        if draft.get("start_node") not in node_ids:
            errors.append("start_node must reference an existing node")
        for node in nodes:
            if not isinstance(node, dict):
                continue
            node_id = node.get("id", "?")
            node_type = node.get("type")
            if node_type in {"line", "condition", "action"}:
                if node.get("next") not in node_ids:
                    errors.append(f"nodes/{node_id}/next: must reference an existing node")
            if node_type == "choice":
                if not node.get("options"):
                    errors.append(f"nodes/{node_id}/options: choice needs at least one option")
                for option in node.get("options", []):
                    if option.get("next") not in node_ids:
                        errors.append(f"nodes/{node_id}/options: next must reference an existing node")
    elif artifact_type == "enemies":
        item_ids = _load_ids("items")
        for drop in draft.get("drops", []):
            if drop.get("item_id") not in item_ids:
                errors.append(f"drops: unknown item id {drop.get('item_id')!r}")
    elif artifact_type == "quests":
        item_ids = _load_ids("items")
        dialogue_ids = _load_ids("dialogues")
        for reward in draft.get("rewards", []):
            if reward.get("type") == "item" and reward.get("id") not in item_ids:
                errors.append(f"rewards: unknown item id {reward.get('id')!r}")
        for dialogue_id in draft.get("dialogue_refs", []):
            if dialogue_id not in dialogue_ids:
                errors.append(f"dialogue_refs: unknown dialogue id {dialogue_id!r}")
    elif artifact_type == "world_events":
        known = {
            "dialogue": _load_ids("dialogues"), "quest": _load_ids("quests"),
            "give_item": _load_ids("items"), "take_item": _load_ids("items"),
        }
        fields = {"dialogue": "dialogue_id", "quest": "quest_id", "give_item": "item_id", "take_item": "item_id"}
        for action in draft.get("actions", []):
            action_type = action.get("type")
            if action_type in known and action.get(fields[action_type]) not in known[action_type]:
                errors.append(f"actions: unknown {fields[action_type]} {action.get(fields[action_type])!r}")
    return errors
