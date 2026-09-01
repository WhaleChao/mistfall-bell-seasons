# Final-size actor atlas provenance

The `*_final.png` files in this directory are deterministic nearest-neighbour
derivatives of the corresponding registered OpenAI-generated runtime atlases.
They were produced on 2026-09-02 to make the authored frame size equal to the
in-game size. No third-party artwork was introduced.

Runtime rules:

- player frame: 47×47 px;
- regular NPC frame: 52×52 px;
- chicken frame: 47×47 px;
- livestock frame: 58×58 px;
- regular enemy frame: 48×51 px;
- boss frame: 60×64 px;
- drowned dreamer: 132×132 px;
- all actor sprites render at `Vector2.ONE` with nearest filtering;
- the actor node is anchored at the centre of its feet, not the image centre.

The world-v2 acceptance gate verifies the exact atlas dimensions, forbids
runtime fractional scale on the player and NPC sprites, and limits regular
actor height variance to 1.25× so that characters remain in proportion to
doors, bridges, beds, machines, and furniture.
