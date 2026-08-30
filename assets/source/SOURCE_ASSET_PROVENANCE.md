# Source asset provenance

The four checkerboard atlases are the untouched source images generated through OpenAI built-in imagegen on 2026-08-30 under user direction. They use `LicenseRef-OpenAI-Generated`, and are retained only for reproducibility; `assets/source/*` is excluded from the commercial game export.

| Source | SHA-256 | Runtime derivative |
|---|---|---|
| `generated_atlases/character_atlas_checkerboard_source.png` | `7354dbd9a0ed60dedb8de633820bc394769f080fd9ef59fcdcf7a2797e33ab02` | `assets/runtime/sprites/character_atlas_alpha.png` |
| `generated_atlases/enemy_atlas_checkerboard_source.png` | `917759e5fcbbe7df435b3c38a61e9e2dbd5b3b4047efc341dfe416ef10990a65` | `assets/runtime/sprites/enemy_atlas_alpha.png` |
| `generated_atlases/animal_atlas_checkerboard_source.png` | `6bdba66c0b8593c8891b3d8a3d5bd14adcc917d1ae0c9d9d4bfc3ab8ba05a725` | `assets/runtime/sprites/animal_atlas_alpha.png` |
| `generated_atlases/player_walk_atlas_checkerboard_source.png` | `ff38826d3054d98b41f16c515e77b7ef493365a465baf10935ffe6b848046c85` | `assets/runtime/sprites/player_walk_atlas_alpha.png` |

`scripts/prepare_transparent_atlases.gd` performs a deterministic, cell-bounded four-neighbour flood fill from each atlas cell edge. It changes alpha only for connected neutral checkerboard pixels and leaves every RGB channel unchanged. The former broad chroma-key shader is retained in `legacy/` for audit history, but is no longer part of the runtime.
