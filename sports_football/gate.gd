extends Spatial

signal goal()

const BALL_MP := preload("res://content/houses/sports_football/football_mp/ball_mp.gd")

const MAT_BLUE := preload("res://resources/materials/colors_cars/blue_3.material")
const MAT_RED := preload("res://resources/materials/ketchup.tres")

export(bool) var is_friend := false

onready var _gate_mesh : MeshInstance = $gate
onready var _timer_goal : SceneTreeTimer = get_tree().create_timer(0.0)


func _ready() -> void:
	if is_friend:
		_gate_mesh.set_surface_material(0, MAT_RED)
	else:
		_gate_mesh.set_surface_material(0, MAT_BLUE)


func _on_Area_body_entered(_body):
	if not _body is BALL_MP:
		return
	if _timer_goal.time_left > 0:
		return
	
	if not _body.is_player:
		return
	
	_timer_goal = get_tree().create_timer(3.0)
	emit_signal("goal")
