class_name PetSwarm
extends Node3D
## Manages a population of tiny autonomous critters scattered across the island.
## Purely decorative: they wander, randomly follow the player, are nice to each
## other, sometimes fight, and sometimes kill each other. The population is kept
## topped up by respawning.

const MODELS: Array[String] = [
	"chars/minion-a01", "chars/minion-a02", "chars/minion-b01", "chars/minion-b02",
	"chars/minion-c01", "chars/minion-c02", "chars/minion-d01", "chars/minion-d02",
	"chars/Enemy_Small", "chars/Enemy_ExtraSmall",
]

var _world: Node3D
var _player: Node2D
var _center := Vector2.ZERO
var _island_radius := 460.0
var _target_count := 28
var _pets: Array = []
var _respawn := 3.0


func setup(world: Node3D, player: Node2D, center: Vector2, island_radius: float, count: int) -> void:
	_world = world
	_player = player
	_center = center
	_island_radius = island_radius
	_target_count = count
	for i in range(count):
		_spawn()
	set_process(true)


func pets() -> Array:
	return _pets


func player() -> Node2D:
	return _player


func neighbors(pet: Pet3D, radius: float) -> Array:
	var out: Array = []
	for p in _pets:
		if p == pet or not p.is_alive():
			continue
		if pet.pos2d().distance_to(p.pos2d()) < radius:
			out.append(p)
	return out


func kill(pet: Pet3D) -> void:
	_pets.erase(pet)
	pet.die()


func _spawn() -> void:
	var id: String = MODELS[randi() % MODELS.size()]
	var angle := randf() * TAU
	var radius := sqrt(randf()) * _island_radius * 0.85
	var pos := _center + Vector2(cos(angle), sin(angle)) * radius
	var pet := Pet3D.new()
	add_child(pet)
	pet.setup(_world, self, id, pos)
	_pets.append(pet)


func _process(delta: float) -> void:
	if _pets.size() < _target_count:
		_respawn -= delta
		if _respawn <= 0.0:
			_respawn = 3.0
			_spawn()
