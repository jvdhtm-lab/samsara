class_name InteractionSelector
extends RefCounted
## Pure selection rule for the current interaction target.
##
## Systems layer. Chooses the best candidate by descending `priority`, then by
## ascending distance from the probing position. Callers pre-filter candidates
## by validity and `can_interact`.

static func pick(targets: Array, from: Vector2) -> Interactable:
	var best: Interactable = null
	var best_priority := -2147483648
	var best_distance := INF
	for candidate in targets:
		if not is_instance_valid(candidate):
			continue
		var node := candidate as Node2D
		if node == null:
			continue
		var candidate_priority := int(candidate.get("interaction_priority"))
		var candidate_distance := from.distance_squared_to(node.global_position)
		if candidate_priority > best_priority \
				or (candidate_priority == best_priority and candidate_distance < best_distance):
			best_priority = candidate_priority
			best_distance = candidate_distance
			best = candidate
	return best
