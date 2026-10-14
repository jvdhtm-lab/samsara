# Samsara — Module Architecture & Dependency Rules

This document describes the concrete module layout and the dependency rules for
the Phase 1 foundation. It is subordinate to the binding contract in
[`../ARCHITECTURE.md`](../ARCHITECTURE.md) and the project rules in
[`../AGENTS.md`](../AGENTS.md).

## Layers

The project is a modular monolith with one `scripts/` subfolder per layer.

| Layer | Folder | Responsibility | May depend on |
|-------|--------|----------------|---------------|
| Application | `scripts/application/` | Game flow, session ownership, command validation | domain, infrastructure |
| Domain | `scripts/domain/` | Authoritative state models + authored data definitions | nothing (pure) |
| Systems | `scripts/systems/` | Interaction, dialogue logic, conditions | domain |
| Infrastructure | `scripts/infrastructure/` | Events, persistence, serialization, validation | nothing (pure) |
| Presentation | `scripts/presentation/` | Scenes, visuals, input, UI | application, systems, domain (read-only) |

### Dependency direction (enforced by convention + review)

```
presentation  ──▶ systems ──▶ domain
      │                         ▲
      └────────▶ application ───┘
      └────────▶ infrastructure ◀── (events)
```

Rules:

1. `domain` depends on nothing. It never references nodes, scenes, or autoloads.
2. `infrastructure` is pure/static where possible so it is headless-testable.
3. `presentation` never writes authoritative state. It sends requests to
   `application` (`Game`) and reflects `EventBus` signals.
4. `application` validates requests, mutates `domain` state, then announces
   results on `EventBus`.
5. `systems` holds rules and pure logic, and may read `domain` state.
6. No circular dependencies. UI does not reach into other UI.
7. Only `Game`, `EventBus`, and `SaveManager` are autoloads; everything else is
   scene-owned.

## Mapping to the AGENTS.md folder blueprint

The Phase 1 task defines five semantic layers. The AGENTS.md blueprint defines
feature-oriented folders. They map as follows:

| Phase 1 layer | Blueprint folder(s) |
|---------------|---------------------|
| application | `scripts/application/` (≈ `core/`) |
| domain | `scripts/domain/` (≈ `core/game_state.gd`, `characters/`, `narrative/`) |
| systems | `scripts/systems/` (≈ `dialogue/`, `world/`) |
| infrastructure | `scripts/infrastructure/` (≈ `persistence/`, `core/event_bus.gd`) |
| presentation | `scripts/presentation/` (≈ `player/`, `ui/`, `characters/`) |

New feature code should be placed in the layer folder that matches its
responsibility, not its feature, until the project grows enough to justify a
split.

## Current modules

- application: `game.gd` (autoload), `scene_router.gd`,
  `timeline_initializer.gd`, `restart_controller.gd`
- domain: `timeline_state.gd`, `character_state.gd`, `meta_progression.gd`,
  `application_settings.gd`, `character_data.gd`
- systems: `interactable.gd`, `interaction_selector.gd`, `text_interactable.gd`,
  `door.gd`, `spawn_point.gd`, `dialogue_runner.gd`, `dialogue_conditions.gd`,
  `dialogue_library.gd`, `dialogue_validator.gd`, `character_registry.gd`,
  `quest_library.gd`, `quest_manager.gd`, `relationship_manager.gd`,
  `trap_machine.gd`, `trap_base.gd`, `meta_narrative.gd`, `narrative_director.gd`,
  `magic_library.gd`, `magic_manager.gd`, `timeline_ending.gd`, `journal.gd`,
  `timeline_variation.gd`
- infrastructure: `event_bus.gd` (autoload), `save_manager.gd` (autoload),
  `save_schema.gd`, `save_storage.gd`, `migration_manager.gd`,
  `audio_manager.gd` (autoload)
- presentation: `player_controller.gd`, `npc_controller.gd`,
  `character_rig.gd` + `character/*_layer.gd`, `area_controller.gd`,
  `sign.gd`, `prop.gd`, `interaction_prompt.gd`, `dialogue_ui.gd`,
  `hud_controller.gd`, `meta_ui.gd`, `main_menu.gd`, `pause_menu.gd`,
  `settings_menu.gd`, `boot.gd`,
  `world_background.gd`, `workshop_background.gd`, `picnic_background.gd`,
  `hollow_background.gd`, `trap_clue.gd`, `trap_exit.gd`, `loop_token.gd`,
  `secret_find.gd`, `endless_picnic.gd`, `returning_tree.gd`,
  `ending_trigger.gd`, `ending_sequence.gd`, `journal_ui.gd`,
  `world3d/actor_3d.gd`, `world3d/world_3d.gd`, `world3d/style_3d.gd`,
  `world3d/model_library.gd`

## State ownership

- `TimelineState` — resets every timeline. Owned by `Game`.
- `MetaProgression` — survives restarts. Owned by `Game`.
- `ApplicationSettings` — never reset by narrative events. Owned by `Game`.

`SaveManager` serializes all three into one versioned file, but they remain
logically separate; only `TimelineState` is replaced by a new timeline.

## Collision layers

| Layer | Name | Used by |
|-------|------|---------|
| 1 | world | static village bounds |
| 2 | player | `CharacterBody2D` |
| 3 (bit 4) | interactable | `Interactable` areas |

The player's `InteractionProbe` (`mask = 4`) detects `Interactable` areas.
`InteractionSelector.pick` chooses the target by descending
`interaction_priority`, then ascending distance, so NPCs and doors win over
decorative props.

## Areas, spawns, and transitions

- Each explorable scene is an `AreaController` root with a `location_id` and an
  optional `bounds` rect (used to build collision walls).
- `SpawnPoint` children mark where the player appears. On load, the area asks
  `Game.consume_spawn()` for the requested spawn id and places the player.
- `Door.interact()` calls `Game.change_area(scene, spawn)`; the application
  layer stores the spawn, then `SceneRouter` fades and swaps the scene. UI and
  props never call `change_scene` directly.
- `Sign`/`Prop` extend `TextInteractable`, which builds an in-memory dialogue
  definition and hands it to `Game.request_raw_dialogue` — reusing the single
  dialogue UI rather than a second text box.

## Testing

- `tests/framework.gd` — minimal assertions, no external dependency.
- `tests/run_tests.gd` + `tests/test_runner.tscn` — headless suite covering
  domain rules, dialogue logic, persistence/recovery, content validation,
  character rig animation, interaction priority, doors, spawn hand-off,
  traps, magic, the timeline ending, the journal, settings/audio/controller
  polish, and world-scene instantiation (village, workshop, picnic, hollow).

Run:

```
godot --headless --path . res://tests/test_runner.tscn
```
