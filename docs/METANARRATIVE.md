# Samsara — Meta-Narrative & Restart

The meta-narrative observes progress and escalates the world toward the
temptation to restart. Restarting is a deliberate, cancellable, safe decision.

## Progression model

`MetaNarrative` (systems, static) derives a single **stage** (0–5) from a
`pressure` scalar — a defined model, not a timer or random escalation:

| Contribution | Pressure |
|--------------|----------|
| Each completed quest | +2 |
| Picnic trap discovered | +1 |
| Picnic trap resolved | +3 |
| Recorded anomalies (capped) | +1 each, max 4 |
| Prior restarts (capped) | +1 each, max 3 |

| Stage | Name | Threshold |
|-------|------|-----------|
| 0 | Comfort | 0 |
| 1 | Oddity | ≥1 |
| 2 | Suspicion | ≥2 |
| 3 | Pressure | ≥4 |
| 4 | Confrontation | ≥7 |
| 5 | Resolution | ≥10 |

`MetaNarrative.stage_name`, `restart_warning` (escalating confirmation text),
and `stage_anomalies` are pure helpers.

## Anomaly director

`NarrativeDirector` (systems, owned by `Game`) listens for
`quest_completed`, `trap_discovered`, `trap_resolved`, and `timeline_started`.
When the stage changes it applies that stage's anomalies (from
`data/events/anomalies.json`) through the application layer and announces them:

- Sets the anomaly's `flag` via `Game.apply_effects`.
- Records the anomaly in `MetaProgression.anomalies_seen`.
- Emits `anomaly_triggered(id, message)` and `meta_stage_changed(stage, prev)`.

Anomalies are authored, not procedural:

```json
{ "id": "restart_whisper", "flag": "restart_offered", "message": "It would be easy to begin again." }
```

## Escalating UI

`MetaUI` (presentation, owned by `Game`) renders a full-screen tint whose
intensity scales with the stage and pulses gently, plus fading "whisper"
messages when anomalies trigger. Characters also react: `NpcController` shows
an uncanny expression while `world_unstable` is set.

## Restart transaction

`RestartController` (application, owned by `Game`) is both the state machine and
the confirmation UI.

```
AVAILABLE ──open()──▶ CONFIRMATION ──confirm()──▶ RESTARTING ──▶ NEW_TIMELINE
     ▲                     │
     └──── cancel() ───────┘
```

- `open()` shows the confirmation (warning text scales with the stage; a summary
  of characters met, quests completed, and the picnic resolution), and pauses
  the game.
- `cancel()` returns to `AVAILABLE` with no changes.
- `confirm(navigate, paths...)`:
  1. `SaveManager.archive_current()` copies the active timeline to
     `user://saves/timeline.archived.json` (falling back to the backup).
  2. `Game.begin_new_timeline()` resets the timeline and verifies isolation.
  3. `SaveManager.save_game()` persists the new timeline (atomically, preserving
     the previous save as backup).
  4. Emits `restart_completed`, unpauses, and (in game) returns to the village.

The pause menu offers **Begin Again**, so the player can always choose to
restart — the meta-narrative only changes how it is framed.

## Safety

- The restart **never deletes** the only valid save: the old timeline is
  archived and the previous save is also kept as the backup.
- Only files under `user://saves/` are written (`timeline.json`,
  `.backup.json`, `.tmp.json`, `.archived.json`). No external files are
  touched.
- Meta-progression (`MetaProgression`) and application settings
  (`ApplicationSettings`) are preserved across restarts; only `TimelineState`
  is replaced.

## Coverage

`tests/run_tests.gd`: `_test_meta_narrative_stages`,
`_test_narrative_director`, `_test_restart_archive`, `_test_restart_flow`
(request → cancel → confirm, asserting timeline reset while meta and settings
survive), plus the Phase 6 isolation tests.
