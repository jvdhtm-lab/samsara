class_name SpawnPoint
extends Node2D
## Named marker used to place the player when an area loads.
##
## Systems layer. AreaController resolves the requested spawn id (from Game)
## against these markers.

@export var spawn_id: StringName = &"default"
