extends "res://content/network/network_bridge_api.gd"
#class_name NetworkBridgeENet

const NetworkENet := preload("res://content/network/network_enet.gd")

var _network_enet : NetworkENet
var ip_join_to_server := ""

var _peers_id := []

var _timer_start_game := Timer.new()

func ready_post() -> void: # override
	_network_enet = NetworkENet.new()
	add_child(_network_enet)
	
	_timer_start_game.one_shot = true
	_timer_start_game.connect("timeout", self, "_TimerStartGame_timeout")
	add_child(_timer_start_game)
	_timer_start_game.stop()
	if Singletones.get_Network() :
		if Singletones.get_Network().lobby :
			Singletones.get_Network().lobby.connect("ready_step_added_peers", self, "_NetworkLobby_ready_step_added_peers")

func create_lobby() -> bool :
	var is_created = _network_enet.create_server()
	if is_created:
		_is_in_lobby = true
		need_peers_count_in_current_step += step_added_peers
		_connects()
		Singletones.get_Network().token = Singletones.get_Network().api.get_peer_id()
		_peers_id.append(get_name())
		yield(get_tree().create_timer(1.0), "timeout")
		_start_timers()
		Singletones.get_Network().lobby.start_lobby()
	return is_created

func close_connect() -> void :
	_peers_id.clear()
	need_peers_count_in_current_step = 0
	step_added_peers = 2
	_is_in_lobby = false
	print(self, " stop timer start single game in close connect")
	_timer_start_single_game.stop()
	if _network_enet:
		if is_host():
			_network_enet.close_connection()
		else:
			_network_enet.leave_from_server()
			_network_enet.close_connection()

func connect_to_loby() -> bool :
	if not ip_join_to_server == "":
		var is_joined = _network_enet.join_to_server(ip_join_to_server)
		if is_joined:
			_connects()
		return is_joined
	else:
		return false

func leave_from_lobby() -> bool :
	Singletones.get_Network().lobby.leave_from_lobby()
	_is_in_lobby = false
	print(self, " leave from lobby")
	print(self, " leave from lobby wait...")
	yield(get_tree(), "idle_frame")
	
	print(self, " leave from lobby. close connect")
	call_deferred("close_connect")
	return true

func is_host() -> bool :
	return _network_enet.is_server

func get_name() -> String :
	return str(_network_enet.get_peer_id())

func get_names_players() -> Array :
	var peers_names := []
	for peer in _peers_id:
		if not peer == get_name():
			peers_names.append(peer)
	return peers_names

func get_peer_id() -> String :
	return str(_network_enet.get_peer_id())

func get_peers_id() -> Array :
	var peers_id := []
	for peer in _peers_id:
		if not peer == get_peer_id():
			peers_id.append(peer)
	return peers_id

func get_peer() -> NetworkedMultiplayerPeer :
	return null

func set_port(port: int) -> void :
	_network_enet.DEFAULT_PORT = port

remote func _update_data_enet(data_bytes: PoolByteArray) -> void :
	var data : Dictionary = bytes2var(data_bytes)
	_update_data(data)

func send_data_to_peer(peer_id) -> bool :
	if _is_in_lobby:
		var data_bytes : PoolByteArray = var2bytes(_data)
		rpc_unreliable_id(peer_id, "_update_data_enet", data_bytes)
		return true
	else:
		return false

func send_data_to_all() -> bool :
	if _is_in_lobby:
		var data_bytes : PoolByteArray = var2bytes(_data)
		rpc_unreliable("_update_data_enet", data_bytes)
		return true
	else:
		return false

func port_delete() -> void :
	_network_enet.port_delete()

func _start_timers() -> void :
	_timer_start_game.wait_time = 30
	_timer_start_game.start()
	print(self, " start timer start game ", _timer_start_game.wait_time, " sec")
	
	_timer_start_single_game.wait_time = 45.0
	_timer_start_single_game.start()
	print(self, " start timer start single game ", _timer_start_single_game.wait_time, " sec")

func _connects() -> void :
	if not get_tree().is_connected("network_peer_connected", self, "_Network_player_connected"):
		get_tree().connect("network_peer_connected", self, "_Network_player_connected")
		get_tree().connect("network_peer_disconnected", self, "_Network_player_disconnected")
		get_tree().connect("connected_to_server", self, "_Network_connected_to_server")
		get_tree().connect("server_disconnected", self, "_Network_server_disconnected")
		get_tree().connect("connection_failed", self, "_Network_connection_failed")

func _Network_player_connected(id) -> void :
	print("NetworkBridgeENet   ID ", Singletones.get_Network().api.get_peer_id(), "   Player ", str(id), " connected")
	if not _peers_id.has(str(id)):
		_peers_id.append(str(id))
	print("NetworkBridgeENet   ID ", Singletones.get_Network().api.get_peer_id(), "   Peers ", _peers_id)
	Singletones.get_Network().lobby.add_network_peer_to_lobby(str(id))

func _Network_player_disconnected(id) -> void :
	print("NetworkBridgeENet   ID ", Singletones.get_Network().api.get_peer_id(), "   Player ", str(id), " disconnected")
	if _peers_id.has(str(id)):
		_peers_id.remove(_peers_id.find(str(id)))
	print("NetworkBridgeENet   ID ", Singletones.get_Network().api.get_peer_id(), "   Peers ", _peers_id)
	Singletones.get_Network().lobby.del_network_peer_from_lobby(str(id))

func _Network_connected_to_server() -> void :
	_is_in_lobby = true
	need_peers_count_in_current_step += step_added_peers
	print("NetworkBridgeENet   ID ", Singletones.get_Network().api.get_peer_id(), "   connected to server")
	Singletones.get_Network().token = Singletones.get_Network().api.get_peer_id()
	if not _peers_id.has(get_name()):
		_peers_id.append(get_name())
	print("NetworkBridgeENet   ID ", Singletones.get_Network().api.get_peer_id(), "   Peers ", _peers_id)
	yield(get_tree().create_timer(1.0), "timeout")
	_start_timers()
	Singletones.get_Network().lobby.start_lobby()

func _Network_server_disconnected() -> void :
	_is_in_lobby = false
	print("NetworkBridgeENet   ID ", Singletones.get_Network().api.get_peer_id(), "   Server disconnected")

func _Network_connection_failed() -> void :
	_is_in_lobby = false
	print("NetworkBridgeENet   ID ", Singletones.get_Network().api.get_peer_id(), "   Connection failed")


func _TimerStartGame_timeout() -> void :
	print(self, " timeout timer start game")
	if is_host():
		print(self, " force start")
		Singletones.get_Network().lobby.force_start()


func _NetworkLobby_ready_step_added_peers() -> void :
	need_peers_count_in_current_step += step_added_peers


func NetworkLobby_lobby_ready_for_race_post() -> void : # override
	print(self, " stop timer start game   from   signal lobby_ready_for_race")
	_timer_start_game.stop()




