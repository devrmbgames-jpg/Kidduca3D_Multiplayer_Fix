extends Node

const NetworkConst := preload("res://content/network/network_const.gd")
const CharacterAnimations := preload("res://resources/models/character_v2/character_animation_v3.gd")

const PLAYER = preload("res://content/character/character_v2.gd")
const PLAYER_NETWORK = preload("res://content/character/player_network.gd")


onready var _timer_update_network := $TimerUpdateNetwork


export(bool) var is_player := true setget set_is_player
func set_is_player(turn: bool) -> void :
	is_player = turn
	_setup_players()

export(NodePath) var player_node := NodePath("") setget set_player_node
func set_player_node(path: NodePath) -> void :
	if not is_player:
		_setup_players()
		return
	var node = null
	if has_node(path):
		node = get_node(path)
		if node and node is PLAYER:
			player = node
	_setup_players()

export(NodePath) var player_network_node := NodePath("") setget set_player_network_node
func set_player_network_node(path: NodePath) -> void :
	if is_player:
		_setup_players()
		return
	var node = null
	if has_node(path):
		node = get_node(path)
		if node and node is PLAYER_NETWORK:
			player_network = node
	_setup_players()

export(float, 0.1, 5.0) var time_network_update := 1.0


var player : PLAYER = null setget set_player
func set_player(node: PLAYER) -> void :
	if not is_player or not node:
		_setup_players()
		return
	player = node
	_setup_players()

var player_network : PLAYER_NETWORK = null setget set_player_network
func set_player_network(node: PLAYER_NETWORK) -> void :
	if is_player or not node:
		_setup_players()
		return
	player_network = node
	_setup_players()


# network
enum TYPE_DATA {
	MOVE_PLAYER,
}

enum NAME_DATA {
	TYPE_UPDATE,
	TYPE,
	IDX_OBJ,
	
	MOVE_PLAYER,
}

var _data_network_move_player := {
	NAME_DATA.TYPE_UPDATE : NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_PLAYER_NETWORK, # TODO
	NAME_DATA.TYPE : TYPE_DATA.MOVE_PLAYER,
	NAME_DATA.IDX_OBJ : 0,
	NAME_DATA.MOVE_PLAYER : null
}


func _ready() -> void:
	set_player_node(player_node)
	set_player_network_node(player_network_node)
	
	_timer_update_network.wait_time = time_network_update
	_timer_update_network.start()


func _setup_players() -> void :
	if is_player:
		player_network = null
	else:
		player = null


func update_network_data(data: Dictionary) -> void :
	if is_player:
		return
	if not player_network or not is_instance_valid(player_network):
		return
	
	match data[NAME_DATA.TYPE] as int:
		TYPE_DATA.MOVE_PLAYER:
			var pra : PoolRealArray = data[NAME_DATA.MOVE_PLAYER]
			var pos_target_move := Vector3.ZERO
			pos_target_move.x = pra[0]
			pos_target_move.y = pra[1]
			pos_target_move.z = pra[2]
			player_network.set_pos_target_move(pos_target_move)

func _send_network_data() -> void :
	if not is_player:
		return
	if not player or not is_instance_valid(player):
		return
	
	var character : CharacterAnimations = player.get_character()
	
	if not character:
		return
	if not is_instance_valid(character):
		return
	if not Singletones.get_Network().api:
		return
	
	var step := 0.01
	_data_network_move_player[NAME_DATA.MOVE_PLAYER] = PoolRealArray([
		stepify(character.global_transform.origin.x, step),
		stepify(character.global_transform.origin.y, step),
		stepify(character.global_transform.origin.z, step),
	])
	_data_network_move_player[NAME_DATA.IDX_OBJ] = int(player.name)
	var key : int = NetworkConst.GLOBAL_TYPE_DATA.OPEN_GAME # TODO
	Singletones.get_Network().api.setup_data(key, _data_network_move_player)
	Singletones.get_Network().api.send_data_to_all()
	pass


func _on_TimerUpdateNetwork_timeout() -> void:
	_send_network_data()
