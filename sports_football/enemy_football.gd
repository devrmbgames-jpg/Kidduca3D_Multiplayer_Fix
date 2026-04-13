extends KinematicBody

const CharacterAnimation := preload("res://resources/models/character_v2/character_animation_v3.gd")
const FCM := preload("res://content/fcm/fcm.gd")

enum GAME {
	FOOTBALL,
	BASKETBALL
}

export(PackedScene) var character: PackedScene = null
export(GAME) var game := GAME.FOOTBALL
export(NodePath) var ball_path := NodePath("")
export(NodePath) var gate_path := NodePath("")
export(NodePath) var trap_ball_player := NodePath("")
export(bool) var is_friend := false

onready var _instance_placeholder : InstancePlaceholder = $Character
var _character: CharacterAnimation = null

onready var _trap_ball := $TrapBall
onready var _area_alloc := $AreaAllocation
onready var _ray_pass := $RayPass
onready var _ray_pass_to_player := $RayPassToPlayer
onready var _ray_goal := $RayGoal

var _ball : RigidBody = null
var _gate : Position3D = null
var _trap_ball_player : Area = null

var _target : Spatial = null

var _direction := Vector3.ZERO
var _rotation := 0.0
var _speed_rotation := 4.0
var _speed_linear := 3.0
var _velocity := Vector3.ZERO

var _is_go_to_ball := false
onready var _timer_to_ball : SceneTreeTimer = get_tree().create_timer(0.0)

var _is_ball_traped := false

var _is_pass_to_player := false

var _is_playing := false

onready var _last_fcm := FCM.IDLE
var is_crazy := false

func _ready() -> void:
	if _instance_placeholder :
		Logger.log_i(self, " instance PH BEGIN ", Time.get_ticks_msec(), " ", Engine.get_idle_frames())
		_character = _instance_placeholder.create_instance(false, character)
		Logger.log_i(self, " instance PH END ", Time.get_ticks_msec(), " ", Engine.get_idle_frames())
	#_character.fcm.push_state(FCM.RUN)
	
	_rotation = rotation.y
	
	if not ball_path.is_empty():
		_ball = get_node(ball_path)
		_trap_ball.set_ball(_ball)
		_target = _ball
	if not gate_path.is_empty():
		_gate = get_node(gate_path)
	if not trap_ball_player.is_empty():
		_trap_ball_player = get_node(trap_ball_player)
	
	_trap_ball.is_friend = is_friend
	_trap_ball.game = game
	_trap_ball.set_game()

func _physics_process(delta) -> void :
	if _is_playing:
		_set_direction()
		_rotate(delta)
		_move(delta)
		_random_pass()
		_random_goal()

func _random_pass() -> void :
	if _is_pass_to_player:
		var area : Area = _ray_pass_to_player.get_collider()
		if area and _is_ball_traped and _trap_ball_player:
			if area.is_in_group("TRAP_BALL"):
				if area.trap_type == area.TRAP_TYPE.PLAYER:
					_trap_ball.kick_ball(true, _trap_ball_player)
	else:
		var area : Area = _ray_pass.get_collider()
		if area and _is_ball_traped:
			if area.is_in_group("TRAP_BALL"):
				if area.is_friend == is_friend and not area.trap_type == area.TRAP_TYPE.GOALKEEPER:
					if randi() % 5 == 0:
						_trap_ball.kick_ball(false)

func _random_goal() -> void :
	if _is_pass_to_player:
		return
	
	var area : Area = _ray_goal.get_collider()
	if area and _is_ball_traped:
		if not area.get_parent().is_friend == is_friend:
			if randi() % 10 == 0:
				if game == GAME.FOOTBALL:
					_trap_ball.kick_ball(false)
				if game == GAME.BASKETBALL and _target:
					_trap_ball.kick_ball(true, _target)

func change_skin(path_pkg: String) -> void :
	_character.queue_free()
	_character = null
	if _instance_placeholder :
		Logger.log_i(self, " instance PH BEGIN ", Time.get_ticks_msec(), " ", Engine.get_idle_frames())
		_character = _instance_placeholder.create_instance(false, ResourceLoader.load(path_pkg, "", GlobalSetupsConsts.NO_CACHED))
		Logger.log_i(self, " instance PH END ", Time.get_ticks_msec(), " ", Engine.get_idle_frames())

func update_reward_items(clothes: Array = []) -> void :
	Logger.log_i(self, " update rewardes ", clothes)
	if _character:
		_character.update_reward_items(clothes)

func get_reward_items() -> Array :
	if _character:
		_character.get_reward_items()
	return []

func play_game() -> void :
	_is_playing = true
	_character.fcm.pop_state()
	_character.fcm.push_state(FCM.RUN)
	_last_fcm = FCM.RUN

func stand() -> void :
	_is_playing = false
	_character.fcm.pop_state()
	_character.fcm.push_state(FCM.IDLE)
	_last_fcm = FCM.IDLE

func victory() -> void :
	_is_playing = false
	_character.fcm.pop_state()
	_character.fcm.push_state(FCM.ACTION)
	_character.set_action_idx(2)
	_last_fcm = FCM.ACTION
	

func set_target(target: Spatial) -> void:
	_target = target

func go_to_ball() -> void :
	if not _is_ball_traped:
		_timer_to_ball = get_tree().create_timer(5.0)
		_timer_to_ball.connect("timeout", self, "_timer_to_ball_timeout")
		_is_go_to_ball = true

func stop_go_to_ball() -> void :
	_is_go_to_ball = false

func pass_to_player() -> void :
	if not _is_ball_traped or not is_friend:
		return
	
	_is_pass_to_player = true
	_target = _trap_ball_player

func get_area_trap_ball() -> Area :
	return _trap_ball as Area

func _timer_to_ball_timeout() -> void :
	_is_go_to_ball = false

func _set_direction() -> void :
	if not _target:
		return
	
	_direction = _target.global_transform.origin - global_transform.origin
	_direction.y = 0.0
	_direction = _direction.normalized()
	
	if _is_pass_to_player:
		return
	
	var direct := Vector3.ZERO
	var distance := 10000.0
	var nom := -1
	var areas : Array = _area_alloc.get_overlapping_areas()
	if not areas.empty() and not _is_go_to_ball:
		for i in areas.size():
			if areas[i].is_in_group("AREA_WALLS"):
				nom = i
				break
			else:
				if not (_is_ball_traped and areas[i].get_parent().is_friend == is_friend):
					var dist_to_area : float = (global_transform.origin - areas[i].global_transform.origin).length()
					if dist_to_area < distance:
						distance = dist_to_area
						nom = i
		if nom >=0:
			if areas[nom].is_in_group("AREA_WALLS"):
				direct = -global_transform.origin + areas[nom].global_transform.origin
			else:
				direct = global_transform.origin - areas[nom].global_transform.origin
	
	if not direct == Vector3.ZERO:
		_direction += direct.normalized() * 2.0
	
	_direction.y = 0.0
	_direction = _direction.normalized()

var _sign := 1.0
func _rotate(delta : float) -> void :
	var step_rot := _speed_rotation * delta
	var direct : Vector3 = -Vector3.FORWARD.rotated(Vector3.UP, _rotation)
	var direct_rot : Vector3 = -Vector3.FORWARD.rotated(Vector3.UP, _rotation + step_rot)
	var dot_1 := _direction.dot(direct)
	var dot_2 := _direction.dot(direct_rot)
	
	var delta_dot : float = 2.0 * (step_rot / PI)
	
	if (1.0 - dot_1) > delta_dot:
		if dot_2 > dot_1:
			_sign = 1.0
			_rotation += step_rot
		else:
			_sign = -1.0
			_rotation -= step_rot
	else:
		step_rot *= (1.0 - dot_1) / delta_dot
		_rotation += step_rot * _sign
	
	self.rotation.y = _rotation

func _move(_delta : float) -> void :
	var direct : Vector3 = -Vector3.FORWARD.rotated(Vector3.UP, _rotation)
	_velocity = direct * _speed_linear
	_velocity = move_and_slide(_velocity)



func _on_TrapBall_trap_ball():
	_is_go_to_ball = false
	_is_ball_traped = true
	if _ball.can_trap:
		_target = _gate


func _on_TrapBall_untrap_ball():
	_is_ball_traped = false
	_is_pass_to_player = false
	if _ball.can_trap:
		_target = _ball


func _on_VisibilityEnabler_screen_entered():
	if is_crazy:
		yield(get_tree(),"idle_frame")
		_character.fcm.pop_state()
		_character.fcm.push_state(FCM.IDLE)
		yield(get_tree(),"idle_frame")
		_character.fcm.pop_state()
		_character.fcm.push_state(_last_fcm)
		if _last_fcm == FCM.ACTION:
			_character.set_action_idx(2)
