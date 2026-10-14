# Samsara — Testing

The project ships with a headless, scene-based test suite. It runs without a
display, windows, or the editor, so it is safe in CI.

## Running

```
godot --headless --path . res://tests/test_runner.tscn
```

The runner prints a section per test group and exits non-zero if anything
fails:

```
Tests complete: 507 passed, 0 failed
```

It also releases audio playbacks before quitting, so a clean run ends without
leaked-instance warnings.

## Structure

- `tests/framework.gd` — a tiny assertion helper (`section`, `check`, `equal`,
  `is_true`, `is_false`). No external dependency.
- `tests/run_tests.gd` — the suite; each `_test_*` function covers one area.
- `tests/test_runner.tscn` — a `Node` whose `_ready` runs the suite and quits.

Some tests are coroutines (`await`) because they instantiate scenes and need a
frame to settle; they are awaited from `_ready`.

## Coverage

| Area | Representative tests |
|------|----------------------|
| Domain state | timeline relationships/flags/quests, serialization round-trips |
| Dialogue | runner flow, routing, line objects, validation, conditions, integration |
| Characters | resources, rig layers/motion/expression/talk, silhouette + palette uniqueness |
| Relationships & quests | transitions, rewards-once, content validation, reactions |
| Persistence | schema validation, atomic write, backup recovery, migration, clear |
| Restart | isolation, archive, request/cancel/confirm, meta survival |
| Traps | state machine, effects, re-entry, clue/exit parts, picnic + hollow scenes |
| Magic | library, validation reasons, spends, context selection, trap integration |
| Meta-narrative | stages, director anomalies |
| Ending | conditions, epilogue, completion recording, scene |
| Content expansion | Fern arc, secret, journal, alternate-timeline dialogue |
| Polish (Phase 12) | settings persistence, audio catalog, controller bindings, reduce-motion transitions, settings menu, dialogue typewriter |
| Variation & 3D (Phase 13) | per-timeline theme determinism + flags, 3D world/actor construction, 2D fallback toggle |

## Manual verification (headless)

Each scene is also loaded on its own to catch `_ready`-time errors:

```
godot --headless --path . res://scenes/boot/boot.tscn --quit-after 100
godot --headless --path . res://scenes/menus/main_menu.tscn --quit-after 100
godot --headless --path . res://scenes/world/village.tscn --quit-after 100
godot --headless --path . res://scenes/world/workshop.tscn --quit-after 100
godot --headless --path . res://scenes/world/hollow.tscn --quit-after 100
godot --headless --path . res://scenes/puzzles/endless_picnic.tscn --quit-after 100
godot --headless --path . res://scenes/endings/timeline_ending.tscn --quit-after 100
godot --headless --path . res://scenes/menus/settings_menu.tscn --quit-after 100
```

## Limitations

- Headless runs cannot verify rendered pixels or audio output; they verify
  scene instantiation, state transitions, and lack of script/runtime errors.
- `--headless` uses a dummy audio device; synthesis is exercised but not heard.
- The export build cannot be produced without the platform export templates
  (see `docs/RELEASE.md`).
