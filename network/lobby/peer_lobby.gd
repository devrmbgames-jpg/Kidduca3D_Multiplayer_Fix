extends Node

const CarConst := preload("res://content/vehicle/car_const.gd")

onready var _timer_update_date := $TimerUpdateDate

var token := ""
var peer_id := ""
var peer_name := ""
var idx_character := 0
var is_host := false

var type_car = CarConst.TYPE_CAR.OLD
var level_drive := 0
var level_wheels := 0 
var skin := 0

var track_num := 0

var data_ready := false
var finished_load_race := false

var icon_player : Texture = null

var is_player := false

enum TYPE_DATA {
	UPDATE_DATA
}
var _data_network_update_data := {
	"type" : TYPE_DATA.UPDATE_DATA,
	"token" : "",
	"peer_id" : "",
	"peer_name" : "",
	"idx_character" : 0,
	"is_host" : false,
	"type_car" : CarConst.TYPE_CAR.OLD,
	"level_drive" : 0,
	"level_wheels" : 0,
	"skin" : 0,
	"track_num" : 0,
	"data_ready" : false,
	"finished_load_race" : false
}


func _ready():
	if is_player:
		token = Singletones.get_Network().token
		#peer_name = Singletones.get_Network().api.get_name()
		peer_name = Singletones.get_GameSaveCloud().game_state.profile.get_name()
		idx_character = Singletones.get_GameSaveCloud().game_state.current_charscter_idx
		type_car = Singletones.get_GameSaveCloud().game_state.v2_cars_state.get_car_current()
		level_drive = Singletones.get_GameSaveCloud().game_state.v2_cars_state.get_level_drive(type_car)
		level_wheels = Singletones.get_GameSaveCloud().game_state.v2_cars_state.get_level_wheels(type_car)
		skin = Singletones.get_GameSaveCloud().game_state.v2_cars_state.get_skin_current(type_car)
		data_ready = true
		_timer_update_date.start()
	
	Singletones.get_Network().api.add_object_update(get_path(), self)

func update_network_data(data: Dictionary) -> void :
	match data.type:
		TYPE_DATA.UPDATE_DATA:
			token = data["token"]
			peer_id = data["peer_id"]
			peer_name = data["peer_name"]
			idx_character = data["idx_character"]
			is_host = data["is_host"]
			type_car = data["type_car"]
			level_drive = data["level_drive"]
			level_wheels = data["level_wheels"]
			skin = data["skin"]
			track_num = data["track_num"]
			data_ready = data["data_ready"]
			finished_load_race = data["finished_load_race"]

func update_data_for_all() -> void :
	if not is_player:
		return
	
	_data_network_update_data["token"] = token
	_data_network_update_data["peer_id"] = peer_id
	_data_network_update_data["peer_name"] = peer_name
	_data_network_update_data["idx_character"] = idx_character
	_data_network_update_data["is_host"] = is_host
	_data_network_update_data["type_car"] = type_car
	_data_network_update_data["level_drive"] = level_drive
	_data_network_update_data["level_wheels"] = level_wheels
	_data_network_update_data["skin"] = skin
	_data_network_update_data["track_num"] = track_num
	_data_network_update_data["data_ready"] = data_ready
	_data_network_update_data["finished_load_race"] = finished_load_race
	var key = get_path()
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


func _on_PeerLobby_tree_exiting():
	pass #TODO
	#Singletones.get_Network().api.del_object_update(get_path())
