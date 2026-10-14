# SAMSARA: ETERNAL RESTART

## Complete Game Development Blueprint

**Engine:** Godot 4.x  
**Language:** GDScript  
**Genre:** Cozy adventure, branching narrative, surreal psychological horror  
**Initial platform:** Desktop PC  
**Perspective:** 2D top-down, with occasional cinematic scenes  
**Architecture:** Modular, data-driven, single-player  
**Primary objective:** Complete a timeline without restarting the universe.

---

# PART I — PROJECT RULES

## 1. Instructions for All Coding Agents

You are building Samsara: Eternal Restart, a complete game whose central conflict is the temptation to erase a universe that the player has learned to love.

Read this entire document before implementing features.

Also read and follow [`ARCHITECTURE.md`](./ARCHITECTURE.md), the binding architecture contract. Where this blueprint and the architecture contract overlap, treat the contract as the authority on boundaries, dependencies, state separation, persistence, and testing. Do not change shared architecture without documenting the intended change first.

### Mandatory rules

1. Use Godot 4.x and GDScript as the primary technology.
2. Preserve the existing project and inspect its contents before changing anything.
2a. Comply with the boundaries, dependency rules, and testing requirements defined in `ARCHITECTURE.md`.
3. Never generate the entire game in one pass.
4. Work in the defined phases, completing and verifying each phase before moving to the next.
5. Keep the project runnable throughout development.
6. Use typed GDScript where practical.
7. Separate gameplay rules, narrative data, persistence, presentation, and UI.
8. Do not put all game logic into one large script.
9. Avoid unnecessary plugins, external services, and backend infrastructure.
10. Never implement fake features that only look functional.
11. Every interactive object must have a defined behavior.
12. Every significant player choice must have an explicit consequence.
13. Every new system must include appropriate tests.
14. Use placeholder assets only when necessary, and track them for replacement.
15. Do not overwrite working systems without understanding their dependencies.
16. Do not silently change the approved design.
17. Document important architectural decisions.
18. Run the actual Godot project and inspect runtime behavior after major changes.

### Definition of done

A feature is complete only when it:

- Implements its specified behavior.
- Works in the running game.
- Integrates with existing systems.
- Handles relevant edge cases.
- Has appropriate automated tests.
- Has been reviewed for regressions.
- Has updated documentation.
- Has no unresolved placeholder behavior disguised as a finished feature.

A successful code generation response is not evidence that a feature works.

---

# PART II — GAME DESIGN

## 2. Core Premise

The player awakens in a whimsical world inhabited by strange, adorable creatures.

They explore the world, solve puzzles, develop relationships, and uncover the lives of its inhabitants.

At first, everything feels safe.

Then the world begins repeating itself.

Characters remember things they should not remember. Familiar locations change. A cheerful character asks the player to do something disturbing. The interface begins presenting contradictory information.

Eventually, the player discovers that the game is actively encouraging them to restart.

Restarting offers relief, a fresh world, and new possibilities. It also destroys the active timeline and all the relationships the player has built there.

The objective is to finish the story while preserving the universe.

## 3. Core Design Pillars

### Emotional attachment

Characters must have recognizable identities, distinct personalities, individual motivations, and relationships that evolve.

The player should care about them before they encounter the game's darkest events.

### Meaningful agency

Choices must affect the world. There should be multiple ways to approach important problems, even when some solutions have costs.

### Surreal escalation

Begin with charming oddities. Gradually introduce repetition, contradictions, impossible spaces, and unsettling behavior.

### Resistance instead of reset

The player should be encouraged to investigate and solve problems rather than abandon the current timeline.

### Persistence and consequence

The active timeline is precious. Meta-progression can survive across timelines, but it must never make relationships feel disposable.

### Coherent endings

Completing a timeline must provide emotional and narrative closure.

---

# PART III — TECHNICAL FOUNDATION

## 4. Project Structure

Use the following directory structure, adapting it only when the existing project provides a compelling reason.

    project.godot

    scenes/
      boot/
        boot.tscn
      menus/
        main_menu.tscn
        settings_menu.tscn
        pause_menu.tscn
        restart_confirmation.tscn
      world/
        world.tscn
        world_transition.tscn
      characters/
        character_base.tscn
        player.tscn
        lumi.tscn
        pip.tscn
        momo.tscn
      dialogue/
        dialogue_box.tscn
        dialogue_choice.tscn
      interactions/
        interaction_prompt.tscn
      puzzles/
        endless_picnic.tscn
        returning_tree.tscn
      ui/
        hud.tscn
        journal.tscn
        inventory.tscn
        relationship_panel.tscn
      endings/
        timeline_ending.tscn

    scripts/
      core/
        game.gd
        game_state.gd
        event_bus.gd
        scene_router.gd
      player/
        player_controller.gd
        player_interaction.gd
      characters/
        character_controller.gd
        character_state.gd
        relationship_manager.gd
      dialogue/
        dialogue_manager.gd
        dialogue_condition.gd
      narrative/
        narrative_manager.gd
        quest_manager.gd
        timeline_director.gd
      world/
        world_controller.gd
        interactable.gd
        trigger_zone.gd
      traps/
        trap_base.gd
        loop_controller.gd
        endless_picnic.gd
        returning_tree.gd
      magic/
        magic_manager.gd
        magic_ability.gd
      persistence/
        save_manager.gd
        save_schema.gd
        migration_manager.gd
      meta/
        meta_narrative.gd
        restart_controller.gd
        anomaly_director.gd
      ui/
        dialogue_ui.gd
        hud_controller.gd
        restart_ui.gd
      audio/
        audio_manager.gd

    resources/
      characters/
      dialogue/
      quests/
      items/
      abilities/
      traps/
      worlds/
      timelines/
      events/

    assets/
      characters/
        concepts/
        sprites/
        portraits/
        expressions/
        animations/
      environments/
        tilesets/
        props/
        backgrounds/
      ui/
      audio/
        music/
        ambience/
        sfx/
      fonts/
      vfx/

    data/
      characters/
      dialogue/
      quests/
      worlds/
      traps/
      endings/

    tests/
      unit/
      integration/
      regression/
      fixtures/

    docs/
      GDD.md
      TDD.md
      ROADMAP.md
      CHARACTER_BIBLE.md
      ART_BIBLE.md
      NARRATIVE_BIBLE.md
      SAVE_FORMAT.md
      TESTING.md
      DECISIONS.md
      RISKS.md
      AGENT_STATUS.md

Keep authored content separate from game logic. Use Godot Resources for strongly structured data and JSON only where external editing, tooling, or import workflows justify it.

## 5. Architecture

Use a small number of persistent autoloads.

Recommended initial autoloads:

- `Game`: top-level game flow and active game session.
- `EventBus`: typed or consistently named global events.
- `SaveManager`: saving, loading, validation, and recovery.
- `AudioManager`: music, ambience, sound effects, and transitions.

Keep other managers scene-owned unless they genuinely need application-wide lifetime.

Do not turn every manager into an autoload.

### Dependency direction

UI sends requests to game systems.

Game systems validate requests and update authoritative state.

The UI responds to events and reflects the resulting state.

Narrative data defines dialogue, conditions, consequences, and triggers.

Persistence serializes explicit state rather than entire scene trees.

The meta-narrative observes game events and requests narrative effects. It does not directly mutate arbitrary gameplay state.

### Signals

Use signals for events such as:

- `character_interacted`
- `dialogue_started`
- `dialogue_finished`
- `relationship_changed`
- `quest_updated`
- `trap_triggered`
- `trap_resolved`
- `magic_used`
- `anomaly_triggered`
- `restart_requested`
- `timeline_completed`

Define signal ownership and payloads consistently.

Avoid global string-based event systems when a typed signal or direct interface is clearer.

---

# PART IV — CHARACTER IDENTITY

## 6. The Main Cast

These three characters are the initial design baseline. Preserve their identities and improve their implementation without making them interchangeable.

Every character must be recognizable by silhouette, face, accessories, animation, and personality, even when shown as a small sprite.

## Character A: Lumi — The Curious Dreamer

**Role:** The player's first close companion.

**Silhouette:** Small, round, slightly asymmetrical lavender body.

**Face:** Large dark eyes with strong highlights, tiny mouth, highly expressive eyebrows or upper-eye shapes.

**Signature accessory:** A mustard-yellow scarf with two visibly different ends.

**Movement:** Curious head tilts, little hops, excited turns, occasional pauses when something feels wrong.

**Personality:** Kind, optimistic, inquisitive, and unusually perceptive.

**Narrative role:** Lumi helps the player discover the world and its mysteries. As anomalies intensify, Lumi begins noticing contradictions in the timeline.

**Emotional arc:** Trust, curiosity, confusion, fear, and finally a meaningful independent choice.

**Recognition requirements:**
- Lavender body.
- Yellow scarf.
- Distinctive large eyes.
- Slightly uneven round silhouette.
- Signature head tilt.

## Character B: Pip — The Nervous Inventor

**Role:** Builder, problem-solver, and source of practical assistance.

**Silhouette:** Mint-green pear-shaped body with a larger head and narrower lower half.

**Face:** Alert eyes, small expressive mouth, visible nervous expressions.

**Signature accessories:** A brown cross-body tool satchel and a small sprout on the head.

**Movement:** Small cautious steps, fidgeting, looking toward suspicious objects, excited movements when explaining inventions.

**Personality:** Shy, inventive, anxious, and deeply loyal.

**Narrative role:** Pip constructs devices that help the player understand and manipulate environmental loops.

**Emotional arc:** Fear of failure, growing confidence, moral uncertainty, and a willingness to challenge the game's instructions.

**Recognition requirements:**
- Mint-green pear silhouette.
- Brown satchel.
- Green sprout.
- Fidgeting animation.
- Recognizable inventor posture.

## Character C: Momo — The Eternal Optimist

**Role:** Social heart of the village and emotional counterpoint to the darker narrative.

**Silhouette:** Peach-pink rounded body with short petal-like extensions.

**Face:** Warm eyes, wide smile, and unusually expressive cheeks.

**Signature accessory:** A small orange flower beside the head.

**Movement:** Cheerful bouncing, expressive gestures, enthusiastic turns, and a distinctive pause before answering difficult questions.

**Personality:** Affectionate, sociable, playful, and occasionally unsettlingly determined to remain cheerful.

**Narrative role:** Momo maintains the village's social traditions and introduces the player to its inhabitants.

**Emotional arc:** Joy, denial, confusion, vulnerability, and a difficult confrontation with the truth.

**Recognition requirements:**
- Peach-pink body.
- Orange flower.
- Distinctive cheek shapes.
- Bouncy idle animation.
- A recognizable smile that can become unnerving without changing the underlying design.

## 7. Character Asset Standard

Create a reusable character scene with separate visual and behavioral layers.

Suggested hierarchy:

    Character
      CharacterController
      CollisionShape2D
      VisualRoot
        Shadow
        BodySprite
        BackAccessories
        Face
          Eyes
          EyeHighlights
          Eyebrows
          Mouth
        FrontAccessories
        AnimationPlayer
        AnimationTree
      InteractionArea
      CharacterAudio

Adapt the hierarchy to the chosen art technique. Separate sprites are illustrative; layered 2D artwork or rigged cutout animation is equally acceptable.

Use shared base behavior but individual character data and presentation.

Create a consistent set of animations:

- Idle.
- Walk.
- Run or hurry.
- Talk.
- Listen.
- Happy.
- Sad.
- Angry or frustrated.
- Afraid.
- Surprised.
- Uncanny idle.
- Loop reaction.
- Restart plea.
- Timeline ending.

Do not create all animations as separate hand-authored assets immediately. Begin with idle, walk, talk, happy, afraid, and uncanny idle. Expand only when the relevant gameplay needs them.

## 8. Character Art Pipeline

Before producing the full cast:

1. Define the art style and reference palette.
2. Produce a front-facing concept sheet for each main character.
3. Create a silhouette comparison sheet.
4. Produce expression sheets.
5. Create a small set of movement animations.
6. Import the assets into Godot.
7. Verify sprite scale, outlines, readability, and animation timing.
8. Test recognition at normal gameplay camera distance.
9. Approve the visual direction.
10. Expand the asset pipeline.

If image-generation tools are used, generate character concepts and sprite assets as separate tasks. Do not rely on a single illustrated image containing several characters as the final game asset.

Character identity takes priority over sheer asset quantity.

---

# PART V — GAMEPLAY SYSTEMS

## 9. Player Controller

Implement:

- Eight-directional movement.
- Collision with the environment.
- Consistent movement speed.
- Interaction input.
- Optional running or movement modifiers.
- Clear movement animations.
- Responsive input handling.
- Input remapping.
- Pause behavior.

Use a `CharacterBody2D` for a conventional collision-based top-down controller.

Movement should feel responsive and predictable.

Do not introduce combat unless it serves the approved game design.

## 10. Interaction System

Create a reusable interaction interface for characters, doors, objects, signs, quest items, puzzles, and environmental anomalies.

Every interactable should support:

- Availability conditions.
- Interaction range.
- A contextual prompt.
- An interaction action.
- Optional dialogue or state changes.
- Feedback when unavailable.
- Relevant narrative events.

Prefer an explicit interface or base class over repeated bespoke input handling.

The player must be able to determine what can be interacted with.

## 11. Dialogue System

Support:

- Character portraits or in-world expressions.
- Speaker names.
- Dialogue text.
- Player choices.
- Conditional branches.
- Relationship requirements.
- Quest conditions.
- Consequences.
- Event triggers.
- Character-specific responses.
- Timeline-specific variations.

Example content structure:

    dialogue_id: lumi_village_intro
    speaker_id: lumi
    lines:
      - text: "You're finally awake!"
      - text: "I thought the clouds were going to swallow the village."
    choices:
      - text: "What happened?"
        next: lumi_explains_clouds
      - text: "Are we friends?"
        next: lumi_friendship
    conditions: []
    consequences: []

The actual implementation should use a validated data schema rather than hard-coded dialogue strings scattered throughout scripts.

Dialogue must be skippable or advanceable according to consistent input rules.

## 12. Relationship System

Represent relationships using a combination of explicit flags and a few meaningful attributes.

Possible attributes:

- Trust.
- Affection.
- Confidence.
- Suspicion.

Do not use every attribute for every character.

Relationship changes must arise from meaningful actions.

Examples:

- Helping Pip repair an invention increases trust.
- Repeatedly ignoring Lumi's warnings changes later dialogue.
- Supporting Momo through an unsettling event unlocks a new conversation.
- Choosing a morally questionable shortcut changes a character's opinion.

Relationship state must influence available dialogue and relevant story events.

Do not reduce the narrative to a single affection score.

## 13. Quest System

Each quest should define:

- Unique ID.
- Starting conditions.
- Objectives.
- Required interactions.
- Completion conditions.
- Failure or alternative outcomes.
- Rewards.
- Narrative consequences.

Support multi-step quests and conditional objectives.

The quest system must be able to represent unusual objectives, including repeated actions, changing environmental conditions, and moral decisions.

## 14. Inventory and Magic

Start with a small inventory.

Each item needs a clear purpose, presentation, and interaction behavior.

Magic abilities are acquired through narrative progression and experimentation.

Initial candidate abilities:

**Temporal Pause:** Briefly freezes a local repeating event.

**Memory Echo:** Reveals fragments of an earlier event or an object's history.

**Reality Thread:** Connects separated objects or restores a broken environmental relationship.

**Loop Break:** Allows the player to interrupt a trap after discovering its underlying rule.

These are candidates. Implement only the abilities required by the first playable narrative.

Magic should consume a defined resource or require a contextual condition where appropriate.

Do not build a large skill tree before the first trap is complete.

---

# PART VI — TIMELINES AND META-NARRATIVE

## 15. State Model

Keep three distinct categories of state.

### Timeline state

Reset when a new timeline begins:

- Character states.
- Relationships.
- Quest progress.
- Environmental changes.
- Local inventory.
- Timeline-specific discoveries.
- Trap states.
- Current ending eligibility.

### Meta-progression

May persist across timelines:

- Unlocked magical knowledge.
- Achievements.
- Previously encountered anomalies.
- Selected journal discoveries.
- Explicitly persistent unlocks.

### Application settings

Always separate from narrative state:

- Audio levels.
- Display settings.
- Accessibility settings.
- Input bindings.

Restarting must never reset accessibility preferences or other unrelated application settings.

## 16. Restart System

Implement a dedicated restart controller.

Suggested state machine:

    AVAILABLE
      -> TEMPTED
      -> WARNING
      -> CONFIRMATION
      -> RESTARTING
      -> NEW_TIMELINE

Allow cancellation before the restart transaction begins.

The UI requests a restart; the controller validates and performs it.

On confirmation:

1. Validate the active session.
2. Display the final warning.
3. Preserve only permitted meta-progression.
4. Safely archive or replace the active timeline save.
5. Generate a new timeline ID.
6. Initialize the new world.
7. Initialize new characters and quests.
8. Restore allowed meta-progression.
9. Validate timeline isolation.
10. Record the outcome for debugging.

Use a versioned save format and atomic-write or backup-and-recovery strategy appropriate to Godot.

Never silently delete the only valid save.

The fiction may treat a restarted universe as permanently lost. The real application must not depend on irreversible deletion of the player's only data.

## 17. Meta-Narrative Director

Build a dedicated system that schedules and activates authored anomalies.

The system may consider:

- Time spent in the timeline.
- Player progress.
- Characters encountered.
- Completed quests.
- Repeated interactions.
- Trap exposure.
- Prior restart count.
- Selected narrative choices.

Use a defined progression model rather than random escalation alone.

Example stages:

**Stage 0 — Comfort:** Normal exploration and friendly dialogue.

**Stage 1 — Oddity:** Repeated phrases, unusual environmental details, unexplained inconsistencies.

**Stage 2 — Suspicion:** Characters react strangely, objects repeat, and the interface begins changing.

**Stage 3 — Pressure:** The game offers seemingly convenient restart opportunities.

**Stage 4 — Confrontation:** The player discovers evidence that the game is influencing their decisions.

**Stage 5 — Resolution:** The player can confront the underlying system and complete the timeline.

These stages are narrative guidance, not a rigid timer. Players who explore thoroughly should encounter the events at appropriate points in the story.

---

# PART VII — FIRST PLAYABLE WORLD

## 18. World One: The Floating Village

Build a compact village suspended among pastel-colored floating islands.

The initial world contains:

- A small central plaza.
- Lumi's favorite meeting place.
- Pip's workshop.
- Momo's picnic garden.
- A strange tree.
- A path leading to a hidden area.
- One locked or inaccessible location that becomes relevant later.

The village should feel handcrafted rather than procedurally generated.

Use a consistent tile size and camera scale. Define them before producing large numbers of assets.

### Initial narrative

The player awakens near the village plaza.

Lumi welcomes them and introduces the world.

Pip needs help repairing a device that has stopped measuring time correctly.

Momo invites the player to a picnic.

The player explores, meets the three characters, and completes a simple quest.

The first anomalies are subtle:

- A character repeats a phrase.
- A clock moves backward.
- A cloud appears in the wrong location.
- A familiar object returns after being moved.

Eventually, the player encounters the endless picnic.

The player can escape by discovering the rule governing the loop, using a relevant tool, or making an appropriate narrative choice.

The game then introduces the first meaningful temptation to restart.

The first world ends only after the player has enough information and emotional investment to understand the decision.

---

# PART VIII — DEVELOPMENT PHASES

## Phase 0: Repository Audit and Planning

**Goal:** Establish the real project state and agree on a practical plan.

Tasks:

1. Inspect `project.godot`, scenes, scripts, assets, and plugins.
2. Identify the Godot version and existing architecture.
3. Run the current project.
4. Record existing functionality and known errors.
5. Create or update project documentation.
6. Define the first playable milestone.
7. Establish coding, naming, and testing conventions.
8. Identify the minimum viable art pipeline.

Deliverables:

- GDD.
- TDD.
- Character Bible.
- Art Bible.
- Roadmap.
- Risk register.
- Initial task breakdown.

**Acceptance criteria:** The project state is understood, and the first playable version is clearly specified.

## Phase 1: Godot Foundation

**Goal:** Establish a stable, runnable game shell.

Tasks:

1. Configure the main window and rendering settings.
2. Establish the input map.
3. Create the boot scene and main menu.
4. Create the world scene and player scene.
5. Implement the basic player controller.
6. Add a placeholder environment and collision.
7. Configure the camera.
8. Add pause and resume functionality.
9. Establish logging and basic error reporting.
10. Verify that the project starts without errors.

Deliverables:

- Runnable Godot project.
- Main menu.
- Test world.
- Player movement.
- Camera and collision.
- Pause menu.

**Acceptance criteria:** The player can launch the game, move around, collide with objects, pause, resume, and return to the main menu.

## Phase 2: Character Identity and Art Pipeline

**Goal:** Create the first recognizable characters.

Tasks:

1. Finalize Lumi, Pip, and Momo's silhouettes.
2. Establish a shared art direction.
3. Create initial sprite assets or layered character artwork.
4. Implement the reusable character scene.
5. Add character-specific accessories and facial expressions.
6. Implement idle and walk animations.
7. Implement basic talk and reaction animations.
8. Add interaction prompts.
9. Test readability at actual gameplay scale.
10. Create documentation for future character assets.

Deliverables:

- Three recognizable character sprites.
- Shared character scene.
- Character-specific presentation.
- Initial animation set.
- Character asset pipeline.

**Acceptance criteria:** A player can identify each character without relying on a name label or color alone.

## Phase 3: Exploration and Interaction

**Goal:** Make the world interactive.

Tasks:

1. Implement interaction detection.
2. Create a reusable interactable base.
3. Add doors, signs, objects, and NPC interactions.
4. Implement contextual prompts.
5. Add basic scene transitions.
6. Add environmental feedback.
7. Create the initial village layout.
8. Test interaction priority and input behavior.

Deliverables:

- Explorable village.
- Functional NPC interactions.
- Reusable world objects.
- Consistent interaction controls.

**Acceptance criteria:** The player can explore the village and interact reliably with its important objects and inhabitants.

## Phase 4: Dialogue and Narrative Foundation

**Goal:** Build branching conversations and meaningful choices.

Tasks:

1. Implement a dialogue data model.
2. Build the dialogue interface.
3. Add speaker names and portraits.
4. Implement player choices.
5. Implement conditional branches.
6. Connect dialogue to character and quest state.
7. Add dialogue validation.
8. Create the opening conversations.
9. Add automated tests for representative dialogue paths.

Deliverables:

- Dialogue manager.
- Dialogue UI.
- Data-driven conversations.
- Conditional choices.
- Opening narrative.

**Acceptance criteria:** Conversations can branch, modify game state, and produce different subsequent responses.

## Phase 5: Character Relationships and Quests

**Goal:** Give the player reasons to care about the characters.

Tasks:

1. Implement character state.
2. Implement relationship attributes and flags.
3. Implement the quest manager.
4. Create Pip's workshop quest.
5. Create a personal story for Lumi.
6. Create Momo's picnic quest.
7. Connect player choices to relationships.
8. Add character reactions to previous events.
9. Test quest completion and alternative outcomes.

Deliverables:

- Relationship system.
- Quest system.
- Three character stories.
- Consequences for player choices.

**Acceptance criteria:** The player can complete a short quest chain and observe characters responding differently to meaningful choices.

## Phase 6: Save, Load, and Timeline Architecture

**Goal:** Make timeline state explicit and reliable.

Tasks:

1. Define the save schema.
2. Implement serialization and deserialization.
3. Separate timeline state from meta-progression.
4. Add versioning and validation.
5. Implement safe writes and backup recovery.
6. Test saving and loading during normal gameplay.
7. Test state restoration for characters and quests.
8. Implement a new-timeline initializer.
9. Verify state isolation.

Deliverables:

- Save manager.
- Versioned save format.
- Timeline state model.
- Meta-progression model.
- New-timeline initializer.

**Acceptance criteria:** Saving and loading restores the same timeline, while a new timeline starts with the intended clean state.

## Phase 7: First Trap — The Endless Picnic

**Goal:** Validate the game's distinctive gameplay.

Tasks:

1. Implement a reusable trap state machine.
2. Create the picnic scene.
3. Implement repetition and changing dialogue.
4. Add environmental inconsistencies.
5. Add character reactions.
6. Implement discovery conditions.
7. Implement at least two distinct escape approaches.
8. Record the player's resolution choice.
9. Add tests for repeated entry and escape.
10. Integrate sound and visual feedback.

Deliverables:

- Complete playable trap.
- Multiple resolution paths.
- Narrative consequences.
- Regression tests.

**Acceptance criteria:** The loop can be entered, understood, escaped, and revisited without creating inconsistent state.

## Phase 8: Meta-Narrative and Restart Temptation

**Goal:** Make restarting a meaningful emotional decision.

Tasks:

1. Implement the meta-narrative director.
2. Define anomaly progression.
3. Create the restart interface.
4. Implement restart confirmation and cancellation.
5. Connect restart behavior to timeline persistence.
6. Add contextual messages and character reactions.
7. Implement escalating UI effects.
8. Test restart during different game states.
9. Verify that settings and permitted meta-progression survive.
10. Verify that no unauthorized external files are modified.

Deliverables:

- Functional restart system.
- Contextual anomalies.
- Meta-narrative progression.
- Safe restart transaction.

**Acceptance criteria:** The player understands what a restart means within the fiction, can cancel it, and experiences the intended consequences after confirming.

## Phase 9: Magic and Environmental Manipulation

**Goal:** Give the player alternatives to restarting.

Tasks:

1. Define the initial magic resource.
2. Implement one useful ability.
3. Connect the ability to a trap.
4. Add visual and audio feedback.
5. Add costs or contextual limitations.
6. Test ability interactions and invalid states.
7. Introduce additional abilities only when required by the narrative.

Deliverables:

- Magic framework.
- At least one complete ability.
- Integration with the first trap.

**Acceptance criteria:** The player can use magic to solve a problem that would otherwise create pressure to restart.

## Phase 10: Timeline Ending

**Goal:** Complete the first narrative arc.

Tasks:

1. Define the final conflict.
2. Connect earlier choices to the climax.
3. Implement the final character interactions.
4. Implement the timeline completion conditions.
5. Create the ending sequence.
6. Record the completed timeline.
7. Unlock the appropriate meta-progression.
8. Implement the credits or return-to-menu flow.
9. Test completion from valid gameplay paths.

Deliverables:

- Complete first-world story.
- Meaningful climax.
- Ending and post-ending state.
- Tested timeline completion.

**Acceptance criteria:** A player can finish the narrative without restarting and receive a coherent, emotionally satisfying resolution.

## Phase 11: Content Expansion

**Goal:** Expand only after the core experience works.

Tasks:

1. Add additional village areas.
2. Introduce new characters.
3. Create new quests and branching stories.
4. Add the returning-tree trap.
5. Expand magic and environmental puzzles.
6. Add optional secrets.
7. Expand the journal and discovery systems.
8. Add alternate timeline variations.
9. Improve character animation and environmental art.
10. Test content combinations and progression.

**Acceptance criteria:** New content integrates with existing systems without duplicating core logic or breaking narrative continuity.

## Phase 12: Polish and Release

**Goal:** Produce a stable and compelling game build.

Tasks:

1. Improve movement and interaction feel.
2. Refine dialogue timing and presentation.
3. Add and balance music and ambience.
4. Improve transitions and animation.
5. Refine lighting, color, and atmosphere.
6. Test accessibility settings.
7. Test keyboard and controller support as applicable.
8. Test saves, restarts, and recovery.
9. Profile performance.
10. Fix gameplay blockers and regressions.
11. Export a reproducible desktop build.
12. Verify the exported build on a clean launch.

Deliverables:

- Release candidate.
- Export instructions.
- Test report.
- Known-issues list.
- Final documentation.

**Acceptance criteria:** The exported build launches reliably, supports a complete playthrough, and satisfies the agreed release requirements.

---

# PART IX — AI CODING WORKFLOW

## 19. How Agents Must Work

For every assigned task:

1. Read the relevant design and architecture documents.
2. Inspect the files that will be changed.
3. State the intended implementation and affected interfaces.
4. Identify dependencies.
5. Implement a small, complete increment.
6. Run the available automated tests.
7. Launch or validate the Godot project when appropriate.
8. Review errors and warnings.
9. Update documentation.
10. Report completed work, test results, and remaining limitations.

Do not ask multiple agents to independently rewrite the same core system.

Assign one owner to each shared system. Other agents may review it or contribute through agreed interfaces.

### Recommended agent ownership

**Architecture agent:** Core systems, state model, persistence, integration contracts.

**Gameplay agent:** Movement, interactions, puzzles, magic, traps.

**Narrative agent:** Character writing, dialogue, quests, story continuity.

**Art agent:** Character concepts, sprite pipeline, environments, animations, presentation.

**QA agent:** Tests, regression checks, save/load validation, playthrough verification.

For a small project, combine roles as needed. Keep architectural and QA reviews independent from the code being reviewed.

## 20. Project Status Tracking

Maintain `docs/AGENT_STATUS.md` with:

- Current phase.
- Current milestone.
- Completed tasks.
- Active tasks and owners.
- Blocked tasks.
- Known bugs.
- Failed tests.
- Outstanding design decisions.
- Next recommended task.

Keep the roadmap aligned with the real state of the project.

Never mark a task complete simply because its code exists.

---

# PART X — FINAL QUALITY BAR

The finished game should satisfy the following requirements:

- Godot 4.x project opens and runs.
- Player movement and interactions are reliable.
- Main characters are individually recognizable.
- Dialogue branches and choices affect game state.
- Relationships and quests are functional.
- Timeline state and meta-progression are separated.
- Save/load and recovery work correctly.
- At least one environmental loop has a meaningful escape.
- Restart behavior is consistent and safe.
- Magic provides a useful alternative to restarting.
- The first timeline has a complete ending.
- Visual and audio presentation support the narrative.
- Automated tests cover high-risk state transitions.
- The exported build is playable from start to finish.

The most important acceptance criterion is not the number of systems or assets.

**The player must care enough about the world that restarting feels like a meaningful loss—and have enough agency that preserving it feels like an accomplishment.**
