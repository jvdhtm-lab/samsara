class_name RelationshipManager
extends RefCounted
## Derives character reactions from relationship state.
##
## Systems layer, pure/static. Turns relationship attributes into a
## relationship level and an idle expression, so characters visibly respond to
## how the player has treated them (see docs/CHARACTER_BIBLE.md).

static func level(timeline: TimelineState, character_id: StringName) -> String:
	return timeline.relationship_level(character_id)


## The expression a character wears when idle, based on how they feel.
static func reaction_expression(timeline: TimelineState, character_id: StringName) -> StringName:
	var state := timeline.get_character_state(character_id)
	if state == null:
		return &"neutral"
	if state.get_attribute("suspicion") >= 2:
		return &"afraid"
	match state.relationship_level():
		CharacterState.LEVEL_CONFIDANT:
			return &"happy"
		CharacterState.LEVEL_WARY:
			return &"afraid"
		_:
			return &"neutral"
