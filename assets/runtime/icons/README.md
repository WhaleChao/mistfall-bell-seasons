# Runtime visual ID catalog

This directory contains the 194 required 64×64 raster visual IDs used by the
inventory, shops, recipes, world pickups, animals, tools and barn automation UI.
`manifest.json` is the release contract. Runtime code loads these PNG files
directly and reports a hard error for a missing ID; it does not draw a circle,
generic icon or SVG fallback.

The catalog was rasterized from the project's original, category-aware icon
designs (crop-specific packets and produce, fish silhouettes, dishes, animal
products, materials, tools and brass automation machinery). Corners remain
transparent and downscaling uses nearest-neighbour sampling.
