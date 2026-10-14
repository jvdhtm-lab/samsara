class_name Interactable
extends Area2D
## Base class for anything the player can interact with.
##
## Systems layer. The player's interaction probe detects these areas and asks
## them to interact. Selection uses `priority` first, then distance, so
## important objects (NPCs, doors) win over decorative props.
##
## Lives on physics layer 3 ("interactable"); it is monitored, not monitoring.

@export var prompt_text: String = "Interact"
@export var enabled: bool = true
@export var interaction_priority: int = 0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	monitorable = true


func can_interact(_player: Node) -> bool:
	return enabled


func interact(_player: Node) -> void:
	pass


## Optional short visual acknowledgement that this object was used.
func play_feedback() -> void:
	if not is_inside_tree():
		return
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.14)
