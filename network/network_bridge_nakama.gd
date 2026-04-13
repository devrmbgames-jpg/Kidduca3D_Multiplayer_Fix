extends Node

signal timeout_start_single_game()
signal timeout_start_football_single_game()

signal exit_from_error()

signal start_matchmaker()
signal start_matchmaker_fooball()

signal host_changed(new_host_id, old_host_id)

const NetworkConst := preload("res://content/network/network_const.gd")

const MAX_PLAYERS_COUNT = 10
const MIN_PLAYERS_COUNT = 2

const MAX_PLAYER_FOOTBALL_COUNT := 8
const MIN_PLAYER_FOOTBALL_COUNT  := 2

const MAX_PLAYERS_COUNT_OG = 15
const MIN_PLAYERS_COUNT_OG = 1

const TIME_FIND_START_SINGLE_GAME := 40


const TAG_KEY := "key"
const TAG_DATA := "data"

enum TYPE_MATCH {
	CAR_GAMES,
	OPEN_GAME,
	NONE,
	FOOTBALL,
}
var _type_match : int = TYPE_MATCH.NONE

var _data := {
	TAG_KEY : 0,
	TAG_DATA : {},
}


var _objects_update := {}
var _is_in_lobby := false
var _timer_start_single_game := Timer.new()

var is_loading_race := false
var is_loading_football := false

# nakama
const SCHEME := "http"
#const HOST = "127.0.0.1"
const HOST = "gameserver.educational-games.online"
const PORT = 7350
const SERVER_KEY = "defaultkey"

var _client_nakama : NakamaClient = null
var _multiplayer_bridge : NakamaMultiplayerBridge = null
var _socket : NakamaSocket = null
var _session : NakamaSession = null
var _ticket_str : String = ""
var _is_leaving_from_lobby := false
var _is_leaving_from_open_game := false
var _is_connection_closing := false
var _is_connection_to_server := false

var _current_match_id := ""

var _connected_opponents = {}
var _host_id := ""
var _peer_id := ""

var time_receive_data := 0
var force_leave_open_game := false


func _ready() -> void:
	_timer_start_single_game.wait_time = TIME_FIND_START_SINGLE_GAME
	_timer_start_single_game.one_shot = true
	_timer_start_single_game.connect("timeout", self, "_TimerStartSingleGame_timeout")
	add_child(_timer_start_single_game)
	_timer_start_single_game.stop()



############################ API ##########################################

func _connect_to_server_nakama() -> bool :
	if not Singletones.get_GlobalGame().is_has_multiplayer:
		Logger.log_i(self, " Multiplayer is disabled")
		emit_signal("exit_from_error")
		yield(get_tree(), "idle_frame")
		return false
	
	_is_connection_to_server = true
	
	Logger.log_i(self, " Connect to server")
	
	if not _client_nakama or not is_instance_valid(_client_nakama):
		_client_nakama = Nakama.create_client(SERVER_KEY, HOST, PORT, SCHEME)
		Logger.log_i(self, " Create client %s" % _client_nakama)
	
	var deviceid = "9d991ec0-007a-11eb-9724-806e6f6e" \
		+ str(randi() % 9) + str(randi() % 9) \
		+ str(randi() % 9) + str(randi() % 9) # fot test on one pc
	#var deviceid = OS.get_unique_id()
	Logger.log_i(self, " device id %s" % deviceid)
	
	
	if (not _session or not is_instance_valid(_session)) \
			or (_session and (_session.is_exception() or _session.is_expired())):
		_session = yield(_client_nakama.authenticate_device_async(deviceid), "completed")
		if not is_inside_tree() or is_queued_for_deletion() :
			return false
		
		if _session.is_exception():
			Logger.log_i(self, " An error occurred: %s" % _session)
			leave_from_lobby()
			emit_signal("exit_from_error")
			_is_connection_to_server = false
			yield(get_tree(), "idle_frame")
			return false
	Logger.log_i(self, " Successfully authenticated: %s" % _session)
	
	if not _socket or not is_instance_valid(_socket):
		_socket = Nakama.create_socket_from(_client_nakama)
		Logger.log_i(self, " Socket created")
	if not _socket.is_connected_to_host():
		yield(_socket.connect_async(_session), "completed")
		if not is_inside_tree() or is_queued_for_deletion() : return false
		
		Logger.log_i(self, " Socket connect async")
	_socket_connect_signals()
	Logger.log_i(self, " Socket is done")
	
	_multiplayer_bridge = NakamaMultiplayerBridge.new(_socket)
	_mp_bridge_connect_signals()
	get_tree().set_network_peer(_multiplayer_bridge.multiplayer_peer)
	Logger.log_i(self, " Multiplayer Bridge is done")
	
	Logger.log_i(self, " Connect to server success")
	_is_connection_to_server = false
	yield(get_tree(), "idle_frame")
	if not is_inside_tree() or is_queued_for_deletion() : return false
	
	return true


func get_matches() -> NakamaAPI.ApiMatchList :
	Logger.log_i(self, " Get matches")
	if not is_connected_to_server():
		Logger.log_i(self, "  |-- Get matches FAIL. Is not connected to server")
		return null
	
	var matches : NakamaAPI.ApiMatchList = yield(_client_nakama.list_matches_async(
		_session,
		0,
		100,
		100,
		false,
		"",
		""
	), "completed")
	if not is_inside_tree() or is_queued_for_deletion() : 
		return null
	
	Logger.log_i(self, "  |-- Get matches success")
	return matches

func is_connected_to_server() -> bool :
	Logger.log_i(self, " Check connection")
	if not _client_nakama:
		Logger.log_i(self, "  |-- Client Nakama is NULL")
		return false
	if not is_instance_valid(_client_nakama):
		_client_nakama = null
		Logger.log_i(self, "  |-- Client Nakama is NOT instance")
		return false
	
	if not _session:
		Logger.log_i(self, "  |-- Session is NULL")
		return false
	if not is_instance_valid(_session):
		_session = null
		Logger.log_i(self, "  |-- Session is NOT instance")
		return false
	if _session.is_exception() or _session.is_expired():
		Logger.log_i(self, "  |-- Session is exception or expired")
		return false
	
	if not _socket:
		Logger.log_i(self, "  |-- Socket is NULL")
		return false
	if not is_instance_valid(_socket):
		Logger.log_i(self, "  |-- Socket is NOT instance")
		_socket = null
		return false
	if not _socket.is_connected_to_host():
		Logger.log_i(self, "  |-- Socket is NOT connected to host")
		return false
	
	if not _multiplayer_bridge:
		Logger.log_i(self, "  |-- Multiplayer bridge is NULL")
		return false
	if not is_instance_valid(_multiplayer_bridge):
		Logger.log_i(self, "  |-- Multiplayer bridge is NOT instance")
		_multiplayer_bridge = null
		return false
	
	Logger.log_i(self, "  |-- Connection is success")
	return true

func check_connection_and_connect_to_open_game() -> void :
	Logger.log_i(self, " Check connection and connect to open game")
	
	
	if force_leave_open_game :
		Logger.log_i(self, "   |- Connection cancel, is force_leave_open_game==true ...")
		return
	
	if not is_connected_to_server():
		Logger.log_i(self, "  |-- Connection FAIL. Connect to open game")
		connect_to_open_game()
	else:
		Logger.log_i(self, "  |-- Connection success")


func connect_to_open_game() -> bool :
	
	
	if not Singletones.get_GlobalGame().is_has_multiplayer:
		Logger.log_i(self, " Multiplayer is disabled")
		emit_signal("exit_from_error")
		yield(get_tree(), "idle_frame")
		return false
	
	Logger.log_i(self, " Connect to open game")
	
	if force_leave_open_game :
		Logger.log_i(self, "   |- Connection cancel, is force_leave_open_game==true ...")
		return
	
	_type_match = TYPE_MATCH.OPEN_GAME
	
	leave_from_open_game()
	while _is_leaving_from_lobby or _is_leaving_from_open_game or _is_connection_closing:
		yield(get_tree(), "idle_frame")
		if not is_inside_tree() or is_queued_for_deletion() : return false
	
	_is_connection_to_server = false
	_connect_to_server_nakama()
	while _is_connection_to_server:
		yield(get_tree(), "idle_frame")
		if not is_inside_tree() or is_queued_for_deletion() : return false
	
	Logger.log_i(self, " Connect to open game. Check socket connected to server")
	if not is_connected_to_server():
		Logger.log_w(self, " NOT Connect to open game. Is not connected to server")
		yield(get_tree(), "idle_frame")
		return false
	
	var matches : NakamaAPI.ApiMatchList = yield(_client_nakama.list_matches_async(
		_session,
		0,
		100,
		100,
		false,
		"",
		""
	), "completed")
	print(self, " Matches ", matches)
	
	print(self, "List matches:")
	if matches:
		for m in matches.matches:
			print(self, "%s: %s players", m.match_id, m.size)
	
	# попытка вернуться в текущий матч
	if matches:
		for m in matches.matches:
			if m.match_id == _current_match_id:
				_multiplayer_bridge.join_match(_current_match_id)
				Logger.log_i(self, " Join current match ", _current_match_id)
				return true
	
	# поиск матчей
	var m_id := ""
	if matches:
		for m in matches.matches:
			if m.size < MAX_PLAYERS_COUNT_OG:
				m_id = m.match_id
				break
	
	if m_id.empty():
		yield(_multiplayer_bridge.create_match(), "completed")
		if not is_inside_tree() or is_queued_for_deletion() : return false
		Logger.log_i(self, " Create match")
		_current_match_id = _multiplayer_bridge.match_id
	else:
		_multiplayer_bridge.join_match(m_id)
		Logger.log_i(self, " Join match ", m_id)
		_current_match_id = m_id
	
	yield(get_tree(), "idle_frame")
	return true


func connect_to_loby() -> bool :
	if not Singletones.get_GlobalGame().is_has_multiplayer:
		Logger.log_i(self, " Multiplayer is disabled")
		emit_signal("exit_from_error")
		return false
	
#	print("#######################################################################################")
#	print("#######################################################################################")
#	print("############################### CONNECT TO LOBBY ######################################")
#	print("#######################################################################################")
#	print("#######################################################################################")
	
	Logger.log_i(self, " Connect to lobby")
	
	_type_match = TYPE_MATCH.CAR_GAMES
	
	leave_from_lobby()
	while _is_leaving_from_lobby or _is_leaving_from_open_game or _is_connection_closing:
		yield(get_tree(), "idle_frame")
		if not is_inside_tree() or is_queued_for_deletion() : return false
	
	Logger.log_i(self, " START timer start single game %s sec" % _timer_start_single_game.wait_time)
	_timer_start_single_game.start()
	
	_is_connection_to_server = false
	_connect_to_server_nakama()
	while _is_connection_to_server:
		yield(get_tree(), "idle_frame")
		if not is_inside_tree() or is_queued_for_deletion() : return false
	
	Logger.log_i(self, " Connect to open game. Check socket connected to server")
	if not is_connected_to_server():
		Logger.log_w(self, " NOT Connect to lobby. Is not connected to server")
		return
	
	
	var query := "+properties.type_game:==%d" % int(TYPE_MATCH.CAR_GAMES)
	var prop_num := {
		"type_game" : int(TYPE_MATCH.CAR_GAMES)
	}
	
	var ticket = yield(_socket.add_matchmaker_async(query, MIN_PLAYERS_COUNT, MAX_PLAYERS_COUNT, {}, prop_num), "completed")
	if not is_inside_tree() or is_queued_for_deletion() : return false
	
	if ticket.is_exception():
		Logger.log_i(self, " Error joining matchmaking pool: %s" % ticket.get_exception().message)
		leave_from_lobby()
		emit_signal("exit_from_error")
		return false
	_ticket_str = ticket.ticket
	Logger.log_i(self, " start_matchmaking. ticket %s" % ticket)
	_multiplayer_bridge.start_matchmaking(ticket)
	
	var account = yield(_client_nakama.get_account_async(_session), "completed")
	if not is_inside_tree() or is_queued_for_deletion() : return false
	
	_peer_id = str(account.user.id)
	Logger.log_i(self, " Self Peer id %s" % _peer_id)
	
	emit_signal("start_matchmaker")
	return true



func connect_to_football_loby() -> bool :
	if not Singletones.get_GlobalGame().is_has_multiplayer:
		Logger.log_i(self, " Multiplayer is disabled")
		emit_signal("exit_from_error")
		return false
	
#	print("#######################################################################################")
#	print("#######################################################################################")
#	print("############################### CONNECT TO FOOTBALL LOBBY ##############################")
#	print("#######################################################################################")
#	print("#######################################################################################")
	
	Logger.log_i(self, " Connect to football lobby")
	
	_type_match = TYPE_MATCH.FOOTBALL
	
	leave_from_lobby()
	while _is_leaving_from_lobby or _is_leaving_from_open_game or _is_connection_closing:
		yield(get_tree(), "idle_frame")
		if not is_inside_tree() or is_queued_for_deletion() : return false
	
	Logger.log_i(self, " START timer start single game %s sec" % _timer_start_single_game.wait_time)
	_timer_start_single_game.start()
	
	_is_connection_to_server = false
	_connect_to_server_nakama()
	while _is_connection_to_server:
		yield(get_tree(), "idle_frame")
		if not is_inside_tree() or is_queued_for_deletion() : return false
	
	Logger.log_i(self, " Connect to open game. Check socket connected to server")
	if not is_connected_to_server():
		Logger.log_w(self, " NOT Connect to lobby. Is not connected to server")
		return
	
	var query := "+properties.type_game:==%d" % int(TYPE_MATCH.FOOTBALL)
	var prop_num := {
		"type_game" : int(TYPE_MATCH.FOOTBALL)
	}
	
	var ticket = yield(_socket.add_matchmaker_async(query, MIN_PLAYER_FOOTBALL_COUNT, MAX_PLAYER_FOOTBALL_COUNT, {}, prop_num), "completed")
	if not is_inside_tree() or is_queued_for_deletion() : return false
	
	if ticket.is_exception():
		Logger.log_i(self, " Error joining matchmaking pool: %s" % ticket.get_exception().message)
		leave_from_lobby()
		emit_signal("exit_from_error")
		return false
	_ticket_str = ticket.ticket
	Logger.log_i(self, " start_matchmaking. ticket %s" % ticket)
	_multiplayer_bridge.start_matchmaking(ticket)
	
	var account = yield(_client_nakama.get_account_async(_session), "completed")
	if not is_inside_tree() or is_queued_for_deletion() : return false
	
	_peer_id = str(account.user.id)
	Logger.log_i(self, " Self Peer id %s" % _peer_id)
	
	emit_signal("start_matchmaker_fooball")
	return true


func leave_from_lobby() -> bool :
	if not Singletones.get_GlobalGame().is_has_multiplayer:
		return false
	
	Logger.log_i(self, " Leave from lobby")
	
	Logger.log_i(self, " STOP timer start single game")
	_timer_start_single_game.stop()
	
	_is_leaving_from_lobby = true
	_is_in_lobby = false
	
	if Singletones.get_Network().lobby :
		Singletones.get_Network().lobby.call_deferred("leave_from_lobby")
	
	if Singletones.get_Network().lobby_football :
		Singletones.get_Network().lobby_football.call_deferred("leave_from_lobby")
	
	
	if _multiplayer_bridge:
		_multiplayer_bridge.leave()
		_mp_bridge_disconect_signals()
	_multiplayer_bridge = null
	get_tree().set_network_peer(null)
	Logger.log_i(self, " Leave from MP Bridge")
	
	if _socket and not _ticket_str.empty() and _socket.is_connected_to_host():
		Logger.log_i(self, " Removing matchmaker socket")
		yield(_socket.remove_matchmaker_async(_ticket_str), 'completed')
		if not is_inside_tree() or is_queued_for_deletion() : return false
		_socket_disconect_signals()
		Logger.log_i(self, " Remove matchmaker socket")
	else:
		Logger.log_i(self, " NOT Remove matchmaker socket")
	
	_connected_opponents = {}
	_host_id = ""
	_peer_id = ""
	is_loading_race = false
	
	_is_leaving_from_lobby = false
	
	_type_match = TYPE_MATCH.NONE
	Logger.log_i(self, " Leave from lobby completed")
	return true

func leave_from_open_game() -> bool :
	if not Singletones.get_GlobalGame().is_has_multiplayer:
		return false
	
	Logger.log_i(self, " Leave from open game")
	
	_is_leaving_from_open_game = true
	
	if _multiplayer_bridge:
		_multiplayer_bridge.leave()
		_mp_bridge_disconect_signals()
	_multiplayer_bridge = null
	get_tree().set_network_peer(null)
	Logger.log_i(self, " Leave from MP Bridge")
	
	if _socket and _socket.is_connected_to_host():
		Logger.log_i(self, " Removing match socket")
		_socket_disconect_signals()
		_socket = null
		Logger.log_i(self, " Remove match socket")
	else:
		Logger.log_i(self, " NOT Remove match socket")
	
	_is_leaving_from_open_game = false
	
	_type_match = TYPE_MATCH.NONE
	Logger.log_i(self, " Leave from open game completed")
	return true


# при выходе из игры
func close_connection() -> void :
	Logger.log_i(self, " Socket close")
	_is_connection_closing = true
	leave_from_lobby()
	leave_from_open_game()
	while _is_leaving_from_lobby or _is_leaving_from_open_game:
		yield(get_tree(), "idle_frame")
		if not is_inside_tree() or is_queued_for_deletion() : return false
	
	if _socket:
		_socket.close()
		_socket = null
		Logger.log_i(self, " Socket close completed")
	else:
		Logger.log_i(self, " NOT Socket close. Socket is null")
	_is_connection_closing = false


func get_peer_id() -> String :
	return _peer_id

func get_peers_id() -> Array :
	return _connected_opponents.keys()

func get_name() -> String :
	return _peer_id

func get_names_players() -> Array :
	return _connected_opponents.keys()

func is_host() -> bool :
	#print(self, " is host. peer id %s   host id %s" % [_peer_id, _host_id])
	return _peer_id == _host_id

func is_in_lobby() -> bool :
	return _is_in_lobby


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

func setup_data(_key: int, _data_in: Dictionary) -> void :
	if not Singletones.get_GlobalGame().is_has_multiplayer:
		return
	
	_data.key = _key
	_data.data = _data_in

func send_data_to_all() -> bool :
	if not Singletones.get_GlobalGame().is_has_multiplayer:
		return false
	if _type_match == TYPE_MATCH.CAR_GAMES and not Singletones.get_RaceSetup().type_game == Singletones.get_RaceSetup().TYPE_GAME.ONLINE_GAME:
		return false
	
	if is_loading_race:
		return false
	
	if not _multiplayer_bridge:
		#Logger.log_w(self, " ERROE Send data. MP Bridge is null")
		return false
	
	if not _socket: 
		#Logger.log_w(self, " ERROR Send data. Socket is null")
		return false
	
	if not _session:
		#Logger.log_w(self, " ERROR Send data. Session is null")
		return false
	
	if not _socket.is_connected_to_host():
		#Logger.log_w(self, " ERROR Send data. Socket is disconnect to host")
		return false
	
	if not _session.is_valid():
		#Logger.log_w(self, " ERROR Send data. Session is not valid")
		return false
	
	var match_id = _multiplayer_bridge.match_id
	var op_code = _data[TAG_KEY]
	#var data_json = JSON.print(_data)
	#_socket.send_match_state_async(match_id, op_code, data_json)
	
	var data_bytes : PoolByteArray = var2bytes(_data[TAG_DATA])
#	var size := data_bytes.size()
#	var data_bytes_comp : PoolByteArray = data_bytes.compress(2)
#	data_bytes_comp.append(size)
#	print(self, " Size compres send data binary ", data_bytes_comp.size())
	
	_socket.send_match_state_raw_async(match_id, op_code, data_bytes)
	return true




########################### PRIVATE FUNC #################################

func _to_string() -> String:
	return "[NetworkBridgeNakama]"

func _socket_connect_signals() -> void :
	Logger.log_i(self, " Socket connect signals")
	if not _socket or not is_instance_valid(_socket):
		Logger.log_i(self, " WRONG Socket connect signals. Socket is null")
		return
	if _socket and not _socket.is_connected("connected", self, "_on_socket_connected"):
		_socket.connect("connected", self, "_on_socket_connected")
	if _socket and  not _socket.is_connected("closed", self, "_on_socket_closed"):
		_socket.connect("closed", self, "_on_socket_closed")
	if _socket and  not _socket.is_connected("received_error", self, "_on_socket_error"):
		_socket.connect("received_error", self, "_on_socket_error")
	if _socket and  not _socket.is_connected("received_matchmaker_matched", self, "_on_matchmaker_matched"):
		_socket.connect("received_matchmaker_matched", self, "_on_matchmaker_matched")
	if _socket and  not _socket.is_connected("received_match_presence", self, "_on_match_presence"):
		_socket.connect("received_match_presence", self, "_on_match_presence")
	if _socket and  not _socket.is_connected("received_match_state", self, "_on_match_state"):
		_socket.connect("received_match_state", self, "_on_match_state")

func _socket_disconect_signals() -> void :
	Logger.log_i(self, " Socket disconnect signals")
	if not _socket or not is_instance_valid(_socket):
		Logger.log_i(self, " WRONG Socket disconnect signals. Socket is null")
		return
	if _socket.is_connected("connected", self, "_on_socket_connected"):
		_socket.disconnect("connected", self, "_on_socket_connected")
	if _socket.is_connected("closed", self, "_on_socket_closed"):
		_socket.disconnect("closed", self, "_on_socket_closed")
	if _socket.is_connected("received_error", self, "_on_socket_error"):
		_socket.disconnect("received_error", self, "_on_socket_error")
	if _socket.is_connected("received_matchmaker_matched", self, "_on_matchmaker_matched"):
		_socket.disconnect("received_matchmaker_matched", self, "_on_matchmaker_matched")
	if _socket.is_connected("received_match_presence", self, "_on_match_presence"):
		_socket.disconnect("received_match_presence", self, "_on_match_presence")
	if _socket.is_connected("received_match_state", self, "_on_match_state"):
		_socket.disconnect("received_match_state", self, "_on_match_state")

func _mp_bridge_connect_signals() -> void :
	Logger.log_i(self, " MP Bridge connect signals")
	if not _multiplayer_bridge or not is_instance_valid(_multiplayer_bridge):
		Logger.log_i(self, " WRONG MP Bridge connect signals. MP Bridge is null")
		return
	if not _multiplayer_bridge.is_connected("match_join_error", self, "_on_match_join_error"):
		_multiplayer_bridge.connect("match_join_error", self, "_on_match_join_error")
	if not _multiplayer_bridge.is_connected("match_joined", self, "_on_match_join"):
		_multiplayer_bridge.connect("match_joined", self, "_on_match_join")

func _mp_bridge_disconect_signals() -> void :
	Logger.log_i(self, " MP Bridge disconnect signals")
	if not _multiplayer_bridge or not is_instance_valid(_multiplayer_bridge):
		Logger.log_i(self, " WRONG MP Bridge disconnect signals. MP Bridge is null")
		return
	if _multiplayer_bridge.is_connected("match_join_error", self, "_on_match_join_error"):
		_multiplayer_bridge.disconnect("match_join_error", self, "_on_match_join_error")
	if _multiplayer_bridge.is_connected("match_joined", self, "_on_match_join"):
		_multiplayer_bridge.disconnect("match_joined", self, "_on_match_join")

func _update_data(_data_in: Dictionary, user_id: String, op_code: int) -> void :
	var path : String = NetworkConst.get_path(op_code)
	
	var node = null
	if has_node(path):
		node = get_node(path)
	
	if node:
		if is_instance_valid(node):
			if node.has_method("update_network_global_data"):
				node.update_network_global_data(_data_in, user_id)
#			else :
#				print(self, " object - ", path, " method is not found")
#		else :
#			print(self, " object - ", path, " is invalid!")
#	else :
#		print(self, " object - ", path, " not found!")

func _setup_host() -> void :
	var old_host_id := _host_id
	var ids : Array = _connected_opponents.keys()

	# важно: добавить себя в список кандидатов, если тебя там нет
	if not _peer_id.empty() and not ids.has(_peer_id):
		ids.append(_peer_id)

	if not ids.empty():
		ids.sort()
		_host_id = ids[0]
	else:
		_host_id = ""

	Logger.log_i(self, " Setup host %s old=%s" % [_host_id, old_host_id])

	if old_host_id != _host_id:
		emit_signal("host_changed", _host_id, old_host_id)



############################## SIGNALS #################################

func _on_socket_connected():
	Logger.log_i(self, " SIGNAL Socket connected.")

func _on_socket_closed():
	Logger.log_i(self, " SIGNAL Socket closed.")

func _on_socket_error(err):
	Logger.log_w(self, " SIGNAL Socket error %s" % err)

func _on_matchmaker_matched(p_matched : NakamaRTAPI.MatchmakerMatched):
	Logger.log_i(self, " SIGNAL Received MatchmakerMatched message: %s" % [p_matched])
	Logger.log_i(self, " SIGNAL Matched opponents: %s" % [p_matched.users])
	
	Logger.log_i(self, " STOP timer start single game")
	_timer_start_single_game.stop()
	
	for user in p_matched.users:
		_connected_opponents[str(user.presence.user_id)] = "" # вписать вместо "" 
	
	Logger.log_i(self, " peer_id %s" % _peer_id)
	
	_setup_host()
	
	yield(get_tree().create_timer(0.5), "timeout")
	if not is_inside_tree() or is_queued_for_deletion() : return
	
	_is_in_lobby = true
	#Singletones.get_Network().lobby.start_lobby()
	Singletones.get_Network().lobby.call_deferred("start_lobby")
	
	Logger.log_i(self, " Connect to lobby completed")

func _on_match_presence(p_presence : NakamaRTAPI.MatchPresenceEvent):
	for p in p_presence.joins:
		_connected_opponents[str(p.user_id)] = p
		if _type_match == TYPE_MATCH.CAR_GAMES:
			Singletones.get_Network().lobby.call_deferred("add_peer_to_lobby", str(p.user_id))
		Logger.log_i(self, " SIGNAL Join opponent ", str(p.user_id))
	for p in p_presence.leaves:
		_connected_opponents.erase(str(p.user_id))
		if _type_match == TYPE_MATCH.CAR_GAMES:
			Singletones.get_Network().lobby.call_deferred("del_peer_from_lobby", str(p.user_id))
		Logger.log_i(self, " SIGNAL Leave opponent ", str(p.user_id))
	Logger.log_i(self, " SIGNAL Connected opponents: %s" % [_connected_opponents.keys()])
	
	_setup_host()

func _on_match_state(p_state : NakamaRTAPI.MatchData):
	if not Singletones.get_GlobalGame().is_has_multiplayer:
		return
	if _type_match == TYPE_MATCH.CAR_GAMES and not Singletones.get_RaceSetup().type_game == Singletones.get_RaceSetup().TYPE_GAME.ONLINE_GAME:
		return
	
	time_receive_data = OS.get_unix_time()
	
	#var data : Dictionary = parse_json(p_state.data)
	var op_code : int = p_state.op_code
	if not op_code in NetworkConst.GLOBAL_TYPE_DATA.values():
		return
	
	if p_state.binary_data.empty():
		return
	
#	var data_binary_comp : PoolByteArray = p_state.binary_data
#	var size: int = data_binary_comp[data_binary_comp.size() - 1]
#	data_binary_comp.resize(data_binary_comp.size() - 1)
#	var data_binary : PoolByteArray = data_binary_comp.decompress(size, 2)
	#print(self, " Size compres state data binary ", data_binary_comp.size())
	
	var data : Dictionary = bytes2var(p_state.binary_data)
	#var data : Dictionary = bytes2var(data_binary)
	var user_id : String = p_state.presence.user_id
	
	#print(self, " SIGNAL update data %s" % data)
	call_deferred("_update_data", data, user_id, op_code)
	#_update_data(data, user_id, op_code)


func _on_match_join_error(error):
	Logger.log_w(self, " SIGNAL Unable to join match: %s" % error.message)

func _on_match_join() -> void:
	if not _multiplayer_bridge:
		return
	Logger.log_i(self, " SIGNAL Joined match with id: %s" % _multiplayer_bridge.match_id)


func _TimerStartSingleGame_timeout() -> void :
	Logger.log_i(self, " TIMEOUT timer start single game")
	
	var type_match := _type_match
	
	leave_from_lobby()
	while _is_leaving_from_lobby or _is_leaving_from_open_game:
		yield(get_tree(), "idle_frame")
		if not is_inside_tree() or is_queued_for_deletion() : return
	
	if type_match == TYPE_MATCH.FOOTBALL :
		emit_signal("timeout_start_football_single_game")
	else :
		emit_signal("timeout_start_single_game")
