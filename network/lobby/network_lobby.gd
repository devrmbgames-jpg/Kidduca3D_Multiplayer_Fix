extends Node

signal lobby_ready_for_race()
signal all_finished_load_race()
signal ready_step_added_peers()
signal self_peer_is_host()
signal self_peer_is_not_host()
signal del_peer_after_time_disconect(peer_id)

const PEER_LOBBY_PKG := preload("res://content/network/lobby/peer_lobby.tscn")

const TIME_BEFORE_DEL_NETWORK_PEER := 3.0
const TIME_DISC_NETWORK_PEER_BEFORE_DEL := 6.0

onready var _timer_check_start_race := $TimerCheckStartRace
onready var _timer_check_disconect_peers := $TimerCheckDisconectPeers
onready var _timers_del_network_peer := $TimersDelNetworkPeer
onready var _peers_node := $PeersLobby

var _peers := {}
var _peers_is_here := {}

var _peer_id_self := ""

var _count_track := 1

enum STATE_LOBBY {
	PENDING_ADDED_PEERS,
	PENDING_SYNC_BEFORE_LOAD_RACE,
	PENDING_ALL_FINISHED_LOAD_RACE,
	NONE
}
var _state_lobby : int = STATE_LOBBY.NONE

enum TYPE_DATA {
	CHANGE_STATE_TO_RACE,
	PEER_IS_HERE
}

var _data_network_change_state_to_race := {
	"type" : TYPE_DATA.CHANGE_STATE_TO_RACE
}
var _data_network_peer_is_here := {
	"type" : TYPE_DATA.PEER_IS_HERE,
	"peer_id" : ""
}


func _ready():
	connect("tree_exiting", self, "_NetworkLobby_tree_exiting")

func start_lobby() -> void :
	randomize()
	_timer_check_start_race.stop()
	_timer_check_disconect_peers.stop()
	_state_lobby = STATE_LOBBY.PENDING_ADDED_PEERS
	_peer_id_self = ""
	
	Logger.log_i(self, " Lobby node name ", get_path())
	Singletones.get_Network().api.add_object_update(get_path(), self)
	
	var id_peers : Array = Singletones.get_Network().api.get_peers_id()
	_peer_id_self = Singletones.get_Network().api.get_peer_id()
	Logger.log_i(self, " Peers ID ", id_peers)
	Logger.log_i(self, " Peer self ID ", _peer_id_self)
	
	_add_self_to_lobby(_peer_id_self)
	
	for i in id_peers.size():
		if not id_peers[i] == _peer_id_self:
			_add_peer_to_lobby(id_peers[i], false)
	
	_timer_check_start_race.start()
	_timer_check_disconect_peers.start()

func leave_from_lobby() -> void :
	print(self, " leave from lobby")
	for peer in _peers.values():
		peer.stop_send_data()
	for i in _peers_node.get_child_count():
		_peers_node.get_child(i).name = "del_" + str(i)
		_peers_node.get_child(i).queue_free()
	_peers.clear()
	_timer_check_start_race.stop()
	_timer_check_disconect_peers.stop()
	_state_lobby = STATE_LOBBY.NONE
	_peer_id_self = ""


func _del_self_from_lobby(id_peer: String) -> void :
	Logger.log_i(self, " func del self from lobby. Peer id ", id_peer)
	_del_peer_from_lobby(id_peer)

func del_network_peer_from_lobby(id_peer: String) -> void :
	if not _timers_del_network_peer.has_node(id_peer):
		var timer := Timer.new()
		timer.name = id_peer
		_timers_del_network_peer.add_child(timer)
		timer.wait_time = TIME_BEFORE_DEL_NETWORK_PEER
		timer.connect("timeout", self, "_on_TimerDelNetworkPeer_timeout", [id_peer])
		timer.start()
		Logger.log_i(self, " Start timer ", TIME_BEFORE_DEL_NETWORK_PEER, " sec before del peer id ", id_peer)

func _del_peer_from_lobby(id_peer: String) -> void :
	Logger.log_i(self, " func del peer from lobby. Peer id ", id_peer)
	if _peers_node.has_node(id_peer):
		var p := _peers_node.get_node(id_peer)
		Logger.log_i(self, "     \\_ del obj update")
		Singletones.get_Network().api.del_object_update(p.get_path())
		p.stop_send_data()
		
		Logger.log_i(self, "     \\_ free")
		p.name += "del"
		p.queue_free()
		Logger.log_i(self, " ID " + str(Singletones.get_Network().api.get_peer_id()) + "   DEL node from lobby peer ID ", id_peer, "   Peers ", _peers)
	
	if _peers.erase(id_peer):
		Logger.log_i(self, " ID " + str(Singletones.get_Network().api.get_peer_id()) + "   DEL from list lobby peer ID ", id_peer, "   Peers ", _peers)
	
	_peers_is_here.erase(id_peer)
	
	# TODO ПОМЕНЯТЬ ПРИНЦИП ДЕЙСТВИЯ, ЕСЛИ МЫ ЯВЛЯЕМСЯ ХОСТОМ
	#	if not _peers.empty() and not _peer_id_self == "":
	#		_peers[_peer_id_self].is_host = Singletones.get_Network().api.is_host()
	#		for key in _peers:
	#			_peers[key].need_update_data()
	
	Logger.log_i(self, "     \\_completed!")


func get_peers_id() -> Array :
	return _peers.keys()

func get_peers() -> Array :
	return _peers.values()

func get_peers_count() -> int :
	return _peers.size()

func get_peers_sort() -> Array :
	var keys_peers_sort = _peers.keys()
	keys_peers_sort.sort()
	var peers := []
	for key in keys_peers_sort:
		peers.append(_peers[key])
	return peers

func get_peer_self() :
	return _peers[_peer_id_self]

func is_host() -> bool :
	return get_peer_id_host() == _peer_id_self

func get_peer_id_host() -> String :
	var peer_id_host := ""
	for peer in _peers.values():
		if peer.is_host:
			peer_id_host = peer.peer_id
	return peer_id_host

func get_peer_host() :
	if has_host_in_lobby():
		return _peers[get_peer_id_host()]
	else:
		return null

func has_host_in_lobby() -> bool :
	var has_host := false
	for peer in _peers.values():
		if peer.is_host:
			has_host = true
	return has_host

func force_start() -> void :
	Logger.log_i(self, " func force start. Count peers ", _peers.size())
	if Singletones.get_Network().api.is_host():
		_state_lobby = STATE_LOBBY.PENDING_SYNC_BEFORE_LOAD_RACE
		Logger.log_i(self, " HOST Force start. Count peers ", _peers.size())


func set_count_track(count_track: int) -> void :
	_count_track = count_track if count_track > 0 else 1
	Logger.log_i(self, " Set count tracks ", _count_track)

func update_network_data(data: Dictionary) -> void :
	match data.type:
		TYPE_DATA.CHANGE_STATE_TO_RACE:
			if _state_lobby == STATE_LOBBY.PENDING_ADDED_PEERS:
				_peers[_peer_id_self].is_host = Singletones.get_Network().api.is_host()
				for key in _peers:
					_peers[key].need_update_data()
				Logger.log_i(self, " From host: change state to PENDING_SYNC_BEFORE_LOAD_RACE")
				_state_lobby = STATE_LOBBY.PENDING_SYNC_BEFORE_LOAD_RACE
		TYPE_DATA.PEER_IS_HERE:
			_peers_is_here[data.peer_id] = 0



func _add_peer_to_lobby(id_peer: String, is_player: bool) -> void :
	if _peers.has(id_peer):
		return

	var peer = PEER_LOBBY_PKG.instance()
	peer.name = id_peer
	peer.peer_id = id_peer
	peer.is_player = is_player
	peer.icon_player = Singletones.get_Network().api.get_icon_player_from_peer_id(id_peer)
	if is_player:
		peer.is_host = Singletones.get_Network().api.is_host()
		var list_races : Array = Singletones.get_RaceSetup().get_list_races_without_passed(_count_track)
		list_races.shuffle()
		peer.track_num = list_races[0]
		Logger.log_i(self, " ID ", Singletones.get_Network().api.get_peer_id(), "   Set for peer num track ", peer.track_num)
	_peers_node.add_child(peer)

	_peers[id_peer] = peer
	Logger.log_i(self, " ID " + str(Singletones.get_Network().api.get_peer_id()) + "   Add to lobby peer ID ", id_peer, "   Peers ", _peers)
	
	_peers_is_here[id_peer] = 0
	
	if not _peers.empty() and not _peer_id_self == "":
		_peers[_peer_id_self].is_host = Singletones.get_Network().api.is_host()
		for key in _peers:
			_peers[key].need_update_data()


func _add_self_to_lobby(id_peer: String) -> void :
	_add_peer_to_lobby(id_peer, true)

func add_network_peer_to_lobby(id_peer: String) -> void :
	if _timers_del_network_peer.has_node(id_peer):
		_timers_del_network_peer.get_node(id_peer).stop()
		_timers_del_network_peer.get_node(id_peer).queue_free()
	_add_peer_to_lobby(id_peer, false)



func _is_lobby_synchronized() -> bool :
	var all_ready := true
	for peer in _peers.values():
		if not peer.data_ready:
			all_ready = false
	return all_ready

func _is_all_finished_load_race() -> bool :
	var all_finished_load_race := true
	for peer in _peers.values():
		if not peer.finished_load_race:
			all_finished_load_race = false
	return all_finished_load_race


func _NetworkLobby_tree_exiting():
	Singletones.get_Network().api.del_object_update(get_path())


func _on_TimerCheckStartRace_timeout():
	match _state_lobby:
		STATE_LOBBY.PENDING_ADDED_PEERS:
			#print(self, " STATE: PENDING_ADDED_PEERS")
			_peers[_peer_id_self].is_host = Singletones.get_Network().api.is_host()
			for key in _peers:
				_peers[key].need_update_data()
			if Singletones.get_Network().api.is_host():
				#print(self, " Send signal PEER IS HOST")
				emit_signal("self_peer_is_host")
			else:
				#print(self, " Send signal PEER IS NOT HOST")
				emit_signal("self_peer_is_not_host")
		STATE_LOBBY.PENDING_SYNC_BEFORE_LOAD_RACE:
			#print(self, " STATE: PENDING_SYNC_BEFORE_LOAD_RACE")
			var key = get_path()
			Singletones.get_Network().api.setup_data(key, _data_network_change_state_to_race)
			Singletones.get_Network().api.send_data_to_all()
			
			if _is_lobby_synchronized() and _peers.size() > 1:
				_state_lobby = STATE_LOBBY.PENDING_ALL_FINISHED_LOAD_RACE
				#print(self, " Lobby ready for race. Count peers", _peers.size())
				#print(self, " Pending all load race...")
				emit_signal("lobby_ready_for_race")
			else :
				Logger.log_i(self, " is not lobby synchronized... ")
		STATE_LOBBY.PENDING_ALL_FINISHED_LOAD_RACE:
			#print(self, " STATE: PENDING_ALL_FINISHED_LOAD_RACE")
			var key = get_path()
			Singletones.get_Network().api.setup_data(key, _data_network_change_state_to_race)
			Singletones.get_Network().api.send_data_to_all()
			
			if _is_all_finished_load_race() and _is_lobby_synchronized():
				_state_lobby = STATE_LOBBY.NONE
				Logger.log_i(self, " All finished load race")
				emit_signal("all_finished_load_race")


func _on_TimerCheckDisconectPeers_timeout():
	for key in _peers_is_here:
		if not key == _peer_id_self:
			_peers_is_here[key] += 1
			if _peers_is_here[key] >= TIME_DISC_NETWORK_PEER_BEFORE_DEL:
				Logger.log_i(self, " ID " + str(Singletones.get_Network().api.get_peer_id()) + "   Time disconect >= ", TIME_DISC_NETWORK_PEER_BEFORE_DEL,"   DEL peer ID ", key)
				_del_peer_from_lobby(key)
				emit_signal("del_peer_after_time_disconect", key)
	
	var key = get_path()
	_data_network_peer_is_here.peer_id = _peer_id_self
	Singletones.get_Network().api.setup_data(key, _data_network_peer_is_here)
	Singletones.get_Network().api.send_data_to_all()


func _on_TimerDelNetworkPeer_timeout(id_peer: String):
	Logger.log_i(self, " timeout timer del network peer", id_peer)
	_del_peer_from_lobby(id_peer)
	if _timers_del_network_peer.has_node(id_peer):
		_timers_del_network_peer.get_node(id_peer).stop()
		_timers_del_network_peer.get_node(id_peer).queue_free()


