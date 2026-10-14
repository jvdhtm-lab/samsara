# Samsara — Character Bible

Design baseline for the main cast. These are original robot-creature designs.
Every character must be identifiable by silhouette, face, accessory, and
animation — never by a name label or colour alone (`AGENTS.md` §6).

Each character is defined by a `CharacterData` resource; this document and the
resource must stay in sync.

---

## Lumi — The Hopeful One

- **Role:** The player's first companion; introduces the world.
- **Silhouette:** Small, round lavender body with two long drooping ears.
- **Face:** Large amber eyes with strong highlights; tiny mouth.
- **Accessory:** Drooping ear-antennae.
- **Marking:** A small star on the chest.
- **Motion:** `idle`; eager, gentle bob.
- **Personality:** Kind, optimistic, quietly perceptive.
- **Dialogue voice:** Warm and wondering; notices when the world repeats.
- **Recognition checklist:** lavender · drooping ears · star-marked · amber eyes.
- **Resource:** `resources/characters/lumi.tres`

## Pip — The Curious One

- **Role:** Builder and problem-solver; helps the player understand loops.
- **Silhouette:** Mint-green pear body (wide top, narrow base) with a pointed
  leaf antenna.
- **Face:** Oversized dark-teal eyes; small mouth.
- **Accessory:** A leaf on a stem.
- **Marking:** A leaf badge.
- **Motion:** `idle`; fidgety, energetic.
- **Personality:** Shy, inventive, anxious, deeply loyal.
- **Dialogue voice:** Fast and bright; half-finished theories.
- **Recognition checklist:** mint · pear shape · leaf antenna · oversized eyes.
- **Resource:** `resources/characters/pip.tres`

## Momo — The Unsettling One

- **Role:** Social heart of the village; emotional counterpoint to the dark.
- **Silhouette:** Peach, wide plush body with short side nubs.
- **Face:** Warm brown half-lidded eyes; an uneven, slightly wrong smile.
- **Accessory:** Plush nubs.
- **Marking:** A sewn button.
- **Motion:** `uncanny_idle` — slower, smoother, unnervingly calm; does not blink.
- **Personality:** Affectionate and playful, occasionally determined to remain
  cheerful.
- **Dialogue voice:** Cheerful, doting, with a pause before easy answers.
- **Recognition checklist:** peach · plush width · button · uneven smile ·
  unblinking idle.
- **Resource:** `resources/characters/momo.tres`

## Fern — The Quiet Warden

- **Role:** Keeper of the Hollow beneath the village; guides the returning-tree
  storyline.
- **Silhouette:** Small amber plush body with a single plain antenna.
- **Face:** Oversized moss-green eyes; an even, level mouth.
- **Accessory:** A simple antenna.
- **Marking:** None.
- **Motion:** `idle`; slow, grounded, barely moving.
- **Personality:** Patient and watchful, more at home with roots than people.
- **Dialogue voice:** Slow and careful; every word placed like a stone.
- **Recognition checklist:** amber · plush shape · plain antenna · moss eyes ·
  unusually still.
- **Resource:** `resources/characters/fern.tres`

## The Wanderer (Player)

- **Role:** The player; newly awake, not yet sure why.
- **Silhouette:** Round cyan body with a single glowing antenna.
- **Face:** Slate eyes; neutral.
- **Marking:** None.
- **Motion:** `idle` / `walk`, faces movement direction.
- **Resource:** `resources/characters/player.tres`

---

## Identity contract

For any new character, define and verify:

1. A silhouette class + accessory that is visibly different from the cast.
2. A palette whose hue is at least 0.05 apart from every existing character.
3. A face (eye shape + mouth) and a chest marking.
4. An idle motion (`idle` or `uncanny_idle`).
5. A distinct dialogue voice and a JSON definition under `data/dialogue/`.

Automated checks live in `tests/run_tests.gd`
(`_test_silhouette_uniqueness`, `_test_character_animation_content`).
