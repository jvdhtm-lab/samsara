# Samsara — Save Format

Versioned, validated, atomic. Never depends on deleting the player's only save.

## Location

| File | Purpose |
|------|---------|
| `user://saves/timeline.json` | Active slot |
| `user://saves/timeline.backup.json` | Previous valid slot (auto) |
| `user://saves/timeline.tmp.json` | In-progress write (transient) |
| `user://settings.json` | Standalone application settings |

Paths are injectable in `SaveManager.save_game/load_game/clear_slot` so tests
and future slots can operate without touching the real save.

## Standalone settings file

Application settings (volume, accessibility, display, text speed) are also
written to their own file via `SaveManager.save_settings/load_settings`, so
preferences persist even when there is no active timeline. It is loaded at
startup and never depends on a save slot (ADR-028). Shape:

```json
{ "version": 2, "settings": { ... } }
```

## Top-level shape (version 2)

```json
{
  "version": 2,
  "saved_at": "2026-10-14T12:00:00",
  "timeline": { ... },
  "meta": { ... },
  "settings": { ... }
}
```

The three payloads correspond to the three state categories
(`docs/ARCHITECTURE.md`): timeline state resets on restart, meta-progression
survives, settings are never touched by narrative.

### timeline

```json
{
  "timeline_id": "tl_1760000000_12345",
  "current_location": "village",
  "characters": {
    "lumi": { "attributes": { "trust": 2, "affection": 0, "suspicion": 0 }, "flags": {}, "met": true }
  },
  "story_flags": { "heard_humming": true },
  "quests": {
    "pip_device": { "status": "active", "objectives": { "talk_pip": true } }
  },
  "visited_locations": { "village": true }
}
```

### meta

```json
{
  "restart_count": 1,
  "completed_timelines": 0,
  "unlocked_abilities": ["temporal_pause"],
  "anomalies_seen": ["momo_time_question"],
  "discoveries": ["lumi_trust"],
  "last_outcome": "clean"
}
```

### settings

```json
{
  "master_volume": 0.8, "music_volume": 0.7, "sfx_volume": 0.8,
  "reduce_motion": false, "high_contrast_text": false, "fullscreen": false,
  "text_speed": 42.0, "use_3d_visuals": true
}
```

## Write protocol (atomic)

`SaveStorage.write_atomic`:

1. Ensure the directory exists.
2. Write the new payload to the temp file.
3. If a slot exists, copy it to the backup (overwriting the old backup).
4. Rename temp → slot (falling back to copy + delete temp).
5. On any failure, the existing slot/backup are left intact.

## Read protocol (validated + recoverable)

`SaveManager.load_game`:

1. `SaveStorage.read_first_valid([slot, backup])` — each candidate is parsed and
   must pass `SaveSchema.validate`.
2. `MigrationManager.migrate` upgrades older versions.
3. `Game.apply_loaded_state` rebuilds the three models.

Malformed data is skipped, never deleted. A corrupt slot falls back to the
backup.

## Versioning & migration

- `SaveSchema.CURRENT_VERSION = 2`, `MIN_SUPPORTED_VERSION = 1`.
- `MigrationManager` upgrades step by step (`v1 → v2` renames
  `timeline.relationships` → `timeline.characters` and
  `timeline.quest_state` → `timeline.quests`).
- `TimelineState.from_dict` also accepts the legacy shapes directly, so a
  hand-written v1 payload still loads.
- Payloads newer than `CURRENT_VERSION` are rejected.

## Restart isolation

`TimelineInitializer.build()` creates a fresh timeline and
`verify_isolation(previous_id, fresh)` reports any leaked character, quest,
flag, or location state (and a non-regenerated id). `Game.begin_new_timeline`
runs this check, records the outcome in `meta.last_outcome`, and leaves
meta-progression and settings untouched.
