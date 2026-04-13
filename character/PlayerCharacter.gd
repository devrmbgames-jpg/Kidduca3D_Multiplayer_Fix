extends "res://content/character/character.gd"

func _ready():
	Singletones.get_Global().player_character = self

func _on_PlayerController_jump() -> void:
	on_jump()


func _on_PlayerController_changed_direction(new_direction: Vector3) -> void:
	on_changed_direction(new_direction)

