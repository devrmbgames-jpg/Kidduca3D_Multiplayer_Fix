extends Spatial

const NetworkConst := preload("res://content/network/network_const.gd")

const NETWORK_PLAYER_PATH := "res://content/character/player_network.tscn"
const NETWORK_PLAYER := preload("res://content/character/player_network.gd")

const TEAM_MARK_PATH := "res://content/houses/sports_football/team_marker.tscn"
const TEAM_MARK := preload("res://content/houses/sports_football/team_marker.gd")

const ENEMY_TR := preload("res://content/Enemy/enemy_multiplayer/enemy_multiplayer.gd")

const LEVEL_FOOTBALL_PATH := "res://content/houses/sports_football/football_mp/sports_football_mp.tscn"

onready var _network_players := $"%NetworkPlayers"
onready var _team_marks := $"%TeamMarks"
onready var _label_timer_lobby := $"%LabelTimer"

onready var _pos_start := $"%NetworkPlayers"
onready var _pos_spawn_level := $"%PosSpawnLevel"

enum NAME_DATA {
	TYPE_UPDATE,
	TYPE,
	IDX_OBJ,
	TYPE_OBJ,
}


var team_mark_pl : TEAM_MARK = null
var game = null

# Track whether we need to restore the open-game connection when exiting
var _was_in_open_game := false


func start_game() -> void :
	Logger.log_i(self, " Football lobby: start_game")
	
	Singletones.get_Global().disabled_bots = true
	
	# Disconnect from open-game session so we are not visible as an active world
	# player while searching for a football match. We reconnect when the match ends.
	_was_in_open_game = true
	Singletones.get_Network().api.force_leave_open_game = true
	Singletones.get_Network().api.leave_from_open_game()
	
	# Wait a frame so leave completes before connecting to football matchmaker
	yield(get_tree(), "idle_frame")
	if not is_instance_valid(self) or is_queued_for_deletion(): return
	
	# Connect signals from the network bridge
	var net_api = Singletones.get_Network().api
	if not net_api.is_connected("exit_from_error", self, "_on_Network_exit_from_error"):
		net_api.connect("exit_from_error", self, "_on_Network_exit_from_error")
	if not net_api.is_connected("timeout_start_football_single_game", self, "_on_Network_timeout_start_football_single_game"):
		net_api.connect("timeout_start_football_single_game", self, "_on_Network_timeout_start_football_single_game")
	if not net_api.is_connected("start_matchmaker_fooball", self, "_on_Network_start_matchmaker_fooball"):
		net_api.connect("start_matchmaker_fooball", self, "_on_Network_start_matchmaker_fooball")
	
	# Connect signals from the football lobby (separate lobby node)
	var lobby_fb = Singletones.get_Network().lobby_football
	if not lobby_fb.is_connected("lobby_ready_for_football", self, "_on_LobbyFootball_lobby_ready_for_football"):
		lobby_fb.connect("lobby_ready_for_football", self, "_on_LobbyFootball_lobby_ready_for_football")
	if not lobby_fb.is_connected("all_finished_load_football", self, "_on_LobbyFootball_all_finished_load_football"):
		lobby_fb.connect("all_finished_load_football", self, "_on_LobbyFootball_all_finished_load_football")
	if not lobby_fb.is_connected("timeout_start_single_game", self, "_on_LobbyFootball_timeout_start_single_game"):
		lobby_fb.connect("timeout_start_single_game", self, "_on_LobbyFootball_timeout_start_single_game")
	
	# Start matchmaking
	net_api.connect_to_football_loby()
	
	# Position the local player in the lobby area
	var player = Singletones.get_Global().player_character
	player.global_position = _pos_start.global_position
	Singletones.get_GameUiDelegate().share.controler.rotation.y += PI
	player.freez = false
	player.enabled = true
	
	# Place a team marker for the local player
	var team_mark : TEAM_MARK = ResourceLoader.load(TEAM_MARK_PATH, "", true).instance()
	team_mark.name = player.name
	_team_marks.add_child(team_mark)
	team_mark.player = player
	team_mark.set_side_team(randi() % TEAM_MARK.COLOR_TEAM.size())
	team_mark_pl = team_mark
	
	Singletones.get_GameUiDelegate().share.is_pause_in_popup_close = false
	
	Logger.log_i(self, " Football lobby: start_game completed, waiting for matchmaker")


func exit() -> void :
	Logger.log_i(self, " Football lobby: exit")
	
	# Tear down the running football game if it is still alive
	if game and is_instance_valid(game):
		game.exit()
		game = null
	
	# Disconnect all signals we connected in start_game
	_disconnect_signals()
	
	# Tell the network layer to leave the football session and reconnect to open game
	Singletones.get_Network().api.force_leave_open_game = false
	Singletones.get_Global().disabled_bots = false
	
	# leave_from_football_lobby also triggers reconnect to open game internally
	Singletones.get_Network().api.leave_from_football_lobby()
	
	queue_free()


func _disconnect_signals() -> void :
	var net_api = Singletones.get_Network().api
	if is_instance_valid(net_api):
		if net_api.is_connected("exit_from_error", self, "_on_Network_exit_from_error"):
			net_api.disconnect("exit_from_error", self, "_on_Network_exit_from_error")
		if net_api.is_connected("timeout_start_football_single_game", self, "_on_Network_timeout_start_football_single_game"):
			net_api.disconnect("timeout_start_football_single_game", self, "_on_Network_timeout_start_football_single_game")
		if net_api.is_connected("start_matchmaker_fooball", self, "_on_Network_start_matchmaker_fooball"):
			net_api.disconnect("start_matchmaker_fooball", self, "_on_Network_start_matchmaker_fooball")
	
	var lobby_fb = Singletones.get_Network().lobby_football
	if is_instance_valid(lobby_fb):
		if lobby_fb.is_connected("lobby_ready_for_football", self, "_on_LobbyFootball_lobby_ready_for_football"):
			lobby_fb.disconnect("lobby_ready_for_football", self, "_on_LobbyFootball_lobby_ready_for_football")
		if lobby_fb.is_connected("all_finished_load_football", self, "_on_LobbyFootball_all_finished_load_football"):
			lobby_fb.disconnect("all_finished_load_football", self, "_on_LobbyFootball_all_finished_load_football")
		if lobby_fb.is_connected("timeout_start_single_game", self, "_on_LobbyFootball_timeout_start_single_game"):
			lobby_fb.disconnect("timeout_start_single_game", self, "_on_LobbyFootball_timeout_start_single_game")


func _exit_out_game() -> void :
	Singletones.get_GameUiDelegate().share.emit_signal("close")


func connect_signal_timer_lobby(enemy_trigger: ENEMY_TR) -> void :
	if not enemy_trigger:
		return
	if not is_instance_valid(enemy_trigger):
		return
	
	if not enemy_trigger.is_connected("timer_tick", self, "_EnemyTrigger_timer_tick"):
		enemy_trigger.connect("timer_tick", self, "_EnemyTrigger_timer_tick")
	if not enemy_trigger.is_connected("timer_timeout", self, "_EnemyTrigger_timer_timeout"):
		enemy_trigger.connect("timer_timeout", self, "_EnemyTrigger_timer_timeout")


func update_network_data(data: Dictionary) -> void :
	match data[NAME_DATA.TYPE_UPDATE] as int:
		NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_PLAYER_NETWORK_LEVEL:
			var path : String = "NetworkPlayers/"
			if not has_node(path + str(data[NAME_DATA.IDX_OBJ])):
				var path_dog := "res://content/character/player_network.tscn"
				var dog = ResourceLoader.load(path_dog, "", true).instance()
				dog.name = str(data[NAME_DATA.IDX_OBJ])
				dog.is_player_in_game = true
				_network_players.add_child(dog)
				var team_mark : TEAM_MARK = ResourceLoader.load(TEAM_MARK_PATH, "", true).instance()
				team_mark.name = str(data[NAME_DATA.IDX_OBJ])
				_team_marks.add_child(team_mark)
				team_mark.player = dog
				dog.connect("tree_exited", team_mark, "queue_free")
			else:
				var player_network = get_node(path + str(data[NAME_DATA.IDX_OBJ]))
				if is_instance_valid(player_network):
					if player_network.has_method("update_network_data"):
						player_network.update_network_data(data)
		NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_LEVELS:
			match data[NAME_DATA.TYPE_OBJ] as int:
				NetworkConst.TYPE_OBJ_LEVEL.FOOTBALL_TEAM_MARK:
					var path : String = "TeamMarks/"
					var path_full : String = path + str(data[NAME_DATA.IDX_OBJ])
					if has_node(path_full):
						var team_mark = get_node(path_full)
						if is_instance_valid(team_mark):
							if team_mark.has_method("update_network_data"):
								team_mark.update_network_data(data)
				NetworkConst.TYPE_OBJ_LEVEL.FOOTBALL_BALL, \
				NetworkConst.TYPE_OBJ_LEVEL.FOOTBALL_GAME, \
				NetworkConst.TYPE_OBJ_LEVEL.FOOTBALL_BOT:
					if game and is_instance_valid(game):
						if game.has_method("update_network_data"):
							game.update_network_data(data)


var _old_sec := 0
func _EnemyTrigger_timer_tick(sec: int) -> void :
	_label_timer_lobby.text = str(sec) + "s"
	
	if sec <= 5:
		if _old_sec != sec:
			_old_sec = sec
			Haptic.play_button()


func _EnemyTrigger_timer_timeout() -> void :
	Logger.log_i(self, " Football lobby: timer timeout — spawning football game")
	
	for npl in _network_players.get_children():
		npl.in_lobby = false
		npl.in_game = true
	
	game = ResourceLoader.load(LEVEL_FOOTBALL_PATH, "", true).instance()
	game.name = "Football"
	add_child(game)
	game.global_position = _pos_spawn_level.global_position
	
	if team_mark_pl and is_instance_valid(team_mark_pl):
		game.team_color = team_mark_pl.color_team
	
	game.network_players_lobby = _network_players
	game.team_marks_lobby = _team_marks
	game.name_node_lobby = name
	game.start_game()
	
	Singletones.get_Global().setup_visible_hints_inside_game()


func _on_AreaEnteredTriggerRed_body_entered(body: Node) -> void:
	if not team_mark_pl:
		return
	if not is_instance_valid(team_mark_pl):
		return
	
	team_mark_pl.set_side_team(TEAM_MARK.COLOR_TEAM.RED)
	var player = Singletones.get_Global().player_character
	if body == player:
		Haptic.play_alert()


func _on_AreaEnteredTriggerBlue_body_entered(body: Node) -> void:
	if not team_mark_pl:
		return
	if not is_instance_valid(team_mark_pl):
		return
	
	team_mark_pl.set_side_team(TEAM_MARK.COLOR_TEAM.BLUE)
	var player = Singletones.get_Global().player_character
	if body == player:
		Haptic.play_alert()


# ── Network bridge callbacks ────────────────────────────────────────────────

func _on_Network_exit_from_error() -> void :
	Logger.log_i(self, " Football lobby: network exit from error — leaving")
	_exit_out_game()


func _on_Network_timeout_start_football_single_game() -> void :
	Logger.log_i(self, " Football lobby: matchmaking timed out — starting single player match")
	# Timeout: no opponents found. Spin up a local-only game with bots.
	_start_single_player_football()


func _on_Network_start_matchmaker_fooball() -> void :
	Logger.log_i(self, " Football lobby: matchmaker started, waiting for opponents...")
	# Update UI label to show searching state
	if _label_timer_lobby:
		_label_timer_lobby.text = "..."


# ── Football lobby sync callbacks ───────────────────────────────────────────

func _on_LobbyFootball_lobby_ready_for_football() -> void :
	Logger.log_i(self, " Football lobby: lobby_ready_for_football — spawning game")
	# All peers synced. Spawn the game immediately (no enemy trigger needed for MP).
	_EnemyTrigger_timer_timeout()


func _on_LobbyFootball_all_finished_load_football() -> void :
	Logger.log_i(self, " Football lobby: all_finished_load_football")
	# All peers finished loading. Nothing extra to do here for now.


func _on_LobbyFootball_timeout_start_single_game() -> void :
	Logger.log_i(self, " Football lobby: lobby timeout — starting single player match")
	_start_single_player_football()


# ── Single-player fallback ───────────────────────────────────────────────────

func _start_single_player_football() -> void :
	Logger.log_i(self, " Football lobby: starting single player football")
	
	# No network peers — spawn game with only bots filling both teams
	game = ResourceLoader.load(LEVEL_FOOTBALL_PATH, "", true).instance()
	game.name = "Football"
	add_child(game)
	game.global_position = _pos_spawn_level.global_position
	
	if team_mark_pl and is_instance_valid(team_mark_pl):
		game.team_color = team_mark_pl.color_team
	
	# Pass empty node containers — _init_enemys_and_friends will fill all 4 slots with bots
	game.network_players_lobby = _network_players
	game.team_marks_lobby = _team_marks
	game.name_node_lobby = name
	game.start_game()
	
	Singletones.get_Global().setup_visible_hints_inside_game()
