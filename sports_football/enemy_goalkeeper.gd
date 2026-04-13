extends KinematicBody

signal trap_ball()
signal untrap_ball()

const CharacterAnimation := preload("res://resources/models/character_v2/character_animation_v3.gd")
const FCM := preload("res://content/fcm/fcm.gd")

export(PackedScene) var character: PackedScene = null
export(NodePath) var ball_path := NodePath("")
export(NodePath) var spawn_ball_path := NodePath("")
export(NodePath) var target_1_path := NodePath("")
export(NodePath) var target_2_path := NodePath("")
export(NodePath) var trap_ball_player := NodePath("")
export(bool) var is_friend := false setget set_is_friend
func set_is_friend(turn: bool) -> void :
	is_friend = turn
	if _trap_ball and is_instance_valid(_trap_ball):
		_trap_ball.is_friend = turn

onready var _instance_placeholder : InstancePlaceholder = $Character
var _character: CharacterAnimation = null

onready var _trap_ball := $TrapBall

var _ball : RigidBody = null
var _spawn_ball : Position3D = null
var _target_1 : Position3D = null
var _target_2 : Position3D = null
var _trap_ball_player : Area = null

var _target_move : Spatial = null
var _target_look : Spatial = null

var _rotation := 0.0
var _speed_rotation := 4.0
var _speed_linear := 3.0
var _velocity := Vector3.ZERO

var _is_go_to_ball := false

var _is_ball_traped := false

var _is_playing := false

onready var _last_fcm := FCM.IDLE
var is_crazy := false

onready var _timer_kick_ball : SceneTreeTimer = get_tree().create_timer(0.0)

func _ready():
	if _instance_placeholder:
		Logger.log_i(self, " instance PH BEGIN ", Time.get_ticks_msec(), " ", Engine.get_idle_frames())
		_character = _instance_placeholder.create_instance(false, character)
		Logger.log_i(self, " instance PH END ", Time.get_ticks_msec(), " ", Engine.get_idle_frames())
	#_character.fcm.push_state(FCM.RUN)
	
	_rotation = rotation.y
	
	if not ball_path.is_empty():
		_ball = get_node(ball_path)
		_trap_ball.set_ball(_ball)
	if not spawn_ball_path.is_empty():
		_spawn_ball = get_node(spawn_ball_path)
	if not target_1_path.is_empty():
		_target_1 = get_node(target_1_path)
	if not target_2_path.is_empty():
		_target_2 = get_node(target_2_path)
	if not trap_ball_player.is_empty():
		_trap_ball_player = get_node(trap_ball_player)
	
	_trap_ball.is_friend = is_friend
	_target_move = _target_1
	_target_look = _ball

func _process(delta) -> void :
	if _is_playing:
		_rotate(delta)
		_move(delta)
		_change_target_move()

var _sign := 1.0
func _rotate(delta : float) -> void :
	if not _target_look:
		return
	
	var step_rot := _speed_rotation * delta
	var direction_look : Vector3 = (_target_look.global_transform.origin - global_transform.origin).normalized()
	var direct : Vector3 = -Vector3.FORWARD.rotated(Vector3.UP, _rotation)
	var direct_rot : Vector3 = -Vector3.FORWARD.rotated(Vector3.UP, _rotation + step_rot)
	var dot_1 := direction_look.dot(direct)
	var dot_2 := direction_look.dot(direct_rot)
	
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
	var direct : Vector3 = global_transform.origin.direction_to(_target_move.global_transform.origin)
	direct.y = 0.0
	_velocity = direct * _speed_linear
	_velocity = move_and_slide(_velocity)

func _change_target_move() -> void :
	if _is_go_to_ball:
		return
	
	var distance := (global_transform.origin - _target_move.global_transform.origin).length()
	if distance < 0.2:
		if _target_move == _target_1:
			_target_move = _target_2
		else:
			_target_move = _target_1

func change_skin(path_pkg: String) -> void :
	_character.queue_free()
	_character = null
	if _instance_placeholder :
		Logger.log_i(self, " instance PH BEGIN ", Time.get_ticks_msec(), " ", Engine.get_idle_frames())
		_character = _instance_placeholder.create_instance(false, load(path_pkg))
		Logger.log_i(self, " instance PH END ", Time.get_ticks_msec(), " ", Engine.get_idle_frames())

func update_reward_items(clothes: Array = []) -> void :
	Logger.log_i(self, " update rewardes ", clothes)
	if _character:
		_character.update_reward_items(clothes)

func get_reward_items() -> Array :
	if _character:
		_character.get_reward_items()
	return []

func play_game() -> void:
	_is_playing = true
	_character.fcm.pop_state()
	_character.fcm.push_state(FCM.RUN)
	_last_fcm = FCM.RUN

func stand() -> void:
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

func go_to_ball() -> void :
	_is_go_to_ball = true
	_target_move = _ball

func stop_go_to_ball() -> void :
	_is_go_to_ball = false
	_target_move = _target_1

func look_to_ball() -> void :
	_target_look = _ball
 
func look_to_spawn_ball() -> void :
	_target_look = _spawn_ball

func _timer_kick_ball_timeout() -> void :
	
	if _is_ball_traped:
		if is_friend and _trap_ball_player:
			_trap_ball.kick_ball(true, _trap_ball_player)
		else:
			_trap_ball.kick_ball(false)
		_target_look = _ball

func _on_TrapBall_trap_ball():
	_is_ball_traped = true
	stop_go_to_ball()
	if is_friend and _trap_ball_player:
		_target_look = _trap_ball_player
	else:
		_target_look = _spawn_ball
	emit_signal("trap_ball")
	if _timer_kick_ball.time_left <= 0:
		_timer_kick_ball = get_tree().create_timer(1.0)
		_timer_kick_ball.connect("timeout", self, "_timer_kick_ball_timeout")


func _on_TrapBall_untrap_ball():
	_is_ball_traped = false
	emit_signal("untrap_ball")

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
