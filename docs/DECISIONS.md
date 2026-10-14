# Samsara — Decision Log

Architecture Decision Records (ADRs). Append-only; supersede rather than edit
silently.

## ADR-001 — Layered module layout

**Status:** Accepted (Phase 1)

Adopt `scripts/{application,domain,systems,infrastructure,presentation}` as
defined in `docs/ARCHITECTURE.md`. Rationale: mirrors the Phase 1 mandate and
keeps shared architecture out of feature folders until scale justifies a split.

## ADR-002 — Runtime InputMap construction

**Status:** Accepted (Phase 1)

Input actions (`move_*`, `interact`, `pause`, `choice_*`) are registered in
`Game._ready()` via `InputMap` instead of a hand-authored `[input]` block in
`project.godot`. Rationale: avoids brittle serialized `InputEventKey` objects
and guarantees the project runs from a clean checkout. Follow-up: migrate to
`project.godot` bindings when a settings/remap UI is built (Phase 12).

## ADR-003 — Character identity as Resources, dialogue as JSON

**Status:** Accepted (Phase 1)

- Character identity/appearance: custom `CharacterData` Godot `Resource`
  (`resources/characters/*.tres`). Strongly structured, editor-friendly.
- Dialogue: JSON (`data/dialogue/*.json`). Chosen for authoring ergonomics and
  simple diffing; validated by tests.

## ADR-004 — Data-driven character visuals

**Status:** Accepted (Phase 1)

One `CharacterVisual` node draws every character from `CharacterData`
(silhouette, palette, face, accessory, marking). Adding a character means
adding a resource, not a script. Rationale: satisfies "distinct identities
without hardcoded branching" and keeps the art pipeline replaceable — this
drawing is an intentional placeholder for real sprites.

## ADR-005 — Atomic saves with backup; never delete the only save

**Status:** Accepted (Phase 1)

`SaveStorage.write_atomic` writes to a temp file, backs up the previous valid
save, then renames into place. On failure it falls back to copy and never
removes the existing save. `SaveManager.load_game` tries the slot, then the
backup, and rejects malformed data without deleting it.

## ADR-006 — Scene-based headless test runner

**Status:** Accepted (Phase 1)

Tests run by executing `tests/test_runner.tscn` (a `Node` whose `_ready` runs
the suite), not `--script`. Rationale: `--script` main-loop scripts did not
exit cleanly in this environment; the scene approach also runs with autoloads
present, enabling the dialogue integration test.

## ADR-007 — Three-way state separation

**Status:** Accepted (Phase 1)

`TimelineState` (reset per timeline), `MetaProgression` (persists), and
`ApplicationSettings` (never touched by narrative) are separate models even
though they are stored in one save file. Rationale: the restart contract
requires permitted meta-progression to survive while timeline state resets.

## ADR-008 — Layered cutout character rig

**Status:** Accepted (Phase 2)

Replace the single `_draw()` visual with a layered rig
(`scenes/characters/character_rig.tscn` + `CharacterRig`) whose parts are
separate `CharacterLayer` nodes: Shadow, BackAccessory, Body, and
Face/Eyes/Mouth/Marking (children of Body). The rig transforms layers and owns
animation state. Rationale: gives real, independently animated layers and an
extensible pipeline without requiring binary art yet; adding a character stays
a data change. Supersedes the Phase 1 monolithic `character_visual.gd`
(removed).

## ADR-009 — Separate motion, expression, and talk channels

**Status:** Accepted (Phase 2)

The rig exposes three independent channels: `motion` (idle/walk/uncanny_idle),
`expression` (neutral/happy/sad/afraid/surprised/uncanny), and `talking`. NPCs
can idle and talk simultaneously; the player can walk while a story expression
persists. Rationale: avoids an animation-name explosion and keeps narrative
expression data-driven. `tick(delta)` is public so tests run deterministically.

## ADR-010 — Interaction marker plus HUD text

**Status:** Accepted (Phase 2)

The current interaction target shows a floating cue above the object
(`InteractionPrompt`) in addition to the HUD's `[E] …` action text. Rationale:
the marker answers "which thing", the HUD answers "what will happen".

## ADR-011 — Interaction priority via a pure selector

**Status:** Accepted (Phase 3)

Add `interaction_priority` to `Interactable` and move target selection into
`InteractionSelector.pick` (priority desc, then distance asc). Rationale:
important objects (NPCs, doors) should win over props, and the rule becomes
unit-testable independent of the player node. Note: the property is named
`interaction_priority` because `Area2D` already exposes `priority`.

## ADR-012 — Areas own spawn hand-off; application owns navigation

**Status:** Accepted (Phase 3)

`AreaController` roots each explorable scene; `SpawnPoint` children mark
placement. Doors request transitions through `Game.change_area`, which stores
the pending spawn id and delegates to `SceneRouter`. Rationale: keeps
navigation and spawn state in the application layer, keeps scenes declarative,
and preserves the "UI/props never call change_scene directly" rule.

## ADR-013 — Props reuse the dialogue UI via raw definitions

**Status:** Accepted (Phase 3)

`TextInteractable` (base of `Sign` and `Prop`) builds an in-memory dialogue
definition and calls `Game.request_raw_dialogue`. Rationale: one presentation
component and one set of advance/input rules for all text, without forcing a
JSON file per sign. Authored NPC dialogue still loads by id from
`data/dialogue/`.

## ADR-014 — Conditional routing, node `next`, and line objects

**Status:** Accepted (Phase 4)

Extend the dialogue model with routing nodes (`routes` + conditions), node-level
`next`, and line objects (`{ "text", "expression" }`). Rationale: enables
state-dependent openings and "different subsequent responses" without bespoke
scripts, and lets lines drive the rig's expression channel. `DialogueRunner`
stays pure; the UI calls `resolve(timeline)` after entering a node.

## ADR-015 — Animated portraits reuse the character rig

**Status:** Accepted (Phase 4)

`DialogueUI` shows a portrait by instancing `character_rig.tscn` under a scaled
parent node, resolved through `CharacterRegistry` by speaker id. Rationale: one
art source for world and UI, working expressions and the talking animation for
free, and no separate portrait asset pipeline yet. Portraits hide for speakers
with no `CharacterData` (signs, props).

## ADR-016 — Static dialogue validation

**Status:** Accepted (Phase 4)

`DialogueValidator` returns a list of structural errors for a definition. The
test suite validates every authored file and includes a negative case.
Rationale: authored content is the highest-risk area for dangling references;
fail fast in CI rather than at runtime.

## ADR-017 — CharacterState and structured quest data (save v2)

**Status:** Accepted (Phase 5)

Formalize per-character state as `CharacterState` (attributes + character flags
+ `met`) and quest state as `{status, objectives}` maps inside `TimelineState`.
`SaveSchema.CURRENT_VERSION` becomes 2; `MigrationManager` upgrades v1 payloads
(`relationships` -> `characters`, `quest_state` -> `quests`) before validation.
`TimelineState.from_dict` also accepts the legacy shapes directly. Rationale:
quests need per-objective tracking, and character-scoped flags belong with the
character; the version bump keeps old saves loadable.

## ADR-018 — QuestManager transitions; Game grants rewards

**Status:** Accepted (Phase 5)

`QuestManager` (static) owns status/objective transitions and emits events but
does not grant rewards. The application layer (`Game`) applies a quest's
`rewards`/`consequences` exactly once when `complete_objective`/`complete_quest`
reports a completion transition. Rationale: keeps reward logic in one place and
prevents double-granting, while the systems layer stays pure and testable.

## ADR-019 — Reaction expressions from relationship state

**Status:** Accepted (Phase 5)

`RelationshipManager.reaction_expression` derives an idle expression from
relationship attributes; `NpcController` re-applies it on
`relationship_changed` and `quest_completed`. Rationale: characters visibly
respond to how the player treated them without per-character code, reusing the
rig's expression channel.

## ADR-020 — New-timeline initializer + verified isolation

**Status:** Accepted (Phase 6)

`TimelineInitializer` builds a fresh timeline and `verify_isolation` reports
leaked character/quest/flag/location state or a non-regenerated id.
`Game.begin_new_timeline` performs the reset, runs the check, records
`meta.last_outcome`, and emits `timeline_started` without navigating (so it is
testable); `start_new_timeline` adds navigation. `SaveManager` paths are
injectable and `clear_slot` exists for tests and explicit deletion. Rationale:
restart isolation must be an explicit, verifiable invariant rather than an
assumption, and tests must never touch the player's real save.

## ADR-021 — Reusable trap machine with timeline-backed state

**Status:** Accepted (Phase 7)

`TrapMachine` (static) is a four-state machine (dormant → active → discovered →
resolved) over `TimelineState.traps`; `TrapBase` is a scene root wrapping it
with hooks. Traps are driven from content via a `trap` dialogue effect and read
via `trap_iteration`/`trap_state` conditions. Rationale: the loop's state must
reset per timeline and persist in saves, and content (not code) should escalate
it. A resolved trap cannot re-activate, satisfying "revisited without
inconsistent state".

## ADR-022 — Procedural audio via AudioManager

**Status:** Accepted (Phase 7)

Add an `AudioManager` autoload whose `play_tone(freq, duration, volume)` builds
and caches short sine tones (with an envelope), respecting
`settings.sfx_volume`. Rationale: the trap needs sound feedback now, and this is
genuine synthesis rather than a stub; it can be replaced or supplemented by
authored audio in Phase 12 without changing call sites. The trap's loop is
driven by a child `Timer` node (not a coroutine) so it frees with the scene and
never leaks.

## ADR-023 — Defined meta-narrative progression + anomaly director

**Status:** Accepted (Phase 8)

`MetaNarrative` computes a stage (0–5) from a `pressure` scalar derived from
quests, the first trap, recorded anomalies, and prior restarts.
`NarrativeDirector` watches relevant events, applies a stage's authored
anomalies (from `data/events/anomalies.json`) through `Game.apply_effects`, and
emits `meta_stage_changed` / `anomaly_triggered`. `MetaUI` renders escalating
effects. Rationale: escalation must be a defined model with authored content,
not random — and the director observes events rather than mutating scene nodes.

## ADR-024 — Restart controller with archiving, never destructive

**Status:** Accepted (Phase 8)

`RestartController` (application, `CanvasLayer`) owns the
AVAILABLE→CONFIRMATION→RESTARTING→NEW_TIMELINE flow and the confirmation UI.
`confirm()` archives the current timeline, calls `Game.begin_new_timeline()`
(which verifies isolation), and re-saves. Rationale: the fiction treats a
restarted universe as lost, but the application must never depend on deleting
the player's only save — the old timeline is archived and the backup preserved.
Only `user://saves/` is written.

## ADR-025 — Data-driven abilities with a pure validator and focus resource

**Status:** Accepted (Phase 9)

Abilities are authored JSON (`data/abilities/`), loaded by `MagicLibrary`.
`MagicManager` (static) validates and spends the per-timeline **Focus**
resource; `Game.use_magic` applies the ability's effects (same effect
vocabulary as dialogue) with `@active` resolved to the current trap. Abilities
are unlocked via `MetaProgression` and mirrored to `ability_<id>` timeline flags
for generic dialogue conditions. Rationale: keep ability behavior data-driven,
validation pure/testable, and avoid a parallel resource system; contextual
limitations (`requires_trap`, `requires_discovered_trap`) make magic a reward
for understanding rather than a bypass.

## ADR-026 — Explicit ending conditions with a generated epilogue

**Status:** Accepted (Phase 10)

`TimelineEnding` (static) defines three completion conditions (all quests, the
picnic resolved, stage ≥ 4) and generates the epilogue from live state
(relationship levels, quest outcomes, picnic resolution, prior completions).
`EndingTrigger` offers completion at the plaza lantern; `Game.begin_ending`
records completion in meta-progression and routes to the `EndingSequence`.
Rationale: the ending must be earned, reflect the player's specific journey,
and persist (completed_timelines, ending_<resolution> discovery) — completing
the timeline, not erasing it.

## ADR-027 — Reusable trap parts, a second trap, and a cross-timeline journal

**Status:** Accepted (Phase 11)

Content expansion generalises rather than forks:

- The picnic's bespoke leaf scripts become reusable interactables:
  `TrapClue` (two-look rule discovery), `TrapExit` (flag-gated escape), and
  `LoopToken` (a manual, iteration-escalating loop driver). The picnic scene is
  migrated to them; `picnic_clue.gd`/`picnic_exit.gd` are removed.
- The **Hollow** (`scenes/world/hollow.tscn`) adds a second trap,
  `ReturningTree`, reusing `TrapBase` and the shared parts; the cellar door
  (unlocked by the `secret_find` key) leads to it. A new character, **Fern**,
  a quest `fern_hollow`, and a new ability `memory_echo` extend the cast and
  magic through existing registries/libraries (no new systems).
- `Game.context_ability()` selects the first unlocked ability valid for the
  active trap, so one magic input serves several abilities without a selection
  UI (resolves the Phase 9 deferral pragmatically).
- **Alternate-timeline variations:** `Game._sync_meta_flags()` mirrors
  `restart_count`/`completed_timelines` into `meta_restarted` /
  `meta_completed_before` timeline flags, letting authored dialogue
  (`fern_intro`) branch on prior timelines using existing conditions.
- The **journal** (`Journal` pure labels + `JournalUI` overlay) surfaces
  `MetaProgression.anomalies_seen`/`discoveries` — knowledge that survives
  restarts — reusing the existing meta model rather than adding one.

Rationale: Phase 11 must add content without duplicating core logic or
breaking continuity; every new piece plugs into an existing contract, and the
new tests keep the additions covered.

## ADR-028 — Release polish: audio beds, standalone settings, accessibility

**Status:** Accepted (Phase 12)

- **Audio:** `AudioManager` gains `play_music`/`play_ambience` over small
  authored specs, synthesizing seamless looping beds (additive partials +
  filtered noise) cached by track id. Scenes request tracks through
  `AreaController.music_id`/`ambience_id`; the menu and ending set their own.
  Music respects `settings.music_volume`; `shutdown_audio` releases playbacks so
  looping beds do not leak at exit.
- **Settings:** application settings persist to a standalone `user://settings.json`
  (`SaveManager.save_settings/load_settings`), independent of a timeline save,
  and are edited through a `SettingsMenu` owned by `Game` (reachable from the
  title and pause menus). Volume, reduce-motion, high-contrast text, fullscreen,
  and text speed are all live-applied.
- **Accessibility / feel:** dialogue gains a typewriter reveal with skip and a
  high-contrast style; the player uses acceleration/friction; `SceneRouter`
  skips the fade when reduced motion is on (still deferring one frame so a
  caller inside `_ready` never swaps scenes mid-add).
- **Input:** joypad buttons and the left-stick axes are registered on the same
  actions as the keyboard, so the whole game is playable on a controller.
- **Export:** `export_presets.cfg` defines Windows Desktop and Linux/X11 presets;
  installing the matching export templates is an external prerequisite
  (`docs/RELEASE.md`).

Rationale: release work should refine presentation and reach without
introducing new systems; each change extends a boundary that already exists and
is covered by tests.

## ADR-029 — Deterministic per-timeline variation

**Status:** Accepted (Phase 13)

`TimelineVariation` (systems, pure/static) derives a stable theme and related
values from the timeline id plus cross-timeline counters. `Game._sync_meta_flags`
applies the theme as timeline flags (`variation_theme`, `variant_<theme>`) on
every new/loaded timeline. The theme drives the world palette (3D), a set of
variant anomalies (`NarrativeDirector` skips anomalies whose `variant` does not
match), and relocates the cellar-key secret via `SecretFind.variation_slots`
(two candidate slots, one active per timeline). Rationale: "every timeline is
different" without harming determinism — reloading a save reproduces the same
variation, and tests stay stable because a raw `TimelineState` carries no
variation flags.

## ADR-030 — 3D presentation layer over 2D gameplay

**Status:** Accepted (Phase 13)

Presentation moves to 3D while gameplay stays 2D. `AreaController` builds an
`AreaWorld3D` node (top-down orthographic `Camera3D`, `WorldEnvironment`,
`DirectionalLight3D`, primitive-mesh environment and props) and `Actor3D`
creatures from `CharacterData`; the linked 2D gameplay nodes keep collision and
interaction and only their drawing is hidden. A 45° (three-quarter) orthographic
camera frames the area; 3D ground (x, 0, z) lines up with the 2D layout so the
world matches the invisible collisions. The layer is toggled by
`ApplicationSettings.use_3d_visuals` (settings menu, on by default). Rationale:
deliver the requested 3D characters/world in a 2.5D view without rewriting the
tested 2D logic; the 2D procedural art remains as a fallback. This intentionally
supersedes the "2D top-down" line in `AGENTS.md` (requested by the project
owner). Note: the class is `AreaWorld3D` because `World3D` is a native Godot
resource.

## ADR-031 — CC0 3D models with procedural fallback

**Status:** Accepted (Phase 13)

The 3D world optionally uses CC0 low-poly models from Kenney's *Nature Kit*
(`assets/models/nature/*.glb`), loaded by `ModelLibrary`. Models are auto-fitted
to a target size by measuring their mesh bounds (so unknown source scales
self-correct) and placed with the base on the ground. Characters stay
procedural (identity comes from `CharacterData`). If a model is missing the
world falls back to primitives, so the game always runs. Attribution is in
`docs/CREDITS.md`. Rationale: real models raise the detail level as requested
while keeping the build self-contained and robust.

## ADR-034 — Authored village plan, map overlay, and a 3/4 graded camera

**Status:** Accepted (Phase 13)

- **Plan:** `VillageLayout` generates the village **per timeline** from a seed
  (`Game.timeline.timeline_id` + restart count) using **rules**: the island
  radius, plaza position, road layout (crossroads / T-junction / parallel
  streets), and 3–5 houses all vary; the 3 houses that carry the functional
  doors face the road; NPCs and the player spawn on the plaza/road; and
  foliage/scatter/stones are rejected anywhere on a road or inside a building.
  `AreaController` moves the 2D gameplay nodes to match; `AreaWorld3D` and
  `WorldMap` read the same plan, so the collided world, the 3D build, and the
  map can never disagree. **Restarting the universe reseeds it, so each timeline
  is an entirely different — but coherent — world.**
- **Camera:** a **perspective 3/4 view** (~40° pitch, 38° FOV) that **follows
  the player** — the "toy-diorama" feel requested.
- **Look:** warm key light (#FFE2B8) with soft shadows, cool sky fill
  (#8FB4E8), lower exposure, ACES tonemap, colour adjustments, subtle glow,
  SSAO, and light pastel fog. This requires the **Forward+** renderer; on GL
  Compatibility the Environment post-processing is ignored (and setting
  `adjustment_enabled` there renders black), so the game must ship Forward+.
- **Minimap:** a circular overlay (masked, bordered, north indicator) showing
  the plan and live actor dots.

Rationale: deliver the requested "premium stylized" direction (exposure,
sun + soft shadows, grading, 3/4 camera, minimap, ground detail) in a way that
keeps a single source of truth for the layout.

## ADR-035 — Spherical planet world

**Status:** Accepted (Phase 13)

The village is placed on a **complete sphere** (a small planet). Flat 2D
coordinates map onto the sphere with an **azimuthal projection** centred at the
village (`AreaWorld3D._normal`/`_surface`/`place_flat`, radius 300), so the
existing 2D gameplay is untouched. Content is built flat and then **bent** onto
the surface (`_bend`): each top-level node's origin is mapped to the sphere and
oriented by the local surface basis, so buildings/trees/props stand along the
surface normal. Roads are **tiled into small quads** so they curve with the
surface. Actors are placed on the sphere each frame and the **camera keeps the
same 3/4 view, orbiting to follow the player** across the surface. Houses are
assembled from the CC0 Quaternius **Medieval Village MegaKit** (`_house`).
Rationale: a "planet" world that the character walks over, without rewriting the
2D gameplay or the camera feel.

## ADR-032 — Data-driven CC0 character models

**Status:** Accepted (Phase 13)

Characters can name a CC0 model via `CharacterData.model_id` (with
`model_yaw`). When set and present, `Actor3D` instantiates the FBX/GLB, auto-fits
it to the character's size, orients it toward the camera, and plays its first
`idle` animation; otherwise it builds the procedural creature. The cast maps to
Quaternius "Ultimate Platformer Pack" models (CC0) by palette: Pip→Finn the
Frog, Momo→Fernando the Flamingo, Fern→Rae the Red Panda, Lumi→Barbara the Bee,
Player→a Mech. Rationale: a data-driven, reversible way to adopt real character
art (requested) without hardcoding, and without losing the procedural fallback.

## ADR-033 — Forward+ renderer and a colour grade for the 3D look

**Status:** Accepted (Phase 13)

The project switched from the GL Compatibility renderer to **Forward+**
(desktop; `mobile` fallback) so post-processing actually applies, and the 3D
environment was re-graded: ACES tonemap at 0.85 exposure, a colour adjustment
(contrast 1.18, saturation 1.3, brightness −0.03), subtle glow, SSAO, and light
depth fog; ambient light energy lowered to 0.55 and the sun warmed. The timeline
palettes were resaturated. Rationale: the previous Compatibility setup could not
run adjustments/SSAO/glow and looked bright and flat. Trade-off: the desktop
build now requires a Vulkan-capable GPU (the project's target machine has one);
revert `rendering/renderer/rendering_method` to `gl_compatibility` if broader
support is needed.









