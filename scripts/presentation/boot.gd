extends Node
## Boot entry point. Routes to the main menu once the game is ready.
##
## Application/presentation boundary.

func _ready() -> void:
	Game.go_to_main_menu()
