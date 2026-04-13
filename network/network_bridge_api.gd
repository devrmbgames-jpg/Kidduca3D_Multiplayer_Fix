extends Node
#class_name NetworkBridgeAPI

var NEED_PLAYERS_COUNT = 10
var need_peers_count_in_current_step := 0
var step_added_peers := 2

const TIME_FIND_START_SINGLE_GAME := 40

signal connect_to_lobby()
signal update_player_status(id, nickname, icon, is_friend, status)
signal rematching()
signal timeout_start_single_game()
signal host_changed(new_host_id, old_host_id)

var _objects_update := {}

const PACKED_TYPE_DATA := "data"
const PACKED_TYPE_HELLO := "hello"
const PACKED_TYPE_START_LOBBY := "start"

const TAG_TYPE := "type"
const TAG_KEY := "key"
const TAG_DATA := "data"
const TAG_SENDER := "sender"

var _data := {
	TAG_TYPE : PACKED_TYPE_DATA,
	TAG_KEY : "",
	TAG_DATA : {},
	TAG_SENDER : ""
}

var _is_in_lobby := false

var _timer_start_single_game := Timer.new()


func _ready():
	_timer_start_single_game.one_shot = true
	_timer_start_single_game.connect("timeout", self, "_TimerStartSingleGame_timeout")
	add_child(_timer_start_single_game)
	_timer_start_single_game.stop()
	
	Singletones.get_Network().lobby.connect("lobby_ready_for_race", self, "_NetworkLobby_lobby_ready_for_race")
	
	ready_post()

func ready_post() -> void : # virtual
	pass

func _to_string() -> String:
	return "[NetworkBridgeAPI]"

func add_object_update(_key: String, _obj) -> void :
	if Singletones.get_GlobalGame().is_has_multiplayer:
		pass #TODO print(self, " add object < ", _key, " >  update from - ", _obj)
		_objects_update[_key] = _obj

func del_object_update(_key: String) -> bool :
	if Singletones.get_GlobalGame().is_has_multiplayer:
		pass #TODO print(self, " del object < ", _key, " >")
		return _objects_update.erase(_key)
	else:
		return false

func is_host() -> bool :
	return false

func is_in_lobby() -> bool :
	return _is_in_lobby

func rematch() -> void :
	pass

func create_lobby() -> bool :
	return false

func create_lobby_from_friend() -> bool :
	return false

func close_connect() -> void :
	pass


func connect_to_lobby_friend(_friend: String) -> bool :
	return false

func connect_to_loby() -> bool :
	return false

func leave_from_lobby() -> bool :
	return false


func invite_friend(_friend: String) -> bool :
	return false

func connect_from_invite():
	pass


func get_expected_player_count() -> int :
	return -1

func get_peer_id() -> String :
	return ""

func get_peers_id() -> Array :
	return []

func get_name() -> String :
	return ""

func get_names_players() -> Array :
	return []

func get_icon_player_from_peer_id(_peer_id: String) -> Texture :
	return null

func poll() -> bool :
	return false


func _update_data(_data_in: Dictionary) -> void :
	pass #TODO print(self, " update data")
	pass #TODO print(self, "  |-- data:", _data_in)
	if not Singletones.get_GlobalGame().is_has_multiplayer:
		return
	
	if _objects_update.has(_data_in.key):
		if is_instance_valid(_objects_update[_data_in.key]):
			if _objects_update[_data_in.key].has_method("update_network_data"):
				_objects_update[_data_in.key].update_network_data(_data_in.data)
			else :
				print(self, " object - ", _data_in.key, " method is not found")
		else :
			print(self, " object - ", _data_in.key, " is invalid!")
	else :
		print(self, " object - ", _data_in.key, " not found!")

func setup_data(_key: String, _data_in: Dictionary) -> void :
	if not Singletones.get_GlobalGame().is_has_multiplayer:
		return
	
	_data.key = _key
	_data.data = _data_in
	_data.sender = get_peer_id()

func send_data_to_peer(_peer_id) -> bool :
	return false

func send_data_to_all() -> bool :
	return false


func get_peer() -> NetworkedMultiplayerPeer :
	return null


func _TimerStartSingleGame_timeout() -> void :
	print(self, " timeout timer start single game")
	
	if Singletones.get_Network().lobby.get_peers_count() < 2:
		print(self, " leave from lobby")
		leave_from_lobby()
	
		yield(get_tree().create_timer(1.5), "timeout")
	
		print(self, " emit signal timeout_start_single_game")
		emit_signal("timeout_start_single_game")


func NetworkLobby_lobby_ready_for_race_post() -> void : # virtual
	pass

func _NetworkLobby_lobby_ready_for_race() -> void :
	print(self, " stop timer start single game")
	_timer_start_single_game.stop()
	NetworkLobby_lobby_ready_for_race_post()
	


