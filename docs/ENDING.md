# Samsara — Timeline Ending

Finishing the story without restarting is the game's central objective. The
ending is gated on meaningful progress and pays off the player's relationships
and choices.

## Completion conditions

`TimelineEnding` (systems, static) defines three requirements:

| id | Requirement |
|----|-------------|
| `quests` | Pip's device, Lumi's story, and Momo's picnic all completed |
| `picnic` | The endless picnic trap resolved (any resolution) |
| `confront` | Narrative stage ≥ 4 (Confrontation) |

`is_ready(timeline, meta)` is true when all are met; `unmet_labels` lists what
remains (used for the lantern's hint dialogue). Completing the three quests
(+6) and resolving the picnic (+3) already reaches stage 4, so the `confront`
condition reflects real progress rather than an extra grind.

## The lantern

`EndingTrigger` (presentation) is a lantern in the village plaza:

- Before the timeline is ready, touching it opens a short "not yet" dialogue
  listing the unmet requirements.
- Once ready, touching it calls `Game.begin_ending()`.

This is the deliberate alternative to the restart temptation: the player
*completes* the timeline instead of erasing it.

## Recording completion

`Game.record_timeline_completion(resolution)` (no navigation, so it is testable)
updates persistent meta-progression:

- `completed_timelines += 1`
- records discoveries `completed_timeline` and `ending_<resolution>`
- sets `meta.last_outcome = "completed"`
- emits `timeline_completed(timeline_id)`

`Game.begin_ending()` records the completion and then routes to the ending
scene.

## Ending sequence

`EndingSequence` (`scenes/endings/timeline_ending.tscn`) assembles the epilogue
from live state via `TimelineEnding.epilogue_lines(timeline, meta)`:

- Opens on "You stayed." — the core choice.
- One line per character, varying on quest completion and relationship level
  (a confidant gets a warmer line than a friend).
- A line reflecting the picnic resolution (`frozen`, `walked_away`, `refused`).
- Acknowledges prior completions, then closes: "A timeline finished. Not
  erased." / "The End."

Lines advance with the interact key; afterwards the player chooses **Return to
the Menu** or **Begin Another Timeline**.

## Post-ending

- The completed timeline is recorded in meta-progression; the save may be
  archived by the same mechanism as restart (`SaveManager.archive_current`).
- **Begin Another Timeline** calls `Game.start_new_timeline()`, which resets the
  timeline (verified isolation) while keeping meta-progression and settings.
- Returning to the menu shows **Continue** if a readable save exists.

## Coverage

`tests/run_tests.gd`: `_test_timeline_ending_conditions`,
`_test_epilogue_lines`, `_test_record_completion`, `_test_ending_valid_path`
(a full playthrough reaches the ending), and `_test_ending_scene` (the scene
instantiates and assembles lines).
