# Samsara — Magic

Magic gives the player an alternative to restarting. Abilities are authored
data; use is validated by a pure system and applied by the application layer.

## Resource

The magic resource is **Focus**, stored per-timeline in
`TimelineState.magic_focus` (`0..MAGIC_FOCUS_MAX`, starting at
`MAGIC_FOCUS_START = 1`). It resets with the timeline and persists in saves.
Grant or spend it with the `focus` effect:

```json
{ "type": "focus", "delta": 1 }
{ "type": "focus", "delta": -1 }
```

Focus is spent only on a successful use (`MagicManager.use`).

## Abilities

Authored in `data/abilities/<id>.json` and loaded by `MagicLibrary`:

```json
{
  "id": "temporal_pause",
  "name": "Temporal Pause",
  "description": "Freeze a repeating moment long enough to step out of it.",
  "cost": 1,
  "requires_trap": true,
  "requires_discovered_trap": true,
  "effects": [
    { "type": "trap", "trap": "@active", "action": "resolve", "resolution": "frozen" },
    { "type": "flag", "flag": "picnic_frozen", "value": true },
    { "type": "meta", "record_anomaly": "temporal_pause_used" }
  ]
}
```

`@active` is a target placeholder resolved to the scene's active trap.

### Acquisition

Abilities are unlocked through narrative progression:
`MetaProgression.unlocked_abilities`. Completing **Pip's device quest** grants
`temporal_pause` via a quest reward:
`{ "type": "meta", "unlock_ability": "temporal_pause" }`. Unlocks persist across
restarts and are mirrored into timeline flags (`ability_<id>`) so dialogue
conditions can reference them generically.

## Validation & use

`MagicManager` (systems, static) is pure:

- `can_use(timeline, meta, ability_id, active_trap)` returns `""` when usable,
  else a reason code: `unknown`, `locked`, `no_focus`, `no_target`,
  `undiscovered`.
- `use(...)` validates, spends focus, and returns the reason (or `""`).

Contextual limitations for `temporal_pause`: it needs an **active, unresolved
trap** and that the player has **discovered** the trap's rule. This keeps magic
as a reward for understanding, not a bypass.

`Game.use_magic(ability_id)` resolves `@active`, applies the ability's effects
through `Game.apply_effects`, and emits `magic_used` / `focus_changed` (or
`magic_failed` with a reason). Traps register themselves as the active trap on
enter and clear it on exit (`TrapBase` ↔ `Game.active_trap`).

## Player-facing use

- Input: **Q** uses the first unlocked ability (`Game.first_ability`).
- HUD: a bottom-left `[Q] Focus ◆◇◇` readout, plus toasts on success/failure
  with human-readable reasons.
- Visual/audio: `MetaUI` flashes a cool overlay on use; `AudioManager` plays a
  rising shimmer on success and a low thud on failure.

## The third picnic escape

Beyond walking away and refusing Momo, a player who has helped Pip can **freeze
the moment** — either with the Q key while in the garden (after discovering the
rule) or via a dialogue choice gated on `ability_temporal_pause` + focus. This
resolves the trap with `frozen`, changes Momo's relationship, and records a meta
anomaly.

## Invalid states

`_test_magic_manager` and `_test_magic_trap_integration` cover: locked ability,
no target, undiscovered trap, insufficient focus, unknown ability, and
successful use (focus spent, trap resolved, effects applied). A resolved trap
reports `no_target`, so focus is never wasted.

## Adding an ability

1. Add `data/abilities/<id>.json` with a cost and effects.
2. Grant it from a quest reward or dialogue effect (`unlock_ability`).
3. If it needs a target, set `requires_trap` / `requires_discovered_trap` and
   use `@active`.
