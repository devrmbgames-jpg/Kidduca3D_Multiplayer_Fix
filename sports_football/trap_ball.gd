extends Area

signal trap_ball()
signal untrap_ball()

enum TRAP_TYPE {
	ENEMY,
	GOALKEEPER,
	PLAYER
}

enum GAME {
	FOOTBALL,
	BASKETBALL
}

export(NodePath) var ball_path := NodePath("")
export(TRAP_TYPE) var trap_type := TRAP_TYPE.ENEMY
export(GAME) var game := GAME.FOOTBALL
export(bool) var is_friend := false

onready var _ball : RigidBody = null
onready var _pos_ball := $Position3D
onready var _pos_kick_ball := $PosKickBall
onready var _animation_pos_ball := $Position3D/AnimationPlayerPosBall

onready var _coll_football := $CollisionShapeFootball
onready var _coll_basketball := $CollisionShapeBasketball

var _is_kick := false
var _is_ball_in_area := false
var can_trap := true

func _ready():
	if not ball_path.is_empty():
		_ball = get_node(ball_path) as RigidBody
	
	set_game()

func _physics_process(_delta) -> void:
	if not can_trap:
		return
	
	if not _ball or not _is_ball_in_area or _is_kick:
		return
	
	if not _ball.can_trap and not trap_type == TRAP_TYPE.GOALKEEPER:
		return
	
	if not _ball.mode == RigidBody.MODE_RIGID:
		return
	
	var force := 30.0
	var coef_damp := 1.5
	var vec_force : Vector3 = _pos_ball.global_transform.origin - _ball.global_transform.origin
	_ball.add_central_force(vec_force * force)
	_ball.add_central_force(-_ball.linear_velocity * coef_damp)

func set_game() -> void :
	if game == GAME.FOOTBALL:
		_coll_football.disabled = false
		_coll_basketball.disabled = true
		_animation_pos_ball.play("play_football")
	if game == GAME.BASKETBALL:
		_coll_football.disabled = true
		_coll_basketball.disabled = false
		_animation_pos_ball.play("play_basketball")

func kick_ball(is_target: bool, target: Spatial = null) -> void :
	if not can_trap:
		return
	
	if not _ball or not _is_ball_in_area or _is_kick:
		return
	
	if not _ball.can_trap and not trap_type == TRAP_TYPE.GOALKEEPER:
		return
	
	if not _ball.mode == RigidBody.MODE_RIGID:
		return
	
	_is_kick = true
	var timer : SceneTreeTimer = get_tree().create_timer(0.5)
	timer.connect("timeout", self, "_timer_timeout")
	
	var force := 0.0
	var vec_impulse := Vector3.ZERO
	
	if game == GAME.FOOTBALL:
		if is_target:
			if target.is_in_group("TRAP_BALL"):
				_ball.linear_velocity = Vector3.ZERO
				var dist_to_target := global_transform.origin.distance_to(target.global_transform.origin)
				var coef_up = dist_to_target
				force = dist_to_target * 0.065
				if force < 1.2:
					coef_up *= force / 2.0
					force = 1.2
				vec_impulse = ((target.global_transform.origin + Vector3.UP * coef_up) - global_transform.origin).normalized()
			else:
				_ball.linear_velocity = Vector3.ZERO
				var dist_to_target := global_transform.origin.distance_to(target.global_transform.origin)
				var coef_up = dist_to_target
				force = dist_to_target * 0.075
				if force < 1.2:
					coef_up *= force * 1.1
					force = 1.2
				vec_impulse = ((target.global_transform.origin + Vector3.UP * coef_up) - global_transform.origin).normalized()
		elif trap_type == TRAP_TYPE.ENEMY:
			_ball.linear_velocity = Vector3.ZERO
			force = 1.2
			vec_impulse = ((_pos_kick_ball.global_transform.origin + Vector3.UP * 0.4) - global_transform.origin).normalized()
		elif trap_type == TRAP_TYPE.GOALKEEPER:
			_ball.linear_velocity = Vector3.ZERO
			force = 2.5
			vec_impulse = ((_pos_kick_ball.global_transform.origin + Vector3.UP * 1.5) - global_transform.origin).normalized()
		else: # player
			force = 1.0
			vec_impulse = ((_pos_kick_ball.global_transform.origin + Vector3.UP * 0.4) - global_transform.origin).normalized()
	
	if game == GAME.BASKETBALL:
		_ball.linear_velocity = Vector3.ZERO
		if is_target:
			if target.is_in_group("TRAP_BALL"):
				var dist_to_target := global_transform.origin.distance_to(target.global_transform.origin)
				var coef_up = dist_to_target
				force = dist_to_target * 0.065
				if force < 1.2:
					coef_up *= force / 2.0
					force = 1.2
				vec_impulse = ((target.global_transform.origin + Vector3.UP * coef_up) - global_transform.origin).normalized()
			else:
				var dist_to_target := global_transform.origin.distance_to(target.global_transform.origin)
				var coef_up = dist_to_target
				force = dist_to_target * 0.1
				if force < 1.2:
					coef_up *= force * 1.3
					force = 1.2
				vec_impulse = ((target.global_transform.origin + Vector3.UP * coef_up) - global_transform.origin).normalized()
		else:
			force = 1.2
			vec_impulse = ((_pos_kick_ball.global_transform.origin + Vector3.UP * 0.4) - global_transform.origin).normalized()
		
	_ball.apply_central_impulse(vec_impulse * force)

func _timer_timeout() -> void:
	_is_kick = false

func set_ball(ball: RigidBody) -> void:
	_ball = ball

func get_direction() -> Vector3 :
	var direct : Vector3 = _pos_kick_ball.global_transform.origin - global_transform.origin
	direct.y = 0.0
	return direct.normalized()


func _on_TrapBall_body_entered(body):
	if _ball:
		if body == _ball:
			_is_ball_in_area = true
			emit_signal("trap_ball")


func _on_TrapBall_body_exited(body):
	if _ball:
		if body == _ball:
			_is_ball_in_area = false
			emit_signal("untrap_ball")
