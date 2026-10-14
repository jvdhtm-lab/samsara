# Samsara — Traps & Loops

A trap is a repeating situation the player must understand and resolve rather
than abandon. The first trap is **The Endless Picnic**.

## State machine

`TrapMachine` (systems, static) drives a four-state machine:

```
dormant ──enter()──▶ active ──discover()──▶ discovered ──resolve()──▶ resolved
```

- `dormant` — not yet encountered.
- `active` — the loop is running (`advance()` counts iterations).
- `discovered` — the player understands the rule.
- `resolved` — escaped; **a resolved trap never re-activates**.

State is stored in `TimelineState.traps` as
`{ "state": String, "iterations": int, "resolution": String }`, so it resets
with the timeline and persists in saves (see `docs/SAVE_FORMAT.md`).

`TrapMachine` emits `trap_triggered`, `trap_loop_iteration`,
`trap_discovered`, and `trap_resolved` on `EventBus`.

`TrapBase` (scene root, extends `AreaController`) wraps the machine and adds
overridable `_on_enter` / `_on_discover` / `_on_resolve` hooks. Scenes subclass
it (e.g. `EndlessPicnic`, `ReturningTree`).

## Reusable trap parts

Traps are assembled from shared, data-configured interactables rather than
per-trap scripts:

- **`TrapClue`** — an examinable object that reveals a trap's rule. The first
  look sets a `notice_flag`; the second discovers the trap, sets the
  `rule_flag`, and records the `anomaly_id`.
- **`TrapExit`** — a physical escape, gated by `required_flag`; resolving with
  the configured `resolution` (and optional `set_flag`).
- **`LoopToken`** — a recurring object that drives a *manual* loop: each
  interaction calls `advance()` and narrates escalating lines by iteration.

## Driving traps from content

Add a `trap` effect to a dialogue choice, node, or prop:

```json
{ "type": "trap", "trap": "endless_picnic", "action": "discover" }
{ "type": "trap", "trap": "endless_picnic", "action": "resolve", "resolution": "refused" }
```

Actions: `enter`, `advance`, `discover`, `resolve`. Applied by the application
layer (`Game._apply_trap_effect`).

Conditions available to dialogue:

- `{ "type": "trap_iteration", "trap": "endless_picnic", "min": 3 }`
- `{ "type": "trap_state", "trap": "endless_picnic", "equals": "discovered" }`

This lets one definition escalate across iterations without code.

## The Endless Picnic

- Entered from the village (the garden door).
- Each completed conversation calls `advance()`: the garden gains a place
  setting, the palette cools, and Momo's lines escalate (routes on
  `trap_iteration`).
- **Environmental inconsistencies:** an extra plate setting per loop; colour
  shift; repeated tea/clue lines.
- **Character reactions:** Momo moves `happy → uncanny → afraid → sad` through
  the loop via per-line expressions.

### Discovery (two paths)

1. Let the loop run to iteration 3, choose "Something is wrong." — the `realize`
   node discovers the rule and sets `picnic_rule_known`.
2. Examine the tea set twice (`TrapClue`): the first look sets `picnic_noticed`,
   the second discovers the rule.

### Escape (two distinct approaches)

1. **Leave** — the `GardenEdge` (`TrapExit`) becomes interactable once
   `picnic_rule_known` is set; interacting resolves with `walked_away`.
2. **Refuse** — the `discovered` dialogue node offers "This isn't real. I won't
   play along.", resolving with `refused`.

Either resolution records the choice (`get_trap_resolution`), sets a
consequence flag (`picnic_walked_away` / `picnic_refused`), records a meta
anomaly, and nudges the relationship with Momo. The controller then returns the
player to the village.

## The Returning Tree

The second trap, in the **Hollow** beneath the village (reached through the
cellar door once the `cellar_key` secret is found).

- A single `LoopToken` — the fallen leaf — drives the loop **manually**: each
  interaction calls `advance()`, the tree narrates escalating lines
  (`lines_early` → `lines_mid` → `lines_late`), and the hollow darkens
  (`ReturningTree` → `HollowBackground.set_iteration`).
- **Environmental inconsistencies:** the leaf returns to exactly where it fell;
  roots tighten; motes dim; a rising tone per iteration.
- **Character reaction:** Fern (`fern_intro`) reacts to understanding with a
  different, quieter conversation.

### Discovery (two paths)

1. Examine the `TreeRoots` (`TrapClue`) twice — the second look discovers the
   rule and sets `returning_tree_rule_known`.
2. Talk to Fern after understanding; her lines confirm the rule.

### Escape (three distinct approaches)

1. **Leave** — `RootsEdge` (`TrapExit`) resolves with `left_it`.
2. **Let it stay** — Fern's `let_stay` dialogue choice resolves with `gave_back`.
3. **Remember** — the `memory_echo` ability resolves with `remembered`.

Every resolution completes the `resolve_tree` objective via
`ReturningTree._on_resolve`, which closes Fern's quest `fern_hollow`.

## Re-entry rules

- A `resolved` trap does not restart its loop on re-entry and cannot be
  re-activated (`TrapMachine.enter` returns false).
- `iterations` and `resolution` persist, so re-entering is harmless and the
  world remembers how the player escaped.

## Feedback

- **Visual:** per-iteration garden changes, a warm/desaturated wash, and
  escalating portrait expressions.
- **Audio:** `AudioManager.play_tone` — a rising tick per iteration and a chime
  on escape.

## Regression coverage

`tests/run_tests.gd`: `_test_trap_machine`, `_test_timeline_traps`,
`_test_trap_effects` (including repeated entry after resolve),
`_test_picnic_content` (both escapes present + validated),
`_test_picnic_scene` (scene instantiates), `_test_trap_clue_and_exit`
(reusable clue + exit behaviour), `_test_hollow_scene`, and
`_test_memory_echo_ability` (magic resolves the returning tree).
