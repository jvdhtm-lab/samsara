# Samsara — Agent Status

Maintained per `AGENTS.md` §20. Updated at the end of each work session.

## Current phase

Phase 13 — Timeline Variation & 3D Presentation. **Status: complete.**

## Current milestone

Every timeline now varies deterministically (world theme/palette, variant
anomalies, relocated secret) and the world and characters render in 3D through
a top-down orthographic camera (2.5D) while the tested 2D gameplay drives
positions and interactions. Toggleable from Settings.

## Completed tasks

### Phases 1–11 (summary)
Layered foundation and saves; character rig + animations; exploration;
dialogue with routing/portraits; relationships and three quests; the Endless
Picnic and Returning Tree traps; the meta-narrative director and safe restart;
magic (Temporal Pause, Memory Echo); the timeline ending; Fern, the Hollow,
the Journal, and alternate-timeline variations.

### Phase 12 — polish & release
- **Audio:** `AudioManager` synthesizes looping **music** and **ambience** beds
  per area (village, workshop, hollow, picnic, menu, ending), crossfaded and
  respecting `music_volume`; playback is released on shutdown (ADR-028).
- **Settings/accessibility:** standalone `user://settings.json`
  (`SaveManager.save_settings/load_settings`) + a `SettingsMenu` owned by `Game`
  and reachable from the title and pause menus. Volume (master/music/sfx),
  reduce motion, high-contrast text, fullscreen, and text speed are live-applied.
- **Dialogue polish:** typewriter reveal with input **skip**, high-contrast
  style, and reduce-motion/text-speed awareness.
- **Feel:** player acceleration/friction; `SceneRouter` skips the fade under
  reduce motion (deferring a frame so callers inside `_ready` never swap scenes
  mid-add — fixes a boot-with-reduce-motion error).
- **Controller:** joypad buttons and left-stick axes registered on the existing
  actions, so the whole game is controller-playable.
- **Export:** `export_presets.cfg` (Windows Desktop + Linux/X11); templates
  installed; `build/windows/Samsara.exe` and `build/linux/Samsara.x86_64`
  produced, with the Windows build verified on launch (exit `0`).
- **Docs:** `docs/TESTING.md`, `docs/RELEASE.md`, ADR-028, updated
  `ARCHITECTURE.md`/`SAVE_FORMAT.md`.
- Test suite expanded to **493 assertions, all passing**, with no leaks.

### Phase 13 — variation & 3D presentation
- **Timeline variation:** `TimelineVariation` (systems, pure) derives a
  deterministic theme (`clear|dawn|dusk|storm|gloom`) from the timeline id +
  counters; `Game` applies `variation_theme` / `variant_<theme>` flags. Themes
  set the 3D palette, gate `variant` anomalies in `anomalies.json`, and relocate
  the cellar-key secret across two slots (`SecretFind.variation_slots`).
- **3D presentation (2.5D):** `AreaWorld3D` builds a 45° three-quarter
  orthographic 3D world (gradient sky, soft-shadowed sun, textured ground,
  grass, walls, houses/trees, detailed props, ambient particles) and `Actor3D`
  builds 3D creatures from `CharacterData`. 2D gameplay (collision/interaction)
  is unchanged; the 2D drawing is hidden. Toggled by
  `ApplicationSettings.use_3d_visuals` (on by default; settings-menu checkbox).
- **CC0 models:** Kenney Nature Kit, Survival Kit, and Fantasy Town Kit GLBs
  (`assets/models/{nature,survival,town}/`) loaded by `ModelLibrary` with
  auto-fit sizing and a procedural fallback (ADR-031, `docs/CREDITS.md`) —
  forest, workshop/hollow props, and village decor (fountain, stalls, banners,
  windmill, cart, hedges, street lantern).
- **CC0 character models:** Quaternius "Ultimate Platformer Pack" FBX
  (rigged + idle animation) mapped via `CharacterData.model_id` (ADR-032);
  procedural body remains the fallback. `assets/models/chars/`.
- **Asset expansion (user-provided, CC0/cleared):** KayKit Forest Nature Pack
  (forest in `assets/models/kaykit_forest/`); Gobkit Free Monster Pack
  (`assets/models/chars/minion-*.glb`, now the cast models); "Cooking Assets"
  (kitchen props in `assets/models/cooking/`, OBJ, placed on the picnic table
  and workshop bench). `ModelLibrary` now resolves `.glb/.gltf/.fbx/.obj`.
- **Look re-grade:** switched to the Forward+ renderer and re-graded the 3D
  scene (ACES tonemap, colour adjustments, glow, SSAO, fog; lower ambient,
  warmer sun, resaturated palettes) — ADR-033. Windows/Linux builds now require
  a Vulkan GPU. Rebuilt `build/windows/Samsara.exe` and `build/linux/Samsara.x86_64`.
- **Art-direction pass (ADR-034):** `VillageLayout` plan (roads, plaza,
  buildings with colours, perimeter foliage) drives both the 3D village and a
  **circular minimap** overlay; camera is now a **perspective 3/4 view (~40°,
  38° FOV) that follows the player**; warm key light + cool fill, soft shadows
  (4096), ACES tonemap, adjustments, glow, SSAO and light fog; ground detail
  (tint patches, stones, dirt road); accent-coloured doors/awnings. Reviewer
  notes still open: world-space door prompt labels and tilt-shift DoF.
- **Planet world (ADR-035):** the village sits on a **complete sphere** (radius
  760); flat 2D coordinates project onto it, content is bent onto the surface,
  roads are tiled into curved quads, and the camera keeps the 3/4 view while
  orbiting to follow the player. Houses are assembled from the CC0 Quaternius
  **Medieval Village MegaKit** (walls/windows/doors/gables/tiled roofs) with the
  kit's own door on a solid front wall and a dark interior so windows read
  properly; the world is large (bounds 780×520) with a **multi-axis street
  grid**. Tiny **autonomous critters** (`PetSwarm` + `Pet3D`, ~30, Gobkit
  minions/Quaternius enemies) are scattered across the island and wander,
  randomly follow the player, are nice to each other ("I love you!"), sometimes
  fight and kill each other (respawned to keep the population).
- Docs: ADR-029, ADR-030, ADR-031, updated `ARCHITECTURE.md`/`ART_BIBLE.md`/
  `NARRATIVE_BIBLE.md`/`SAVE_FORMAT.md`, added `docs/CREDITS.md`.
- Test suite expanded to **521 assertions, all passing**.

## Active tasks / owners

- None outstanding for Phase 12 acceptance.

## Blocked tasks

- None. The Godot 4.5.1 export templates were installed, and both presets were
  exported successfully.

## Known bugs

- None at the time of writing.

## Failed tests

- None.

## Outstanding design decisions

- Ability selection is contextual (first valid) rather than a browsable menu.
- Focus regeneration cadence (currently granted via effects) — revisit with
  content.

## Placeholders to replace

- Procedural character, prop, and background art (`docs/ART_BIBLE.md`).
- Audio is synthesized (tones + beds); replace or supplement with authored
  audio if desired.

## Verification evidence

- `godot --headless --path . --import` → no script errors.
- Headless load of `boot`, `main_menu`, `village`, `workshop`, `hollow`,
  `endless_picnic`, `timeline_ending`, and `settings_menu` → all clean.
- `godot --headless --path . res://tests/test_runner.tscn`
  → **521 passed, 0 failed**, including settings persistence, the audio
  catalog, controller bindings, reduce-motion transitions, the settings menu,
  the dialogue typewriter, per-timeline variation, 3D world construction with a
  45° camera (and the 2D fallback), and CC0 model loading/auto-fit.
- Export: `--export-release "Windows Desktop"` → `build/windows/Samsara.exe`
  (96.6 MB) + `Samsara.pck` (0.3 MB); `--export-release "Linux/X11"` →
  `build/linux/Samsara.x86_64`. Running the exported Windows binary
  (`--headless --quit-after 150`) boots and exits `0`.

## Next recommended task

Authored art/audio pass and richer 3D: replace primitive meshes with authored
character/environment models and the procedural audio with composed tracks, and
add more per-timeline variation content (extra themes, layout shifts).

