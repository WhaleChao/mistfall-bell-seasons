from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def load(path: str) -> dict:
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def test_calendar_has_four_thirty_day_seasons() -> None:
    seasons = load("data/seasons/seasons.json")["definitions"]
    assert [season["id"] for season in seasons] == ["spring", "summer", "autumn", "winter"]
    assert all(season["days"] == 30 for season in seasons)
    assert sum(season["days"] for season in seasons) == 120


def test_content_density_per_season() -> None:
    crops = load("data/crops/crops.json")["definitions"]
    festivals = load("data/festivals/festivals.json")["definitions"]
    recipes = load("data/recipes/recipes.json")["definitions"]
    expected_mix = {"fast": 3, "medium": 4, "long": 2, "regrow": 2, "rare": 1}
    for season in ("spring", "summer", "autumn", "winter"):
        season_crops = [crop for crop in crops if season in crop["seasons"]]
        assert len(season_crops) == 12
        assert {category: sum(crop["category"] == category for crop in season_crops) for category in expected_mix} == expected_mix
        assert sorted(festival["day"] for festival in festivals if festival["season"] == season) == [8, 18, 28]
        assert len([recipe for recipe in recipes if recipe["season"] == season]) == 10


def test_long_term_contracts() -> None:
    dungeon = load("data/dungeons/mistfall_depths.json")
    family = load("data/family/family_policy.json")
    assert dungeon["max_floor"] == 40
    assert dungeon["boss_floors"] == [10, 20, 30, 40]
    assert dungeon["elevator_interval"] == 5
    assert family["child"]["stages"] == {"baby": [0, 29], "toddler": [30, 89], "child": [90, 209], "teen": [210, None]}
    assert family["marriage"]["deadline"] is None


def test_generated_title_asset_is_registered() -> None:
    assets = load("data/assets/index.json")["assets"]
    record = next(asset for asset in assets if asset["id"] == "mistfall_farm_title")
    asset_path = ROOT / record["source_path"].removeprefix("res://")
    assert asset_path.is_file()
    assert record["license"]["spdx"] == "LicenseRef-OpenAI-Generated"


def test_commercial_narrative_and_portraits_are_registered() -> None:
    arc = load("data/story_arcs/mistfall_three_years.json")
    assert len(arc["chapters"]) == 12
    assert arc["deadline"] is None
    assert all(chapter["completion_conditions"] for chapter in arc["chapters"])
    assets = load("data/assets/index.json")["assets"]
    portrait = next(asset for asset in assets if asset["id"] == "romance_candidates_atlas")
    assert (ROOT / portrait["source_path"].removeprefix("res://")).is_file()
    assert portrait["license"]["spdx"] == "LicenseRef-OpenAI-Generated"
