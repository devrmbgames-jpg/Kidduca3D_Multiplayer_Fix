extends Area

const PLAYER_NETWORK := preload("res://content/character/player_network.gd")


var pl_net : PLAYER_NETWORK = null
var is_friend := false

func _process(_delta: float) -> void:
	if not pl_net:
		return
	if not is_instance_valid(pl_net):
		return
	
	global_position = pl_net.get_pos_network_player()
