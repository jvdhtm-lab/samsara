# Samsara — Architecture Contract

Implement Samsara as a modular, data-driven Godot 4.x game using GDScript.

## Architectural objective

The project must support adding characters, dialogue, quests, worlds, traps, abilities, and endings without repeatedly modifying unrelated core systems.

Prefer a modular monolith with clear boundaries. Do not introduce microservices, networking, or external databases for the initial single-player game.

## Required boundaries

Separate presentation, gameplay, narrative, mutable game state, persistence, and infrastructure.

Maintain separate representations for:

1. Current timeline state.
2. Cross-timeline meta-progression.
3. Application settings.

Keep character identity, quest progress, relationship state, and environmental consequences explicit and serializable.

## Data and behavior

Use custom Godot Resources for structured authored content where appropriate.

Use GDScript for runtime behavior and explicit state transitions.

Keep shared definitions immutable during gameplay. Store changing values in authoritative state models.

Use stable IDs for characters, dialogue nodes, quests, traps, items, abilities, worlds, and endings.

Validate all authored references and conditional logic.

## Dependencies

Use small interfaces and explicit dependencies.

Use direct calls for commands and signals for relevant notifications.

Do not allow UI code to directly mutate authoritative game state.

Do not let the meta-narrative modify arbitrary scene nodes or bypass gameplay rules.

Do not introduce global autoloads unless their lifetime and responsibility justify them.

## Persistence and restart

Implement a dedicated restart coordinator.

Separate the restart request, confirmation, transaction, new-timeline initialization, and recovery behavior.

Use versioned saves, validation, backups, and safe writes.

Ensure permitted meta-progression survives restarts while timeline-specific state resets according to explicit rules.

Never depend on deleting the player's only save file.

## Testing

Provide unit tests for important rules and state transitions.

Provide integration tests for dialogue, quests, traps, and meta-narrative interactions.

Provide persistence tests for save/load, migration, restart isolation, and recovery.

Provide content validation for IDs, missing references, invalid branches, and missing assets.

Keep the game runnable after every phase.

## Agent workflow

Before changing shared architecture, inspect existing interfaces and document the intended change.

Assign one accountable owner to each core subsystem.

Do not implement competing versions of the same manager.

Make small, reviewable changes, run relevant tests, validate the Godot project, and update project status.

Do not claim success without evidence.

## Scalability rule

Prefer a simple implementation that supports the current requirements and has a clear extension path.

Introduce additional abstractions only when a concrete use case demonstrates their value.

The architecture succeeds when the team can expand the game without losing narrative consistency, state integrity, character identity, or the ability to test the result.
