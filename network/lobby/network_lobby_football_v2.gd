extends Node

signal lobby_ready_for_football()
signal all_finished_load_football()
signal timeout_start_single_game()

const NetworkConst := preload("res://content/network/network_const.gd")

const PEER_LOBBY_PKG := preload("res://content/network/lobby/peer_lobby_football_v2.tscn")

onready var _peers_node := $PeersLobby

var _peer_self : Node = null

func _ready() -> void:
	connect("tree_exiting", self, "_NetworkLobby_tree_exiting")


################## START LOBBY ########################
func start_lobby() -> void :
	Logger.log_i(self, " Start lobby")
	
	Singletones.get_Network().api.add_object_update(get_path(), self)
	
	var id_peers : Array = Singletones.get_Network().api.get_peers_id()
	var peer_id_self = Singletones.get_Network().api.get_peer_id()
	Logger.log_i(self, " Peers ID ", id_peers)
	Logger.log_i(self, " Peer self ID ", peer_id_self)
	
	_add_self_to_lobby(peer_id_self)
	
	for i in id_peers.size():
		if not id_peers[i] == peer_id_self:
			add_peer_to_lobby(id_peers[i])
	
	_need_update_all_peers()
	get_tree().create_timer(3.0).connect("timeout", self, "_pending_synchronize_lobby")


func _pending_synchronize_lobby() -> void :
	if not Singletones.get_Network().api.is_in_lobby():
		return
	
	if _is_lobby_synchronized() and has_host_in_lobby():
		var peers : Array = get_peers_sort()
		peers.invert()
		var time := 0.5
		var step := 0.5
		for peer in peers:
			if peer.peer_id == Singletones.get_Network().api.get_peer_id():
				get_tree().create_timer(time).connect("timeout", self, "_emit_signal_start_football")
				break
			time += step
		_pending_load_football()
		return
	
	get_tree().create_timer(0.5).connect("timeout", self, "_pending_synchronize_lobby")


func _pending_load_football() -> void :
	if not Singletones.get_Network().api.is_in_lobby():
		return
	
	if _is_all_load_football():
		emit_signal("all_finished_load_football")
		return
	
	get_tree().create_timer(0.5).connect("timeout", self, "_pending_load_football")


func _emit_signal_start_football() -> void :
	Singletones.get_Network().api.is_loading_football = true
	emit_signal("lobby_ready_for_football")


func _is_lobby_synchronized() -> bool :
	for peer in _peers_node.get_children():
		if is_instance_valid(peer):
			if not peer.data_ready:
				return false
	return true


func _need_update_all_peers() -> void :
	for peer in _peers_node.get_children():
		if is_instance_valid(peer):
			if not peer.is_player:
				peer.data_ready = false


func _is_all_load_football() -> bool :
	for peer in _peers_node.get_children():
		if is_instance_valid(peer):
			if not peer.finished_load_football:
				return false
	return true
################### START LOBBY END ####################


func leave_from_lobby() -> void :
	Logger.log_i(self, " leave from lobby")
	for peer in _peers_node.get_children():
		if is_instance_valid(peer):
			peer.stop_send_data()
	for i in _peers_node.get_child_count():
		_peers_node.get_child(i).name = "del_" + str(i)
		_peers_node.get_child(i).queue_free()
	_peer_self = null


func get_peers() -> Array :
	return _peers_node.get_children()


func get_peer_self() :
	return _peer_self


func get_peers_id() -> Array :
	var peers_id := []
	for peer in _peers_node.get_children():
		if is_instance_valid(peer):
			peers_id.append(peer.peer_id)
	return peers_id


func get_peers_count() -> int :
	return _peers_node.get_child_count()


func get_peers_sort() -> Array :
	var peers_dict := {}
	for peer in _peers_node.get_children():
		peers_dict[peer.peer_id] = peer
	
	var peers_id : Array = peers_dict.keys()
	peers_id.sort()
	
	var peers_arr := []
	for peer_id in peers_id:
		peers_arr.append(peers_dict[peer_id])
	
	return peers_arr


func get_peer_host() :
	var peers : Array = get_peers_sort()
	for peer in peers:
		if is_instance_valid(peer):
			if peer.is_host:
				return peer
	return peers[0]


func has_host_in_lobby() -> bool :
	for peer in _peers_node.get_children():
		if is_instance_valid(peer):
			if peer.is_host:
				return true
	return false




func set_team(_team: int) -> void :
	pass


func _add_self_to_lobby(id_peer: String) -> void :
	Logger.log_i(self, " add SELF peer ", id_peer)
	add_peer_to_lobby(id_peer)


func add_peer_to_lobby(id_peer: String) -> void :
	if _peers_node.has_node(id_peer):
		return
	var is_player = (Singletones.get_Network().api.get_peer_id() == id_peer)
	var peer = PEER_LOBBY_PKG.instance()
	peer.name = id_peer
	peer.peer_id = id_peer
	peer.is_player = is_player
	if is_player:
		peer.id_team = Singletones.get_GameSaveCloud().game_state.id_team
		peer.idx_character = Singletones.get_GameSaveCloud().game_state.current_charscter_idx
		_peer_self = peer
	_peers_node.add_child(peer)
	
	Logger.log_i(self, " ID ", Singletones.get_Network().api.get_peer_id(), "   Add to lobby peer ID ", id_peer)
	Logger.log_i(self, " peers in node ", _peers_node.get_children())


func del_peer_from_lobby(id_peer: String) -> void :
	Logger.log_i(self, " del peer from lobby. Peer id ", id_peer)
	if _peers_node.has_node(id_peer):
		var p := _peers_node.get_node(id_peer)
		Singletones.get_Network().api.del_object_update(p.get_path())
		p.stop_send_data()
		p.name += "del"
		p.queue_free()
		Logger.log_i(self, " ID ", Singletones.get_Network().api.get_peer_id(), "   DEL node from lobby peer ID ", id_peer)
		Logger.log_i(self, " peers in node ", _peers_node.get_children())


func update_network_global_data(data: Dictionary, peer_id: String) -> void :
	var path_local : String = "PeersLobby/" + peer_id
	var node = null
	if has_node(path_local):
		node = get_node(path_local)
	if node:
		if is_instance_valid(node):
			if node.has_method("update_network_data"):
				node.update_network_data(data)
#			else :
#				Logger.log_i(self, " object - ", path_local, " method is not found")
#		else :
#			Logger.log_i(self, " object - ", path_local, " is invalid!")
#	else :
#		Logger.log_i(self, " object - ", path_local, " not found!")


func stop_send_data_all_peers() -> void :
	for peer in _peers_node.get_children():
		if is_instance_valid(peer):
			peer.stop_send_data()


func _NetworkLobby_tree_exiting():
	Singletones.get_Network().api.del_object_update(get_path())

