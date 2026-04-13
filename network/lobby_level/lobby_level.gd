extends Node

signal update_lobby(peers)
signal stoped_lobby()

const NetworkConst := preload("res://content/network/network_const.gd")

const PEER_LOBBY_PKG := preload("res://content/network/lobby_level/peer_lobby_level.tscn")
const LIST_PLAYERS := preload("res://content/ui/network/list_players_in_game/list_players_in_game_mp.gd")

onready var _peers_node := $PeersLobby
onready var _timer_update := $TimerUpdate


#var list_players : LIST_PLAYERS = null
var pos_ivent := Vector3.ZERO
var need_dist := 12.0
var max_players := 0

var _peer_self := ""


# network
enum TYPE_DATA {
	UPDATE_PEER
}

enum NAME_DATA {
	TYPE_UPDATE,
	TYPE,
	IDX_OBJ,
}


func try_start_lobby(pos: Vector3, max_pl: int) -> bool :
	Logger.log_i(self, " Try start lobby level")
	print(self, " Pos - ", pos)
	print(self, " Max players - ", max_pl)
	_clear_peers()
	if pos == Vector3.ZERO:
		Logger.log_i(self, " Lobby NOT start. Pos is ZERO")
		return false
	if max_pl < 1:
		Logger.log_i(self, " Lobby NOT start. Max players < 1 - ", max_pl)
		return false
	pos_ivent = pos
	max_players = max_pl
	
	
	
	var pls : Array = _get_network_players_in_lobby()
	print(self, " Network Players in lobby - ", pls)
	if pls.size() >= max_players:
		Logger.log_i(self, " Lobby NOT start. Count network players >= Max players",
			"   Count network players - ", pls.size(),
			"   Max players - ", max_players)
		stop_lobby()
		return false
	
	if Singletones.get_Global().player_character and is_instance_valid(Singletones.get_Global().player_character):
		Singletones.get_Global().player_character.in_lobby = true
		Singletones.get_Global().player_character.send_in_lobby(true)
	else:
		Logger.log_i(self, " Lobby NOT start. Player character is NULL or NOT instance valid")
		stop_lobby()
		return false
	
	_start_lobby()
	Logger.log_i(self, " Start lobby level SUCCESS")
	return true

func _start_lobby() -> void :
	_timer_update.start()
	_update_lobby()

func stop_lobby() -> void :
	_timer_update.stop()
	pos_ivent = Vector3.ZERO
	max_players = 0
	_clear_peers()


func get_peers_networks_players() -> Array :
	var peers := []
	for peer in _peers_node.get_children():
		if not peer.is_player:
			peers.append(peer)
	return peers


func add_peer_to_lobby(node_name: String) -> void :
	if _peers_node.has_node(node_name):
		return
	var is_player := false
	if Singletones.get_Global().player_character and is_instance_valid(Singletones.get_Global().player_character):
		var node_name_pl : String = Singletones.get_Global().player_character.name
		is_player = (node_name_pl == node_name)
	var peer = PEER_LOBBY_PKG.instance()
	peer.name = node_name
	peer.node_name = node_name
	peer.is_player = is_player
	if is_player:
		_peer_self = peer.node_name
	_peers_node.add_child(peer)
	
	Logger.log_i(self, " ID ", _peer_self, "   Add to lobby peer ID ", node_name)
	Logger.log_i(self, " peers in node ", _peers_node.get_children())

func del_peer_from_lobby(node_name: String) -> void :
	Logger.log_i(self, " del peer from lobby. Peer id ", node_name)
	if _peers_node.has_node(node_name):
		var p := _peers_node.get_node(node_name)
		p.stop_send_data()
		p.name += "del"
		p.queue_free()
		Logger.log_i(self, " ID ", _peer_self, "   DEL node from lobby peer ID ", node_name)
		Logger.log_i(self, " peers in node ", _peers_node.get_children())


func _clear_peers() -> void:
	for p in _peers_node.get_children():
		p.stop_send_data()
		p.name += "del"
		p.queue_free()


func _get_network_players_in_lobby() -> Array :
	if pos_ivent == Vector3.ZERO:
		return []
	if max_players < 1:
		return []
	
	var pls_net : Array = get_tree().get_nodes_in_group("NETWORK_PLAYER")
	var pls := []
	
	for pl_net in pls_net:
		if pl_net and is_instance_valid(pl_net):
			if pl_net.all_data_ready:
				if pl_net.in_lobby:
					var dist : float = pos_ivent.distance_to(pl_net.get_pos_network_player())
					if dist < need_dist:
						if not pl_net.is_bot:
							pls.append(pl_net)
	return pls

func _update_lobby() -> void :
	print(self, " Update lobby")
	if pos_ivent == Vector3.ZERO:
		return
	if max_players < 1:
		return
	
	var pls : Array = _get_network_players_in_lobby()
	print(self, " Network players in lobby - ", pls)
	
	var names_nodes := []
	for lp in pls:
		names_nodes.append(lp.name)
	
	for peer in _peers_node.get_children():
		if not peer.node_name in names_nodes and not peer.is_player:
			del_peer_from_lobby(peer.node_name)
	
	if Singletones.get_Global().player_character and is_instance_valid(Singletones.get_Global().player_character):
		if Singletones.get_Global().player_character.in_lobby:
			var node_name_pl : String = Singletones.get_Global().player_character.name
			add_peer_to_lobby(node_name_pl)
		else:
			stop_lobby()
			emit_signal("stoped_lobby")
			return
	else:
		stop_lobby()
		emit_signal("stoped_lobby")
		return
	
	for name_node in names_nodes:
		add_peer_to_lobby(name_node)
	
	emit_signal("update_lobby", get_peers_networks_players())
	
	Logger.log_i(self, " Peers in node - ", _peers_node.get_children())


func update_network_data(data: Dictionary) -> void :
	match data[NAME_DATA.TYPE] as int:
		TYPE_DATA.UPDATE_PEER:
			var path : String = "PeersLobby/"
			if has_node(path + str(data[NAME_DATA.IDX_OBJ])):
				var peer = get_node(path + str(data[NAME_DATA.IDX_OBJ]))
				if is_instance_valid(peer):
					if peer.has_method("update_network_data"):
						peer.update_network_data(data)



############### SYNHRONIZE LOBBY ######################



############### END SYNHRONIZE LOBBY ##################



func _on_TimerUpdate_timeout() -> void:
	_update_lobby()
