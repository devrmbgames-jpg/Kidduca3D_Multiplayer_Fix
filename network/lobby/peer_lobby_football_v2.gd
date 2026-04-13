extends Node

const NetworkConst := preload("res://content/network/network_const.gd")
const GameState := preload("res://content/game_save_cloud/game_state.gd")

onready var _timer_update_date := $TimerUpdateDate


var is_host = false
var peer_id := ""
var peer_name := ""

var idx_character := 0

var id_team := 0

var data_ready := false
var finished_load_football := false

var is_player := false

enum TYPE_TEAM {
	RED,
	BLUE,
	NONE
}

enum TYPE_DATA {
	UPDATE_DATA
}


enum NAME_DATA {
	
	TYPE,
	IS_HOST,
	PEER_ID,
	PEER_NAME,
	IDX_CHARACTER,
	DATA_READY,
	FINISHED_LOAD_FOOTBALL,

	TEAM,
	
}


var _data_network_update_data := {
	
	NAME_DATA.TYPE : TYPE_DATA.UPDATE_DATA,
	NAME_DATA.IS_HOST : false,
	NAME_DATA.PEER_ID : "",
	NAME_DATA.PEER_NAME : "",
	NAME_DATA.IDX_CHARACTER : 0,
	NAME_DATA.TEAM : 0,
	NAME_DATA.DATA_READY : false,
	NAME_DATA.FINISHED_LOAD_FOOTBALL : false
}


func _ready():
	if is_player:
		var game_state: GameState = Singletones.get_GameSaveCloud().game_state as GameState
		
		is_host = Singletones.get_Network().api.is_host()
		peer_id = Singletones.get_Network().api.get_peer_id()
		peer_name = game_state.profile.get_name()
		idx_character = game_state.current_charscter_idx
		id_team = game_state.id_team
		data_ready = true
		_timer_update_date.start()


func update_network_data(data: Dictionary) -> void :
	match data[NAME_DATA.TYPE]:
		TYPE_DATA.UPDATE_DATA:
			is_host = data[NAME_DATA.IS_HOST] as bool
			peer_id = data[NAME_DATA.PEER_ID] as String
			peer_name = data[NAME_DATA.PEER_NAME] as String
			idx_character = data[NAME_DATA.IDX_CHARACTER] as int
			id_team = data[NAME_DATA.TEAM] as int
			data_ready = data[NAME_DATA.DATA_READY] as bool
			finished_load_football = data[NAME_DATA.FINISHED_LOAD_FOOTBALL] as bool


func update_data_for_all() -> void :
	if not is_player:
		return

	_data_network_update_data[NAME_DATA.IS_HOST] = Singletones.get_Network().api.is_host()
	_data_network_update_data[NAME_DATA.PEER_ID] = peer_id
	_data_network_update_data[NAME_DATA.PEER_NAME] = peer_name
	_data_network_update_data[NAME_DATA.IDX_CHARACTER] = idx_character
	_data_network_update_data[NAME_DATA.TEAM] = id_team
	_data_network_update_data[NAME_DATA.DATA_READY] = data_ready
	_data_network_update_data[NAME_DATA.FINISHED_LOAD_FOOTBALL] = finished_load_football
	
	# Use LOBBY_FOOTBALL op-code so this doesn't pollute the global LOBBY channel
	var key : int = NetworkConst.GLOBAL_TYPE_DATA.LOBBY_FOOTBALL
	Singletones.get_Network().api.setup_data(key, _data_network_update_data)
	Singletones.get_Network().api.send_data_to_all()


func need_update_data() -> void :
	if not is_player:
		data_ready = false


func stop_send_data() -> void :
	_timer_update_date.stop()


func _on_TimerUpdateDate_timeout():
	if is_player:
		update_data_for_all()
