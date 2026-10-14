# Samsara — Narrative Bible

How conversations are authored, validated, and delivered. Pairs with
`docs/CHARACTER_BIBLE.md` (who speaks) and `docs/ART_BIBLE.md` (how they look).

## Where dialogue lives

- Authored NPC dialogue: `data/dialogue/<dialogue_id>.json`, loaded by
  `DialogueLibrary` and cached.
- In-memory text (signs, props, doors): built by `TextInteractable` and routed
  through `Game.request_raw_dialogue`.
- One UI (`DialogueUI`) presents both; one runner (`DialogueRunner`) drives both.

## Definition schema

```json
{
  "id": "lumi_intro",
  "speaker": "lumi",
  "speaker_name": "Lumi",
  "start": "start",
  "nodes": {
    "start": {
      "routes": [
        { "condition": { "type": "flag", "flag": "lumi_trusted", "equals": true }, "next": "return_trust" },
        { "next": "first_meeting" }
      ]
    },
    "first_meeting": {
      "lines": [
        { "text": "Oh! Your lights are on again.", "expression": "happy" },
        "The sky has been humming all morning."
      ],
      "choices": [
        {
          "text": "I hear it too. Are you alright?",
          "next": "reassure",
          "effects": [
            { "type": "relationship", "character": "lumi", "attr": "trust", "delta": 1 },
            { "type": "flag", "flag": "heard_humming", "value": true }
          ]
        }
      ]
    }
  }
}
```

### Node kinds

| Field | Meaning |
|-------|---------|
| `lines` | Sequence of strings or `{ "text", "expression" }` objects. |
| `choices` | Branch options shown after the last line. |
| `next` | Auto-continue to another node after the last line (no choices). |
| `routes` | Conditional auto-branch. First matching route wins; the node shows nothing itself. |
| `effects` | Applied once when the node is entered. |

A node with `routes` and no `lines`/`choices` is a **routing node** (used to
branch on state). `DialogueRunner.resolve` follows these until content or a
terminal node is reached.

### Conditions

`DialogueConditions` supports:

- `{ "type": "flag", "flag": "x", "equals": true }`
- `{ "type": "relationship", "character": "lumi", "attr": "trust", "min": 2 }`
- `{ "type": "objective", "quest": "pip_device", "objective": "talk_pip", "done": true }`
- `{ "type": "quest_status", "quest": "pip_device", "equals": "active" }`
- `{ "type": "trap_iteration", "trap": "endless_picnic", "min": 3 }`
- `{ "type": "trap_state", "trap": "endless_picnic", "equals": "discovered" }`
- `{ "type": "focus", "min": 1 }`
- `{ "type": "ability", "ability": "temporal_pause" }`
- `{ "type": "all", "conditions": [ ... ] }` / `{ "type": "any", "conditions": [ ... ] }`

Choices may use `condition` (one) or `conditions` (array, treated as `all`).
Routing entries use `condition`.

### Effects

| Type | Fields | Applies to |
|------|--------|-----------|
| `relationship` | `character`, `attr` (trust/affection/suspicion), `delta` | Timeline state |
| `flag` | `flag`, `value` | Timeline state |
| `quest` | `quest`, `state` | Timeline state |
| `meta` | `unlock_ability` / `record_anomaly` / `record_discovery` | Meta-progression (survives restarts) |
| `trap` | `trap`, `action` (enter/advance/discover/resolve), `resolution`, `objective` | Timeline trap state |
| `focus` | `delta` | Timeline magic focus (clamped 0–3) |

Effects are applied by the **application layer** (`Game.apply_effects`); the UI
never writes state.

## Validation

`DialogueValidator.validate(definition, known_character_ids)` returns a list of
errors: missing start, unknown speaker, dangling `next`/choice/route targets,
empty nodes/lines/choices, malformed effects, unknown effect types, and
relationship effects naming unknown characters.

The test suite validates every authored file
(`_test_dialogue_validation`). Run it before shipping new content.

## Voice guidelines

- **Lumi:** warm, wondering; notices repetition before anyone else.
- **Pip:** fast, bright, anxious; half-finished theories.
- **Momo:** sweet and doting; a pause before easy answers; occasionally wrong.
- **Signs/props:** terse, observational; the world's oddities stated plainly.

Keep the uncanny in the subtext: contradictions and repetitions rather than
explicit menace.

## Meta-narrative stages (from `AGENTS.md` §17)

0 Comfort → 1 Oddity → 2 Suspicion → 3 Pressure → 4 Confrontation →
5 Resolution. Dialogue and anomalies should advance these deliberately, not on
a raw timer. The opening conversations plant Stage 1 seeds: a humming sky, a
stuck minute, and Momo's too-long memory of the player.

## Adding a conversation

1. Create `data/dialogue/<id>.json` with a known `speaker` id.
2. Reference it from the character's `CharacterData.dialogue_id`.
3. Use `routes` for state-dependent openings and `effects` for consequences.
4. Run the validator (via the test suite) and fix any reported errors.
5. Add or extend a representative-path test if the branch is significant.

## Quests

Quests are authored in `data/quests/<id>.json` and loaded by `QuestLibrary`.
Runtime state lives in `TimelineState.quests` (`status` + per-objective flags);
`QuestManager` owns the transitions and emits `quest_started`,
`quest_objective_completed`, `quest_completed`, and `quest_failed`.

```json
{
  "id": "pip_device",
  "title": "The Stubborn Minute",
  "giver": "pip",
  "summary": "…",
  "objectives": [
    { "id": "talk_pip", "description": "Ask Pip about the device" },
    { "id": "examine_device", "description": "Examine the device" },
    { "id": "return_pip", "description": "Tell Pip what you found" }
  ],
  "rewards": [ { "type": "relationship", "character": "pip", "attr": "trust", "delta": 1 } ],
  "consequences": [ { "type": "flag", "flag": "pip_quest_done", "value": true } ]
}
```

Quest effects in dialogue (and on `TextInteractable` props) use an `action`:

| Action | Fields | Effect |
|--------|--------|--------|
| `start` | — | Activates the quest |
| `objective` | `objective` | Marks an objective; completes the quest when all are done |
| `complete` / `fail` | — | Forces the terminal status |

Rewards and consequences are applied by the **application layer** (`Game`),
exactly once, when the quest transitions to `completed`. Objectives are also
completable from world props via `TextInteractable.quest_id` /
`objective_id`.

### Current quest chains

- **Pip — The Stubborn Minute:** ask Pip → examine the device (workshop) → report back.
- **Lumi — The Humming Sky:** listen with Lumi → read the plaque (strange tree) → tell Lumi.
- **Momo — A Seat Kept Warm:** accept the invite → pick a flower (garden) → share the picnic.
- **Fern — What the Roots Remember:** meet Fern (Hollow) → understand the returning
  tree → settle it (leave, let it stay, or use Memory Echo).

Each completion changes the character's relationship and sets a flag that
routes their next conversation to a warmer, informed reply.

### Alternate-timeline variations

`Game` mirrors cross-timeline meta-progress into two timeline flags —
`meta_restarted` and `meta_completed_before` — so authored dialogue can branch
on prior timelines using the ordinary `flag` condition (see `fern_intro`'s
`first_again` / `let_stay_remembered` nodes).

Each timeline also gets a deterministic **theme** (`variation_theme` ∈
`clear|dawn|dusk|storm|gloom`) applied by `Game` from `TimelineVariation`, plus
a convenience flag per theme (`variant_clear`, `variant_dawn`, …). Dialogue can
branch on either, and `data/events/anomalies.json` entries may carry a
`variant` field so the director only fires them on matching timelines.

