extends RigidBody

const NetworkConst := preload("res://content/network/network_const.gd")


onready var _mat_ball : ShaderMaterial = $football_ball.mesh.surface_get_material(0) as ShaderMaterial
onready var _area_ball : Area = $AreaBall


var is_player := false setget set_is_player
func set_is_player(turn: bool) -> void :
	is_player = turn
	if turn:
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		mode = RigidBody.MODE_RIGID
	else:
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		mode = RigidBody.MODE_STATIC
	
	if turn:
		send_is_player()


var can_trap := true
var _max_speed_ball := 15.0
var _target_pos := Vector3.ZERO
var _target_ang_vel := Vector3.ZERO


# network
enum TYPE_DATA {
	MOVE_BALL,
	IS_PLAYER,
}

enum NAME_DATA {
	TYPE_UPDATE,
	TYPE,
	IDX_OBJ,
	TYPE_OBJ,
	
	MOVE_BALL,
	IS_PLAYER,
}

var _data_network_move_ball := {
	NAME_DATA.TYPE_UPDATE : NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_LEVELS,
	NAME_DATA.TYPE : TYPE_DATA.MOVE_BALL,
	NAME_DATA.IDX_OBJ : "",
	NAME_DATA.TYPE_OBJ : NetworkConst.TYPE_OBJ_LEVEL.FOOTBALL_BALL,
	NAME_DATA.MOVE_BALL : null
}

var _data_network_is_player := {
	NAME_DATA.TYPE_UPDATE : NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_LEVELS,
	NAME_DATA.TYPE : TYPE_DATA.IS_PLAYER,
	NAME_DATA.IDX_OBJ : "",
	NAME_DATA.TYPE_OBJ : NetworkConst.TYPE_OBJ_LEVEL.FOOTBALL_BALL,
	NAME_DATA.IS_PLAYER : false
}


func _ready() -> void:
	set_is_player(false)
	#yield(get_tree(), "idle_frame")
	#_target_pos = global_position

func _physics_process(_delta) -> void :
	if not is_player and not _target_pos == Vector3.ZERO:
		if global_position.distance_to(_target_pos) > 20.0:
			global_position = _target_pos
		else:
			global_position = lerp(global_position, _target_pos, 0.03)

		var delta_rotation = Basis(_target_ang_vel * _delta)
		global_transform.basis = delta_rotation * global_transform.basis
		
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
	else:
		if linear_velocity.length() > _max_speed_ball * 1.1:
			linear_velocity = linear_velocity.normalized() * _max_speed_ball
	

func force_take_authority() -> void :
	_target_pos = global_position
	_target_ang_vel = angular_velocity
	set_is_player(true)

func change_mat_ball(icon : AtlasTexture, region_start : Vector2, uv_offset : Vector2) -> void :
	_mat_ball.set_shader_param("albedo_texture", icon)
	_mat_ball.set_shader_param("region_start", region_start)
	_mat_ball.set_shader_param("uv_offset", uv_offset)

func get_area_ball() -> Area :
	return _area_ball


func send_move_ball() -> void :
	if not is_player:
		return
	
	_data_network_move_ball[NAME_DATA.IDX_OBJ] = get_parent().get_parent().name
	
	var step := 0.01
	_data_network_move_ball[NAME_DATA.MOVE_BALL] = PoolRealArray([
		stepify(global_position.x, step),
		stepify(global_position.y, step),
		stepify(global_position.z, step),
		stepify(angular_velocity.x, step),
		stepify(angular_velocity.y, step),
		stepify(angular_velocity.z, step),
	])
	
	var key : int = NetworkConst.GLOBAL_TYPE_DATA.OPEN_GAME
	Singletones.get_Network().api.setup_data(key, _data_network_move_ball)
	Singletones.get_Network().api.send_data_to_all()

func send_is_player() -> void :
	if not is_player:
		return
	
	_data_network_is_player[NAME_DATA.IDX_OBJ] = get_parent().get_parent().name
	_data_network_is_player[NAME_DATA.IS_PLAYER] = is_player
	
	var key : int = NetworkConst.GLOBAL_TYPE_DATA.OPEN_GAME
	Singletones.get_Network().api.setup_data(key, _data_network_is_player)
	Singletones.get_Network().api.send_data_to_all()
	

func update_network_data(data: Dictionary) -> void :
	match data[NAME_DATA.TYPE] as int:
		TYPE_DATA.MOVE_BALL:
			if not is_player:
				var pos_arr : PoolRealArray = data[NAME_DATA.MOVE_BALL]
				_target_pos = Vector3(pos_arr[0], pos_arr[1], pos_arr[2])
				_target_ang_vel = Vector3(pos_arr[3], pos_arr[4], pos_arr[5])
		TYPE_DATA.IS_PLAYER:
			_target_pos = global_position
			_target_ang_vel = angular_velocity
			set_is_player(false)


func _on_TimerNetworkUpdate_timeout() -> void:
	send_move_ball()
