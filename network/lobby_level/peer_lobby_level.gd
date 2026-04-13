extends Node


const NetworkConst := preload("res://content/network/network_const.gd")


onready var _timer_update_date := $TimerUpdateDate


var is_host = false
var node_name := ""
var player_name := ""
var idx_character := 0
var data_ready := false
var data_network := {}

var is_player := false


enum TYPE_DATA {
	UPDATE_PEER
}
enum NAME_DATA {
	TYPE_UPDATE,
	TYPE,
	IDX_OBJ,
	
	IS_HOST,
	NODE_NAME,
	PLAYER_NAME,
	IDX_CHARACTER,
	DATA_READY,
	DATA_NETWORK,
}
var _data_network_update_data := {
	NAME_DATA.TYPE_UPDATE : NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_LOBBY,
	NAME_DATA.TYPE : TYPE_DATA.UPDATE_PEER,
	NAME_DATA.IDX_OBJ : 0,
	NAME_DATA.IS_HOST :false,
	NAME_DATA.NODE_NAME : "",
	NAME_DATA.PLAYER_NAME : "",
	NAME_DATA.IDX_CHARACTER : 0,
	NAME_DATA.DATA_READY : false,
	NAME_DATA.DATA_NETWORK : {},
}


func _ready() -> void:
	if is_player:
		player_name = Singletones.get_GameSaveCloud().game_state.profile.get_name()
		idx_character = Singletones.get_GameSaveCloud().game_state.current_charscter_idx
		data_ready = true
		_timer_update_date.start()
		pass


func update_network_data(data: Dictionary) -> void :
	match data[NAME_DATA.TYPE]:
		TYPE_DATA.UPDATE_PEER:
			is_host = data[NAME_DATA.IS_HOST] as bool
			node_name = data[NAME_DATA.NODE_NAME] as String
			player_name = data[NAME_DATA.PLAYER_NAME] as String
			idx_character = data[NAME_DATA.IDX_CHARACTER] as int
			data_ready = data[NAME_DATA.DATA_READY] as bool
			data_network = data[NAME_DATA.DATA_NETWORK] as Dictionary

func update_data_for_all() -> void :
	if not is_player:
		return
	_data_network_update_data[NAME_DATA.IDX_OBJ] = int(name)
	_data_network_update_data[NAME_DATA.IS_HOST] = is_host
	_data_network_update_data[NAME_DATA.NODE_NAME] = node_name
	_data_network_update_data[NAME_DATA.PLAYER_NAME] = player_name
	_data_network_update_data[NAME_DATA.IDX_CHARACTER] = idx_character
	_data_network_update_data[NAME_DATA.DATA_READY] = data_ready
	_data_network_update_data[NAME_DATA.DATA_NETWORK] = data_network
	
	var key : int = NetworkConst.GLOBAL_TYPE_DATA.OPEN_GAME
	Singletones.get_Network().api.setup_data(key, _data_network_update_data)
	Singletones.get_Network().api.send_data_to_all()

func stop_send_data() -> void :
	_timer_update_date.stop()

func _on_TimerUpdateDate_timeout() -> void:
	if is_player:
		update_data_for_all()
