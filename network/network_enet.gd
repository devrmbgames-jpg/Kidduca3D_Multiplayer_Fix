extends Node
#class_name NetworkENet

var DEFAULT_PORT = 7689
const MAX_CLIENTS = 11

var _network_enet : NetworkedMultiplayerENet = null
var is_server := true

var ip_address = ""

var _upnp : UPNP = null
var external_ip = ""

func _ready():
	ip_address = IP.get_local_addresses()[3]
	print("IP local array  ", IP.get_local_addresses())

#func _connects() -> void :
#	get_tree().connect("connected_to_server", self, "_Network_connected_to_server")
#	get_tree().connect("server_disconnected", self, "_Network_server_disconnected")
#	#get_tree().connect("connection_failed", self, "_Network_connection_failed")

func _port_mapping() -> void:
	_upnp = UPNP.new()
	var discover_result = _upnp.discover(2000, 2, "InternetGatewayDevice")
	
	print("_upnp.get_gateway()   ", _upnp.get_gateway())
	print("_upnp.get_device_count()   ", _upnp.get_device_count())
	
	for i in _upnp.get_device_count():
		print("_upnp.get_device(i)   ", _upnp.get_device(i))
		print("_upnp.get_device(i).description_url   ", _upnp.get_device(i).description_url)
		print("_upnp.get_device(i).is_valid_gateway()   ", _upnp.get_device(i).is_valid_gateway())
		print("_upnp.get_device(i).igd_status   ", _upnp.get_device(i).igd_status)
		print("_upnp.get_device(i).igd_control_url   ", _upnp.get_device(i).igd_control_url)
		print("_upnp.get_device(i).igd_our_addr   ", _upnp.get_device(i).igd_our_addr)
		print("_upnp.get_device(i).igd_service_type   ", _upnp.get_device(i).igd_service_type)
		print("_upnp.get_device(i).service_type   ", _upnp.get_device(i).service_type)
		print("_upnp.get_device(i).query_external_address()   ", _upnp.get_device(i).query_external_address())
	
	if discover_result == UPNP.UPNP_RESULT_SUCCESS:
		print("Discover success")
		if _upnp.get_gateway() and _upnp.get_gateway().is_valid_gateway():
			var map_result_upd := _upnp.add_port_mapping(DEFAULT_PORT, DEFAULT_PORT, "godot_upd", "UPD", 0)
			
			if not map_result_upd == UPNP.UPNP_RESULT_SUCCESS:
				_upnp.add_port_mapping(DEFAULT_PORT, DEFAULT_PORT, "", "UPD")
	else:
		print("Discover FAIL")
	
	external_ip = _upnp.query_external_address()
	print("External IP   ", external_ip)

func port_delete() -> void:
	if _upnp:
		_upnp.delete_port_mapping(DEFAULT_PORT, "UPD")

func create_server() -> bool:
	_port_mapping()
	
	ip_address = external_ip
	
	_network_enet = NetworkedMultiplayerENet.new()
	#_connects()
	
	print("Port server   ", DEFAULT_PORT)
	var err = _network_enet.create_server(DEFAULT_PORT, MAX_CLIENTS)
	if err == OK:
		get_tree().set_network_peer(_network_enet)
		is_server = true
		return true
	else:
		return false

func join_to_server(ip_addr: String) -> bool:
	_network_enet = NetworkedMultiplayerENet.new()
	#_connects()
	
	var err = _network_enet.create_client(ip_addr, DEFAULT_PORT)
	if err == OK:
		get_tree().set_network_peer(_network_enet)
		is_server = false
		return true
	else:
		return false

func close_connection() -> void :
	if _network_enet:
		_network_enet.close_connection()
	_network_enet = null

func leave_from_server() -> void :
	if _network_enet and not is_server:
		_network_enet.close_connection()
	_network_enet = null

func get_peer_id() -> String :
	if is_instance_valid(_network_enet):
		return str(_network_enet.get_unique_id())
	else:
		return ""


func _Network_connected_to_server() -> void:
	#print("Successfully connected to the server")
	pass

func _Network_server_disconnected() -> void:
	#print("Disconnected from the server")
	pass
