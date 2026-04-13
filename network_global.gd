extends "res://globals/singletones_v2/interfaces/INetwork.gd"

const PlatformsInfo := preload("res://content/platforms_info/platforms_info.gd")


var _inited := false

func _to_string() -> String:
	return "[NetworkGlobal]"

func load_tokens_and_init():
	if _inited : return
	_inited = true
	
	Logger.log_i(self, " load token...")
	_load_token()
	
	Logger.log_i(self, " create lobby")
	lobby = LOBBY_PKG.instance()
	add_child(lobby)
	
	lobby_football = LOBBY_FOOTBALL_PKG.instance()
	add_child(lobby_football)
	
	Logger.log_i(self, " create api")
	api = load("res://content/network/network_bridge_nakama.gd").new()
	add_child(api)
	
	Logger.log_i(self, " add object update lobby")
	Logger.log_i(self, "     completed...")

func create_token() -> void:
	randomize()
	token = ""
	for i in 16:
		token += str(randi() % 10)
	Logger.log_i(self, "Create token   ", token)
	_save_token()

func _save_token() -> void :
	var save_file = File.new()
	save_file.open(TOKEN_PATH, File.WRITE)
	save_file.store_line(token)
	save_file.close()
	print(self, " Save token   ", token)

func _load_token() -> void :
	var save_file = File.new()
	if not save_file.file_exists(TOKEN_PATH):
		create_token()
		return
	
	save_file.open(TOKEN_PATH, File.READ)
	token = save_file.get_line()
	save_file.close()
	Logger.log_i(self, " Load token   ", token)
