extends Spatial

const NetworkConst := preload("res://content/network/network_const.gd")
const CharacterAnimations := preload("res://resources/models/character_v2/character_animation_v3.gd")
const FCM := preload("res://content/fcm/fcm.gd")
const CharacterConst := preload("res://content/character/characters_consts.gd")


onready var _player_core := $Core
onready var _instance_placeholder := $Core/Character
onready var _target_move := $PosTargetMove
onready var _name_player := $Core/NamePlayer
onready var _timer_despawn := $TimerDespawn

onready var _smiles := $Core/Smiles

onready var _path_system_bot := $PathSystemBot
onready var _coll_path := $Core/AreaPath/CollisionShape
onready var _timer_despawn_bot := $TimerDespawnBot

var _character: CharacterAnimations = null


# network
enum TYPE_DATA {
	MOVE_PLAYER,
	ALL_DATA,
	GIVE_ME_ALL_DATA,
	NAME_PLAYER,
	CLOTHES,
	IDX_CHARACTER,
	NUM_WORLD,
	SMILE,
	IN_GAME,
	ANIMATION,
	IN_LOBBY,
	IS_HOST,
}

enum NAME_DATA {
	TYPE_UPDATE,
	TYPE,
	IDX_OBJ,
	
	MOVE_PLAYER,
	NAME_PLAYER,
	CLOTHES,
	IDX_CHARACTER,
	NUM_WORLD,
	SMILE,
	IN_GAME,
	ANIMATION
	LEVEL_ACHIV,
	IS_ACTIVE_SUB,
	IN_LOBBY,
	IS_HOST,
}

const SPEED_ROTATE := 10.0
const SPEED_ROTATE_BOT := 4.0
const SPEED_LIN := 4.7

var name_pl := ""
var clothes := []
var idx_character := 0
var num_world := 0
var in_game := false
var in_lobby := false
var is_host := false
var is_player_in_game := false
var level_achivment := 0.2
var is_active_subscription := false
var all_data_ready := false

var is_visible := true setget set_visible
func set_visible(turn: bool) -> void :
	is_visible = turn
	_setup_visible()

var _fcm: FCM = null

var is_bot := false setget set_is_bot
func set_is_bot(turn: bool) -> void :
	Logger.log_i(self, " Turn player network to bot - ", turn)
	is_bot = turn
	_coll_path.disabled = not turn
	all_data_ready = turn
	
	if turn:
		visible = true
		_timer_despawn_bot.start()
	else:
		_timer_despawn_bot.stop()

var _prev_poses := [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var _tick_prev_pos := 0


func _ready() -> void:
	#visible = false
	visible = true
	
	change_pkg()


func change_pkg() -> void:
	if is_player_in_game:
		print(self, "#######################################################")
		print(self, "#######################################################")
		print(self, "################ PLAYER NETWORK IN GAME ###############")
		print(self, "#######################################################")
		print(self, "#######################################################")
	if not _instance_placeholder :
		print(self, " Change pkg FAIL. instance is NULL")
		return
	Logger.log_i(self, " Change pkg, idx character - ", idx_character)
	#var trans_player : Transform = Transform.IDENTITY
	if _character and is_instance_valid(_character):
		#trans_player = _character.global_transform
		print(self, " Change pkg queue free")
		_character.queue_free()
	
	var path_char : String = CharacterConst.get_character_path(idx_character)
	var character_pkg: PackedScene = ResourceLoader.load(path_char, "", false) as PackedScene
	_character = _instance_placeholder.create_instance(false, character_pkg)
	
	print(self, " Change pkg - ", _character)
	
	if _character :
		#_character.global_transform = trans_player
		_character.rotation = Vector3(0.0, -PI, 0.0)
		_character.scale = Vector3.ONE
		_fcm = _character.fcm

func get_pos_network_player() -> Vector3 :
	if is_bot:
		return _prev_poses[0]
	else:
		return _player_core.global_position

func set_points_path_and_run(points: Array) -> void :
	if not is_bot:
		return
	_path_system_bot.set_points_path_and_run(points)


func set_position(pos: Vector3) -> void :
	_player_core.global_position = pos

func set_rotate_y(angle_y: float) -> void :
	_player_core.rotation = Vector3(0.0, angle_y, 0.0)


func _physics_process(_delta: float) -> void:
	_tick_prev_pos += 1
	if _tick_prev_pos > 5:
		_tick_prev_pos = 0
		for i in range(0, _prev_poses.size() - 1):
			_prev_poses[i] = _prev_poses[i + 1]
		_prev_poses[_prev_poses.size() - 1] = _player_core.global_position


func _process(delta: float) -> void:
	var speed_rot : float = SPEED_ROTATE_BOT if is_bot else SPEED_ROTATE
	
	var pos_pl : Vector3 = _player_core.global_position
	var direct_pl : Vector3 = -_player_core.global_transform.basis.z
	
	var dist_to_targ : float = pos_pl.distance_to(_target_move.global_position)
	var direct_to_targ : Vector3 = pos_pl.direction_to(_target_move.global_position)
	
	var pos_targ : Vector3 = _target_move.global_position
	pos_targ.y = pos_pl.y
	var _dist_to_targ_xz : float = pos_pl.distance_to(pos_targ)
	var direct_to_targ_xz : Vector3 = pos_pl.direction_to(pos_targ)
	
	if dist_to_targ > 10.0:
		_player_core.global_position = _target_move.global_position
		if _fcm:
			var state : int = _fcm.get_current_state()
			if not state == FCM.IDLE and not state == FCM.SIT and not state == FCM.ACTION:
				#print(self, " ####################### IDLE")
				
				_fcm.pop_state()
				pass
	elif dist_to_targ > 0.3:
		var angle : float = direct_pl.angle_to(direct_to_targ_xz)
		var cross : Vector3 = direct_pl.cross(direct_to_targ_xz)
		var angle_offset : float = speed_rot * delta if speed_rot * delta < angle else angle
		if angle > 0.01 and not cross == Vector3.ZERO:
			_player_core.rotate(cross.normalized(), angle_offset)
		
		var move : Vector3 = direct_to_targ * SPEED_LIN * delta
		_player_core.global_position += move
		if _fcm:
			if not _fcm.get_current_state() == FCM.RUN:
				#print(self, " ####################### RUN RUN RUN")
				_fcm.pop_state()
				_fcm.push_state(FCM.RUN)
				pass
	else:
		if _fcm:
			var state : int = _fcm.get_current_state()
			if not state == FCM.IDLE and not state == FCM.SIT and not state == FCM.ACTION:
				#print(self, " ####################### IDLE")
				_fcm.pop_state()
				pass


func _setup_visible() -> void :
	var _current_num_world : int = Singletones.get_GameSaveCloud().game_state.world_num
	#visible = ((not in_game) and (not in_lobby) and (num_world == current_num_world) and is_visible)
	visible = true


func _update_all_data(
			name_pl_new: String,
			idx_char_new: int,
			clothes_new: Array,
			num_world_new: int,
			in_game_new: bool,
			level_achiv: float,
			is_active_sub: bool,
			in_lobby_new: bool,
			is_host_new: bool) -> void :
	#Logger.log_i(self, " Update all data")
	update_name_player(name_pl_new)
	update_idx_character(idx_char_new)
	update_clothes(clothes_new)
	update_num_world(num_world_new)
	update_in_game(in_game_new)
	update_level(level_achiv)
	update_is_active_sub(is_active_sub)
	update_in_lobby(in_lobby_new)
	update_is_host(is_host_new)
	all_data_ready = true

func update_name_player(name_pl_new: String) -> void :
	#Logger.log_i(self, " Update name player - ", name_pl_new)
	name_pl = name_pl_new
	_name_player.set_name(name_pl_new)

func update_idx_character(idx_char_new: int) -> void :
	#Logger.log_i(self, " Update idx character - ", idx_char_new)
	idx_character = idx_char_new
	change_pkg()

func update_clothes(clothes_new: Array) -> void :
	Logger.log_i(self, " Update clothes - ", clothes_new)
	clothes = clothes_new
	if _character and is_instance_valid(_character):
		_character.update_reward_items(clothes)

func get_clothes() -> Array :
	return clothes

func update_num_world(num_world_new: int) -> void :
	#Logger.log_i(self, " Update num world - ", num_world_new)
	num_world = num_world_new
	_setup_visible()

func update_in_game(in_game_in: bool) -> void :
	#Logger.log_i(self, " Update in game - ", in_game_in)
	in_game = in_game_in
	_setup_visible()

func update_level(level_achiv: float) -> void :
	level_achivment = level_achiv
	_name_player.set_level(level_achiv)

func update_is_active_sub(is_active_sub: bool) -> void :
	is_active_subscription = is_active_sub
	_name_player.set_premium(is_active_sub)

func update_in_lobby(in_lobby_in: bool) -> void :
	in_lobby = in_lobby_in
	_setup_visible()

func update_is_host(is_host_in: bool) -> void :
	is_host = is_host_in

func set_pos_target_move(pos: Vector3) -> void :
	_target_move.global_transform.origin = pos

func start_animation(anim: String) -> void :
	if not _character:
		return
	if not is_instance_valid(_character):
		return
	if not _fcm:
		return
	
	var DANCE_1 := 0
	var DANCE_2 := 1
	var VICTORY := 2
	var WAIVING := 3
	
	match anim :
		"Victory" :
			if _fcm.get_current_state() == FCM.SIT :
				_fcm.pop_state()
			_character.set_action_idx(VICTORY)
			_fcm.push_state(FCM.ACTION)
		"Sit" :
			if _fcm.get_current_state() == FCM.ACTION :
				_fcm.pop_state()
			_fcm.push_state(FCM.SIT)
		"Dance" :
			if _fcm.get_current_state() == FCM.SIT :
				_fcm.pop_state()
			_character.set_action_idx(DANCE_1)
			_fcm.push_state(FCM.ACTION)
		"Dance2" :
			if _fcm.get_current_state() == FCM.SIT :
				_fcm.pop_state()
			_character.set_action_idx(DANCE_2)
			_fcm.push_state(FCM.ACTION)
		"Wave" :
			if _fcm.get_current_state() == FCM.SIT :
				_fcm.pop_state()
			_character.set_action_idx(WAIVING)
			_fcm.push_state(FCM.ACTION)
		"Dodge" :
			if _fcm.get_current_state() == FCM.SIT :
				_fcm.pop_state()
			_character.set_action_idx(DANCE_2)
			_fcm.push_state(FCM.ACTION)


func update_network_data(data: Dictionary) -> void :
	if is_bot:
		return
	
	_timer_despawn.start()
	match data[NAME_DATA.TYPE] as int:
		TYPE_DATA.MOVE_PLAYER:
			var pra : PoolRealArray = data[NAME_DATA.MOVE_PLAYER]
			_target_move.global_transform.origin.x = pra[0]
			_target_move.global_transform.origin.y = pra[1]
			_target_move.global_transform.origin.z = pra[2]
		TYPE_DATA.ALL_DATA:
			_update_all_data(
				data[NAME_DATA.NAME_PLAYER] as String,
				data[NAME_DATA.IDX_CHARACTER] as int,
				data[NAME_DATA.CLOTHES] as Array,
				data[NAME_DATA.NUM_WORLD] as int,
				data.get(NAME_DATA.IN_GAME, in_game) as bool,
				data.get(NAME_DATA.LEVEL_ACHIV, 0.2) as float,
				data.get(NAME_DATA.IS_ACTIVE_SUB, is_active_subscription) as bool,
				data.get(NAME_DATA.IN_LOBBY, in_lobby) as bool,
				data.get(NAME_DATA.IS_HOST, is_host) as bool
			)
		TYPE_DATA.NAME_PLAYER:
			update_name_player(data[NAME_DATA.NAME_PLAYER] as String)
		TYPE_DATA.IDX_CHARACTER:
			update_idx_character(data[NAME_DATA.IDX_CHARACTER] as int)
			update_clothes(data[NAME_DATA.CLOTHES] as Array)
		TYPE_DATA.CLOTHES:
			update_clothes(data[NAME_DATA.CLOTHES] as Array)
		TYPE_DATA.NUM_WORLD:
			update_num_world(data[NAME_DATA.NUM_WORLD] as int)
		TYPE_DATA.SMILE:
			_smiles.show_smile_character(data[NAME_DATA.SMILE] as int, idx_character)
		TYPE_DATA.IN_GAME:
			update_in_game(data.get(NAME_DATA.IN_GAME, in_game) as bool)
		TYPE_DATA.ANIMATION:
			start_animation(data.get(NAME_DATA.ANIMATION, "Victory") as String)
		TYPE_DATA.IN_LOBBY:
			update_in_lobby(data.get(NAME_DATA.IN_LOBBY, in_lobby) as bool)



func _on_TimerDespawn_timeout() -> void:
	if is_bot:
		return
	queue_free()


func _on_PathSystemBot_next_point(next_point_pos: Vector3) -> void:
	if not is_bot:
		return
	_target_move.global_position = next_point_pos


func _on_PathSystemBot_last_point() -> void:
	if not is_bot:
		return
	in_game = true
	visible = false
	_player_core.global_position = _prev_poses[0]
	_target_move.global_position = _prev_poses[0]
	_timer_despawn_bot.stop()
	get_tree().create_timer(30.0).connect("timeout", self, "_del_bot")

func _del_bot() -> void :
	queue_free()


var _prev_pos_bot := Vector3.ZERO
func _on_TimerDespawnBot_timeout() -> void:
	if not is_bot:
		_timer_despawn_bot.stop()
		return
	
	var dist : float = _prev_pos_bot.distance_to(_player_core.global_position)
	if dist < 0.5:
		queue_free()
	_prev_pos_bot = _player_core.global_position





