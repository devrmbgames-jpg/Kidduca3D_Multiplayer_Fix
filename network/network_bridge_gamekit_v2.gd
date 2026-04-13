extends "res://content/network/network_bridge_api.gd"
#class_name NetworkBridgeGamekitV2

const UUID_PATH := "user://uuid.cfg"
const CFG_VALUE := "uuid"
const CFG_SECTION := "PARAM"

var _view_controller: Reference = null
var _matchmaker: Reference = null
var _game_match: Reference = null

var _players_name_to_player := {}
var _player_name_state := {}
var _player_name_to_icon := {}
var _player_names := []


var _request: Reference = null

var _local_player: Reference = null

#var _timer_wait := Timer.new()
#var _timer_pending_host := Timer.new()
var _host_player_name := ""




func _log_time(text_log: String, val = "") -> void :
	var time : String = Time.get_time_string_from_unix_time(OS.get_unix_time())
	print(time, " ", self, " ", text_log, " ", val)


func _to_string() -> String:
	return "[NetworkBridgeGameKitV2]"

func ready_post() -> void: # override
	
	pass #TODO _log_time( " ready...")
	yield(get_tree().create_timer(0.1), "timeout")
	#_local_player = GameKitBuilder.create_local_player()
	
	
	pass #TODO _log_time( " athenticate...")
	_local_player.authenticate()
	var i := 0
	while not _local_player.get_authenticated() and i < 20 :
		i += 1
		yield(get_tree().create_timer(1.0), "timeout" )
		if not _local_player.get_authenticated() :
			Logger.log_e(self, "failed local player authenticated!")
	
	_local_player.connect(
		"update_texture_icon", 
		self, 
		"_update_player", 
		[
			_local_player,
			0,
			GKMatch.GKPlayerStateConnected
		], 
	CONNECT_DEFERRED)
	
	_local_player.get_texture_icon()
	
	var player_name = _local_player.get_player_name()
	pass #TODO _log_time( " local player: ", player_name)
	
	_player_names = [player_name]
	_players_name_to_player[player_name] = _local_player
	_player_name_state[player_name] = GKMatch.GKPlayerStateConnected
	
	_data.sender = get_peer_id()
	
	#_timer_wait.wait_time = 20
	#_timer_wait.one_shot = true
	#_timer_wait.connect("timeout", self, "_finish_wait")
	#add_child(_timer_wait)
	
	#_timer_pending_host.wait_time = 1
	#_timer_pending_host.one_shot = true
	#_timer_pending_host.connect("timeout", self, "_finish_pending_host")
	#add_child(_timer_pending_host)
	
	Singletones.get_Network().lobby.connect("ready_step_added_peers", self, "_NetworkLobby_ready_step_added_peers")
	Singletones.get_Network().lobby.connect("del_peer_after_time_disconect", self, "_networkLobby_del_peer_after_time_disconect")
	
	var mm := GameKitBuilder.matchmaker()
	_matchmaker = mm
	_matchmaker.connect("find_match_completion_handler", self, "_on_matchmaker_view_controller_did_find_match")
	

func _update_player(image: Image, player: Reference, id: int, status: int) -> void :
	var nickname: String = player.get_player_name()
	var is_friend: bool = true if id == 0 else false
	
	print(self, " update player img:", image, " id:", id, " nickname:", nickname, " is_friend:", is_friend, " status:", status)
	var texture: ImageTexture = null
	if image :
		texture = ImageTexture.new()
		texture.create_from_image(image, ImageTexture.FLAG_FILTER)
	
	_player_name_to_icon[nickname] = texture
	
	var state := OK if status == GKMatch.GKPlayerStateConnected else ERR_BUSY
	
	emit_signal(
		"update_player_status", 
		id, nickname, texture, is_friend, state)
	


#func _init_witch_request(request: Reference) -> void :
#	print(self, " ini with request: ", str(request))
#
#	var player_name: String = _local_player.get_player_name()
#	_player_names = [player_name]
#	_players_name_to_player[player_name] = _local_player
#	_player_name_state[player_name] = GKMatch.GKPlayerStateConnected
#
#	_request = request
#
#	if _game_match :
#		_game_match.disconnect_match()
#		_game_match.clear()
#		_game_match = null
#
#	_matchmaker.cancel()
#	_matchmaker.find_match_for_request(_request)
#
#	var icon: Image = _local_player.get_texture_icon()
#	_update_player(icon, _local_player, 0, GKMatch.GKPlayerStateConnected)
#
#	_timer_start_single_game.wait_time = 35.0
#	_timer_start_single_game.start()
#	print(self, " start timer start single game ", _timer_start_single_game.wait_time, " sec")


############## INIT WITH REQUEST ##################################
func _init_witch_request(request: Reference) -> void :
	pass #TODO _log_time( " [init] 1 init with request: ", str(request))
	
	var player_name: String = _local_player.get_player_name()
	_player_names = [player_name]
	_players_name_to_player[player_name] = _local_player
	_player_name_state[player_name] = GKMatch.GKPlayerStateConnected
	
	_request = request
	
	if _game_match :
		pass #TODO _log_time( "  |-- match disconnect. game_match ", _game_match)
		_game_match.disconnect_match()
	else:
		pass #TODO _log_time( "  |-- match NOT disconnect. game_match ", _game_match)
	
	get_tree().create_timer(0.3).connect("timeout", self, "_clear_match_after_disconect_match_init")

func _clear_match_after_disconect_match_init() -> void :
	pass #TODO _log_time( " [init] 2 clear match after disconect match")
	if _game_match :
		pass #TODO _log_time( "  |-- match clear. game_match ", _game_match)
		_game_match.clear()
	else:
		pass #TODO _log_time( "  |-- match NOT clear. game_match ", _game_match)
	_game_match = null
	get_tree().create_timer(0.3).connect("timeout", self, "_cancel_matchmaker_after_clear_match_init")

func _cancel_matchmaker_after_clear_match_init() -> void :
	pass #TODO _log_time( " [init] 3 cancel matchmaker after clear match")
	if _matchmaker:
		pass #TODO _log_time( "  |-- matchmaker cancel. matchmaker ", _matchmaker)
		_matchmaker.cancel()
	else:
		pass #TODO _log_time( "  |-- matchmaker NOT cancel. matchmaker ", _matchmaker)
	get_tree().create_timer(0.3).connect("timeout", self, "_find_match_after_cancel_matchmaker_init")

func _find_match_after_cancel_matchmaker_init() -> void :
	pass #TODO _log_time( " [init] 4 find match after cancel matchmaker")
	if _matchmaker:
		pass #TODO _log_time( "  |-- find match. matchmaker ", _matchmaker)
		_matchmaker.find_match_for_request(_request)
	else:
		pass #TODO _log_time( "  |-- NOT find match. matchmaker ", _matchmaker)
	
	var icon: Image = _local_player.get_texture_icon()
	_update_player(icon, _local_player, 0, GKMatch.GKPlayerStateConnected)
	
	_timer_start_single_game.wait_time = TIME_FIND_START_SINGLE_GAME
	_timer_start_single_game.start()
	pass #TODO _log_time( "  |-- timer start single game START ", _timer_start_single_game.wait_time)
############## INIT WITH REQUEST END ##################################



# Произошла ошиька
func _on_matchmaker_view_controller_did_fail_with_error( error: String) -> void : 
	pass #TODO _log_time( " matchmaker view_controller did fail with error:", error)
	#_view_controller.dissmis(false)
	call_deferred("leave_from_lobby")

func _on_matchmaker_view_controller_was_cancelled() -> void :
	pass #TODO _log_time( " matchmaker view_controller was cancelled")
	#_view_controller.dissmis(false)
	call_deferred("leave_from_lobby")


################################################################################
####### MATCH ##################################################################
################################################################################

func _on_matchmaker_view_controller_did_find_match(game_match: Reference) -> void :
	pass #TODO _log_time( " matchmaker view_controller did find match:", game_match)
	if not game_match :
		Logger.log_e(self, "Failed find match")
		_on_matchmaker_view_controller_did_fail_with_error("failed")
		return
	#_view_controller.dissmis(false)
	_game_match = game_match
	_game_match.connect("chose_best_hosting_player_with_completion_handler", self, "_on_chose_best_hosting_player_with_completion_handler", [], CONNECT_DEFERRED)
	_game_match.connect("rematch_with_completion_handler", self, "_on_rematch_with_completion_handler", [], CONNECT_DEFERRED)
	_game_match.connect("match_did_fail_with_error", self, "_on_match_did_fail_with_error", [], CONNECT_DEFERRED)
	_game_match.connect("match_player_did_change_connection_state", self, "_on_match_player_did_change_connection_state", [], CONNECT_DEFERRED)
	_game_match.connect("match_did_recive_data_from_remote_player", self, "_on_match_did_recive_data_from_remote_player")
	_game_match.connect("match_did_recive_data_for_recipient_from_remote_player", self, "_on_match_did_recive_data_for_recipient_from_remote_player")
	#_game_match.connect("match_should_reinvite_disconnected_player", self, "_on_match_should_reinvite_disconnected_player")
	
	Singletones.get_Network().token = get_peer_id()
	
	_finish_wait()

# Получаем хоста
func _on_chose_best_hosting_player_with_completion_handler(player: Reference) -> void :
	pass #TODO _log_time( " chose best hosting player:", player)
	if player :
		pass #TODO _log_time( "        player_name:", player.get_player_name())
		_host_player_name = player.get_player_name()
	else :
		Logger.log_e(self, " chose best hosting player is null!")
	
	#_finish_pending_host()

#если мы делаем РЕМАТЧ, то получаем этот обьект матча
func _on_rematch_with_completion_handler(game_match: Reference, error: String) -> void :
	pass #TODO _log_time( " rematch with:", game_match)
	pass #TODO _log_time( "  |-- completion handler:", error)
	if not error.empty() :
		_on_match_did_fail_with_error(error)
		return
	
	_game_match.clear()
	_game_match = null
	
	_player_name_state[_local_player.get_player_name()] = GKMatch.GKPlayerStateConnected
	_players_name_to_player[_local_player.get_player()] = _local_player
	
	var icon: Image = _local_player.get_texture_icon()
	_update_player(
		icon,
		_local_player,
		0,
		GKMatch.GKPlayerStateConnected
	)
	
	var idx := 1
	for player in game_match.get_players() :
		_player_names.append(player.get_player_name())
		_player_name_state[player.get_player_name()] = GKMatch.GKPlayerStateConnected
		_players_name_to_player[player.get_player()] = player
		
		_update_player(
			player.get_texture_icon(),
			player,
			idx,
			GKMatch.GKPlayerStateConnected
		)
		
		idx += 1
	
	
	_on_matchmaker_view_controller_did_find_match(game_match)
	

#мы потеряли соеденинение
func _on_match_did_fail_with_error(error: String) -> void :
	pass #TODO _log_time( " match did fail with error:", error)
	if _game_match :
		_game_match.disconnect_match()
	
	call_deferred("leave_from_lobby")

#игроки меняют статус
func _on_match_player_did_change_connection_state(player: Reference, state: int) -> void :
	pass #TODO _log_time( " Change connection state from GAME MATCH")
	if not _player_did_change_connection_state(player, state):
		return
	
	var nickname: String = player.get_player_name()
	
	match state:
		GKMatch.GKPlayerStateConnected:
			pass #TODO _log_time( " Add network player to lobby, ", nickname)
			Singletones.get_Network().lobby.call_deferred("add_network_peer_to_lobby", nickname)
		GKMatch.GKPlayerStateDisconnected:
			pass #TODO _log_time( " Del network player from lobby, ", nickname)
			Singletones.get_Network().lobby.call_deferred("del_network_peer_from_lobby", nickname)

func _player_did_change_connection_state(player: Reference, state: int) -> bool :
	pass #TODO _log_time( " match player:", player)
	pass #TODO _log_time( " did change connection state:", state)
	pass #TODO _log_time( "            player_name:", player.get_player_name())
	pass #TODO _log_time( "            state      :", state)
	
	if not player :
		Logger.log_e(self, "match player did change connectuon state is null")
		return false
	
	var nickname: String = player.get_player_name()
	
	if nickname.empty() :
		Logger.log_e(self, "match player did change connectuon state, is this player...")
		return false
	
	_players_name_to_player[nickname] = player
	_player_name_state[nickname] = state

	if not _player_names.has(nickname) :
		_player_names.append(nickname)
	
	var idx := _player_names.find(nickname)
	
	if player.is_connected("update_texture_icon", self, "_update_player") :
		player.disconnect("update_texture_icon", self, "_update_player")
	player.connect(
		"update_texture_icon", 
		self, 
		"_update_player", 
		[
			player,
			idx,
			state
		], 
		CONNECT_ONESHOT | CONNECT_DEFERRED)
	
	var icon: Image = player.get_texture_icon()
	_update_player(icon, player, idx, state)
	_sort_player_and_select_host()
	
	return true


func _send_to_all_my_uuid() -> void :
	pass #TODO _log_time( " send to all ID")
	_data[TAG_TYPE] = PACKED_TYPE_HELLO
	_data[TAG_SENDER] = get_peer_id()
	var data_bytes : PoolByteArray = var2bytes(_data)
	_game_match.send_data_to_all_players(data_bytes, GKMatch.GKMatchSendDataReliable, "")


############### FINISH WAIT ########################################
var _count_tick_timer_wait_players := 0
func _finish_wait() -> void :
	pass #TODO _log_time( " finish wait")
	
	_send_to_all_my_uuid()
	_game_match.choose_best_hosting_player()
	#_timer_pending_host.start()
	
	_count_tick_timer_wait_players = 0
	_wait_players()

func _wait_players() -> void :
	if not is_inside_tree():
		return
	
	pass #TODO _log_time( " wait players")
	_count_tick_timer_wait_players += 1
	
	if not _game_match or not is_instance_valid(_game_match):
		pass #TODO _log_time( "  |-- game match NOT found. game_match ", _game_match)
		return
	
	var connected_states := 0
	for state in _player_name_state.values() :
		if state == GKMatch.GKPlayerStateConnected :
			connected_states += 1
	pass #TODO _log_time( "  |-- connected_states ", connected_states)
	
	if _game_match.get_excepted_player_count() == 0 :
		pass #TODO _log_time( "  |-- excepted_player_count == 0")
		_finish_wait_2()
	
	if connected_states == _game_match.get_players().size() :
		pass #TODO _log_time( "  |-- connected_states == _game_match.get_players().size()")
		_finish_wait_2()
	
	if _is_in_lobby :
		pass #TODO _log_time( "  |-- is_in_lobby TRUE")
		_finish_wait_2()
	
	pass #TODO _log_time( "  |-- connected - ", connected_states)
	if _count_tick_timer_wait_players < 10:
		pass #TODO _log_time( "  |-- wait players again. _count_tick_timer_wait_players ", _count_tick_timer_wait_players)
		get_tree().create_timer(1.0).connect("timeout", self, "_wait_players")
	else:
		pass #TODO _log_time( "  |-- count ticks OUT. _count_tick_timer_wait_players ", _count_tick_timer_wait_players)
		_finish_wait_2()

func _finish_wait_2() -> void :
	pass #TODO _log_time( " finish_wait_2")
	_sort_player_and_select_host()
	if is_host() :
		pass #TODO _log_time( "  |-- finish matchmaking from match...")
		_matchmaker.finish_matchmaking_for_match(_game_match)
	
	_finish_pending_host()
	#ГОТОВЫ НАЧАТЬ
############### FINISH WAIT END ########################################



func _on_match_did_recive_data_from_remote_player(data: PoolByteArray, player: Reference) -> void :
	var data_dict : Dictionary = bytes2var(data)
	pass #TODO _log_time( " match did recive data: ", data_dict)
	pass #TODO _log_time( "  |-- remote player: ", player)
	if data :
		if data_dict :
			var type = data_dict[TAG_TYPE]
			if type == PACKED_TYPE_DATA :
				_update_data(data_dict)
			elif type == PACKED_TYPE_START_LOBBY :
				_finish_pending_host()

func _on_match_did_recive_data_for_recipient_from_remote_player(data: PoolByteArray, recipient: Reference, player: Reference) -> void :
	
	var data_dict : Dictionary = bytes2var(data)
	pass #TODO _log_time( " match did recive data: ", data_dict)
	pass #TODO _log_time( "   |-- for recipinet: ", recipient)
	pass #TODO _log_time( "   |-- remote player: ", player)
	if data :
		if data_dict :
			var type = data_dict[TAG_TYPE]
			if type == PACKED_TYPE_DATA :
				_update_data(data_dict)
			elif type == PACKED_TYPE_START_LOBBY :
				_finish_pending_host()

#информация об реинвайте. Перегрузите функцию в GKMatch для отработки
func _on_match_should_reinvite_disconnected_player(player: Reference) -> void :
	pass #TODO _log_time( " match should reinvite disconnected player:", player)
	pass

func _sort_player_and_select_host() -> void :
	pass #TODO _log_time( " Sort player and select host")
	var players := []
	
	for key in _player_name_state :
		if _player_name_state[key] == GKMatch.GKPlayerStateConnected :
			players.append(key)
	
	players.sort()
	pass #TODO _log_time( " variants hosts - ", players)
	_host_player_name = players.front()

func _finish_pending_host() -> void :
	if _is_in_lobby :
		return
	#_timer_pending_host.stop()
	#_timer_wait.stop()
	_is_in_lobby = true
	pass #TODO _log_time( " finish pending host:", _host_player_name)
	
	_sort_player_and_select_host()
	
	#СТАРТ
	pass #TODO _log_time( " start lobby")
	Singletones.get_Network().lobby.start_lobby()
	emit_signal("connect_to_lobby")
	
	
	yield(get_tree().create_timer(0.1),"timeout")
	if is_host() :
		pass #TODO _log_time( " force start")
		Singletones.get_Network().lobby.force_start()


################################################################################
####### API ####################################################################
################################################################################

func is_host() -> bool :
	return _local_player.get_player_name() == _host_player_name

func create_lobby() -> bool :
	return false

func create_lobby_from_friend() -> bool :
	return false

#func rematch() -> void :
#	if not _game_match :
#		push_error("%s failed rematch... game match is null" % str(self))
#		call_deferred("leave_from_lobby")
#		return
#
#
#	_game_match.disconnect(
#		"chose_best_hosting_player_with_completion_handler", 
#		self, 
#		"_on_chose_best_hosting_player_with_completion_handler")
#	_game_match.disconnect(
#		"match_did_fail_with_error", 
#		self, 
#		"_on_match_did_fail_with_error")
#	_game_match.disconnect(
#		"match_player_did_change_connection_state", 
#		self, 
#		"_on_match_player_did_change_connection_state")
#	_game_match.disconnect(
#		"match_did_recive_data_from_remote_player", 
#		self, 
#		"_on_match_did_recive_data_from_remote_player")
#	_game_match.disconnect(
#		"match_did_recive_data_for_recipient_from_remote_player", 
#		self, 
#		"_on_match_did_recive_data_for_recipient_from_remote_player")
#
#	_host_player_name = ""
#	_player_name_state = {}
#	_players_name_to_player = {}
#	_player_names = [_local_player.get_player_name()]
#
#	var icon: Image = _local_player.get_texture_icon()
#	_update_player(
#		icon,
#		_local_player,
#		0,
#		GKMatch.GKPlayerStateConnected
#	)
#
#	#_timer_pending_host.stop()
#	#_timer_wait.stop()
#	_is_in_lobby = false
#
#	_game_match.rematch_with()
#	emit_signal("rematching")


func connect_to_lobby_friend(friend: String) -> bool :
	return false

func connect_to_loby() -> bool :
	pass #TODO _log_time( " connect to lobby")
	Singletones.get_Network().lobby.leave_from_lobby()
	var request := GameKitBuilder.create_match_request(2, NEED_PLAYERS_COUNT)
	request.default_player = NEED_PLAYERS_COUNT
	get_tree().create_timer(0.3).connect("timeout", self, "_init_witch_request", [request])
	#_init_witch_request(request)
	return true

#func close_connect() -> void :
#	print(self, " close connect")
#
#	if _matchmaker :
#		_matchmaker.cancel()
#
#	print(self, "    \\_disconnected match")
#	if _game_match:
#		_game_match.disconnect_match()
#		_game_match.clear()
#	_game_match = null
#
#	print(self, "    \\_clear collections")
#
#	_host_player_name = ""
#	_player_name_state = {}
#	_players_name_to_player = {}
#	_player_names = [_local_player.get_player_name()]
#
#
#	print(self, "    \\_timers stopped")
#	#_timer_pending_host.stop()
#	#_timer_wait.stop()
#	print(self, "    \\_stop timer start single game in close connect")
#	_timer_start_single_game.stop()
#	_is_in_lobby = false
#
#
#	if _view_controller :
#		_view_controller.call_deferred("free")
#	_view_controller = null
#
#	print(self, "     \\_completed")


############### CLOSE CONNECT #####################################
func close_connect() -> void :
	pass #TODO _log_time( " [close] 1 close connect")
	pass #TODO _log_time( " |-- timer start single game STOP")
	_timer_start_single_game.stop()
	if _game_match:
		pass #TODO _log_time( "  |-- match disconect. game_match ", _game_match)
		_game_match.disconnect_match()
	else:
		pass #TODO _log_time( "  |-- match NOT disconect. game_match ", _game_match)
	get_tree().create_timer(0.3).connect("timeout", self, "_clear_match_after_disconnect_match_close")

func _clear_match_after_disconnect_match_close() -> void :
	pass #TODO _log_time( " [close] 2 clear match after disconnect match")
	if _game_match:
		pass #TODO _log_time( "  |-- match clear. game_match ", _game_match)
		_game_match.clear()
	else:
		pass #TODO _log_time( "  |-- match NOT clear. game_match ", _game_match)
	_game_match = null
	get_tree().create_timer(0.3).connect("timeout", self, "_cancel_matchmaker_after_clear_match_close")

func _cancel_matchmaker_after_clear_match_close() -> void :
	pass #TODO _log_time( " [close] 3 cancel matchmaker after clear match")
	if _matchmaker :
		pass #TODO _log_time( "  |-- matchmaker cancel. matchmaker ", _matchmaker)
		_matchmaker.cancel()
	else:
		pass #TODO _log_time( "  |-- matchmaker NOT cancel. matchmaker ", _matchmaker)
	get_tree().create_timer(0.3).connect("timeout", self, "_clear_collections_after_cancel_matchmaker_close")

func _clear_collections_after_cancel_matchmaker_close() -> void :
	pass #TODO _log_time( " [close] 4 clear collections after clear match")
	_host_player_name = ""
	_player_name_state = {}
	_players_name_to_player = {}
	if _local_player:
		pass #TODO _log_time( "  |-- local_player ", _local_player)
		_player_names = [_local_player.get_player_name()]
	else:
		pass #TODO _log_time( "  |-- local_player NOT found ", _local_player)
		_player_names = []
	
	_is_in_lobby = false
	
	if _view_controller :
		pass #TODO _log_time( "  |-- view controller free. view_controller ", _view_controller)
		_view_controller.call_deferred("free")
	else:
		pass #TODO _log_time( "  |-- view controller NOT free. view_controller ", _view_controller)
	_view_controller = null
	
	pass #TODO _log_time( "  |-- close connect completed")
############### CLOSE CONNECT END #####################################


func leave_from_lobby() -> bool :
	pass #TODO _log_time( " leave from lobby")
	Singletones.get_Network().lobby.leave_from_lobby()
	_is_in_lobby = false
	get_tree().create_timer(0.3).connect("timeout", self, "close_connect")
	return true


func invite_friend(friend: String) -> bool :
	return false

func connect_from_invite():
	pass



func get_peer_id() -> String :
	return _local_player.get_player_name()

func get_peers_id() -> Array :
	return _players_name_to_player.keys()

func get_name() -> String :
	return _local_player.get_player_name()

func get_names_players() -> Array :
	var names := []
	if _game_match:
		var players: Array = _game_match.get_players()
		for player in players:
			names.append(player.get_player_name())
	return names

func get_icon_player_from_peer_id(peer_id: String) -> Texture :
	if not _player_name_to_icon.has(peer_id):
		pass #TODO _log_time( " Error get icon player - _player_name_to_icon not has peer_id ", peer_id)
		return null
	
	return _player_name_to_icon[peer_id]
	
#	var player = _players_name_to_player[peer_id]
#	var icon: Image = player.get_texture_icon()
#	var texture: ImageTexture = null
#	if icon :
#		texture = ImageTexture.new()
#		texture.create_from_image(icon, ImageTexture.FLAG_FILTER)
#	else:
#		print(self, " Error get icon player - icon texture is null")
#	return texture\

func poll() -> bool :
	return false


func send_data_to_peer(peer_id) -> bool :
	pass #TODO _log_time( " send data to peer")
	if not Singletones.get_GlobalGame().is_has_multiplayer:
		return false
	
	if _is_in_lobby :
		var player: Reference = _players_name_to_player.get(peer_id, null)

		if _game_match and player :
			_data[TAG_TYPE] = PACKED_TYPE_DATA
			var data_bytes : PoolByteArray = var2bytes(_data)
			_game_match.send_data_to_players(data_bytes, [player], GKMatch.GKMatchSendDataUnreliable, "")
			return true

	return false

func send_data_to_all() -> bool :
	pass #TODO _log_time( " send data to all")
	if not Singletones.get_GlobalGame().is_has_multiplayer:
		pass #TODO _log_time( "  |-- failed send data to all, multiplayer disabled")
		return false
	
	if _is_in_lobby:
		_data[TAG_TYPE] = PACKED_TYPE_DATA
		pass #TODO _log_time( "  |-- data to all:", _data)
		if _game_match :
			var data_bytes : PoolByteArray = var2bytes(_data)
			_game_match.send_data_to_all_players(data_bytes, GKMatch.GKMatchSendDataUnreliable, "")
			return true

		pass #TODO _log_time( " failed send data to all, game match is null")

	pass #TODO _log_time( " failed send data to all, is in lobby is false")
	return false

func get_peer() -> NetworkedMultiplayerPeer :
	return null

func get_expected_player_count() -> int :
	if _game_match:
		return _game_match.expected_player_count()
	else:
		return -1


###############################################################################
########## NETWORK LOBBY ######################################################
###############################################################################

func _NetworkLobby_ready_step_added_peers() -> void :
	need_peers_count_in_current_step += step_added_peers
	pass #TODO _log_time( " Signal _NetworkLobby_ready_step_added_peers    need_peers_count_in_current_step ", need_peers_count_in_current_step)

func _networkLobby_del_peer_after_time_disconect(peer_id: String) -> void :
	pass #TODO _log_time( " _networkLobby_del_peer_after_time_disconect")
	if _players_name_to_player.has(peer_id):
		pass #TODO _log_time( " Change connection state from LOBBY")
		var player : Reference = _players_name_to_player[peer_id]
		_player_did_change_connection_state(player, GKMatch.GKPlayerStateDisconnected)
	else:
		pass #TODO _log_time( " player ID NOT found ", peer_id)

