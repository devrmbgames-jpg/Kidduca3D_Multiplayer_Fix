extends Node

const CarConst := preload("res://content/vehicle/car_const.gd")
const NetworkConst := preload("res://content/network/network_const.gd")

onready var _timer_update_date := $TimerUpdateDate


var is_host = false
var peer_id := ""
var peer_name := ""
var idx_character := 0

var type_car = CarConst.TYPE_CAR.OLD
var level_drive := 0
var level_wheels := 0 
var skin := 0

var track_num := 0

var data_ready := false
var finished_load_race := false

var is_player := false


enum TYPE_DATA {
	UPDATE_DATA
}


enum NAME_DATA {
	
	TYPE,
	IS_HOST,
	PEER_ID,
	PEER_NAME,
	IDX_CHARACTER,
	TYPE_CAR,
	LEVEL_DRIVE,
	LEVEL_WHEELS,
	SKIN,
	TRACK_NUM,
	DATA_READY,
	FINISHED_LOAD_RACE

	
}


var _data_network_update_data := {
	
	NAME_DATA.TYPE : TYPE_DATA.UPDATE_DATA,
	NAME_DATA.IS_HOST :false,
	NAME_DATA.PEER_ID : "",
	NAME_DATA.PEER_NAME : "",
	NAME_DATA.IDX_CHARACTER : 0,
	NAME_DATA.TYPE_CAR : CarConst.TYPE_CAR.OLD,
	NAME_DATA.LEVEL_DRIVE : 0,
	NAME_DATA.LEVEL_WHEELS : 0,
	NAME_DATA.SKIN : 0,
	NAME_DATA.TRACK_NUM : 0,
	NAME_DATA.DATA_READY : false,
	NAME_DATA.FINISHED_LOAD_RACE : false
}


func _ready():
	if is_player:
		is_host = Singletones.get_Network().api.is_host()
		peer_name = Singletones.get_GameSaveCloud().game_state.profile.get_name()
		idx_character = Singletones.get_GameSaveCloud().game_state.current_charscter_idx
		type_car = Singletones.get_GameSaveCloud().game_state.v2_cars_state.get_car_current()
		level_drive = Singletones.get_GameSaveCloud().game_state.v2_cars_state.get_level_drive(type_car)
		level_wheels = Singletones.get_GameSaveCloud().game_state.v2_cars_state.get_level_wheels(type_car)
		skin = Singletones.get_GameSaveCloud().game_state.v2_cars_state.get_skin_current(type_car)
		data_ready = true
		_timer_update_date.start()
	
	#Singletones.get_Network().api.add_object_update(get_path(), self)


func update_network_data(data: Dictionary) -> void :
	match data[NAME_DATA.TYPE]:
		TYPE_DATA.UPDATE_DATA:
			is_host = data[NAME_DATA.IS_HOST] as bool
			peer_id = data[NAME_DATA.PEER_ID] as String
			peer_name = data[NAME_DATA.PEER_NAME] as String
			idx_character = data[NAME_DATA.IDX_CHARACTER] as int
			type_car = data[NAME_DATA.TYPE_CAR] as int
			level_drive = data[NAME_DATA.LEVEL_DRIVE] as int
			level_wheels = data[NAME_DATA.LEVEL_WHEELS] as int
			skin = data[NAME_DATA.SKIN] as int
			track_num = data[NAME_DATA.TRACK_NUM] as int
			data_ready = data[NAME_DATA.DATA_READY] as bool
			finished_load_race = data[NAME_DATA.FINISHED_LOAD_RACE] as bool


func update_data_for_all() -> void :
	if not is_player:
		return

	_data_network_update_data[NAME_DATA.IS_HOST] = Singletones.get_Network().api.is_host()
	_data_network_update_data[NAME_DATA.PEER_ID] = peer_id
	_data_network_update_data[NAME_DATA.PEER_NAME] = peer_name
	_data_network_update_data[NAME_DATA.IDX_CHARACTER] = idx_character
	_data_network_update_data[NAME_DATA.TYPE_CAR] = type_car
	_data_network_update_data[NAME_DATA.LEVEL_DRIVE] = level_drive
	_data_network_update_data[NAME_DATA.LEVEL_WHEELS] = level_wheels
	_data_network_update_data[NAME_DATA.SKIN] = skin
	_data_network_update_data[NAME_DATA.TRACK_NUM] = track_num
	_data_network_update_data[NAME_DATA.DATA_READY] = data_ready
	_data_network_update_data[NAME_DATA.FINISHED_LOAD_RACE] = finished_load_race
	
	var key : int = NetworkConst.GLOBAL_TYPE_DATA.LOBBY
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


#func _on_PeerLobby_tree_exiting():
#	pass #TODO
#	#Singletones.get_Network().api.del_object_update(get_path())
