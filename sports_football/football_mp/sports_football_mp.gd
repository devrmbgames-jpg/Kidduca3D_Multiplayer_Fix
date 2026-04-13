extends Spatial

const Analitics := preload("res://content/analitics/analitics.gd")
const AchivmentsConsts := preload("res://content/achivment/achivment_consts.gd")
const PlatformsInfo := preload("res://content/platforms_info/platforms_info.gd")
const RewardItemsConst := preload("res://content/ui/reward_items/reward_items_const.gd")
const NetworkConst := preload("res://content/network/network_const.gd")

const TEAM_MARK := preload("res://content/houses/sports_football/team_marker.gd")

const AREA_ALLOC_PL_NET_PATH := "res://content/houses/sports_football/football_mp/area_allocation_pl_net.tscn"
const AREA_ALLOC_PL_NET := preload("res://content/houses/sports_football/football_mp/area_allocation_pl_net.gd")

const BOT_PATH := "res://content/houses/sports_football/football_mp/enemy_football_mp.tscn"
const BOT := preload("res://content/houses/sports_football/football_mp/enemy_football_mp.gd")

const PLAYER_NETWORK := preload("res://content/character/player_network.gd")

const ICON_KICK_FOOTBAL := preload("res://resources/ui/icons/football_kick_icon.png")

const COUNT_PLAYERS_IN_TEAM := 4

var SCORE_MAX = 4

enum BALL_ON {
	NONE,
	ENEMYS,
	FRIENDS
}

enum TWEEN {
	NONE,
	CAMERA_LEVEL,
	CAMERA_PLAYER,
	ROTATE
}

# ── Scene nodes ───────────────────────────────────────────────────────────────
onready var _ball := $BallMP
onready var _pos_spawn_ball := $PosSpawnBall
onready var _pos_character_start := $PosCharacterStart
onready var _area_trap_ball_player := $TrapBallPlayer
onready var _pos_goal_player := $Gates/PosGoalPlayer
onready var _pos_goal_pl_red := $Gates/PosGoalPlayerRed
onready var _pos_goal_pl_blue := $Gates/PosGoalPlayerBlue
onready var _pos_gate_enemy := $Gates/PosGateEnemy
onready var _pos_gate_friend := $Gates/PosGateFriend

onready var _pos_start_team_red := $PosStartTeamRed
onready var _pos_start_team_blue := $PosStartTeamBlue

onready var _poses_spawn_red_pl := $PosesSpawnRed
onready var _poses_spawn_blue_pl := $PosesSpawnBlue

onready var _areas_alloc_pl_net := $AreasAllocPlNet

onready var _enemys := $Enemys
onready var _friends := $Friends

onready var _goalkeep_enemy := $GoalKeepers/goalkeeper_enemy
onready var _goalkeep_friend := $GoalKeepers/goalkeeper_friend

onready var _gate_enemy := $Gates/GateEnemy
onready var _gate_friend := $Gates/GateFriend

onready var _fans := $Fans
onready var _shapes := $Shapes
onready var _characters := $Characters

onready var _camera := $Camera
onready var _animation_camera := $Camera/AnimationPlayerCamera
onready var _tween := $Tween
onready var _animation := $AnimationPlayer
onready var _audio_dialog := $AudioDialog

# ── UI ────────────────────────────────────────────────────────────────────────
onready var _score_shapes_friend := $"%ScoreShapesFriend"
onready var _score_shapes_enemy  := $"%ScoreShapesEnemy"
onready var _score_back_friend   := $"%ScoreBackFriend"
onready var _score_back_enemy    := $"%ScoreBackEnemy"
onready var _animation_label_start := $"%AnimationPlayerLabelStart"
onready var _score_icon_friend   := $"%TextureRectFriend"
onready var _score_icon_enemy    := $"%TextureRectEnemy"
onready var _hint_mobile         := $"%HintMobile"
onready var _area_hint_mobile    := $"%AreaHintMobile"
onready var _timer_hint_mobile   := $TimerHintMobile

# ── Runtime state ─────────────────────────────────────────────────────────────
onready var _ball_on = BALL_ON.NONE
onready var _timer_spawn_ball : SceneTreeTimer = get_tree().create_timer(0.0)

var _round          := 0
var _score_friend   := 0
var _score_enemy    := 0

var _is_ball_traped_player := false
onready var _timer_kick_ball : SceneTreeTimer = get_tree().create_timer(0.0)

var _shapes_list : Array
var _camera_player_rotation  := Vector2.ZERO
var _camera_level_start_trans : Transform
var _current_tween            = TWEEN.NONE
var _character_friend         := 1
var _character_enemy          := 1
var _success                  := false
var _is_click_right_stick     := false
var _clother_do_game          := []

# ── Lobby / multiplayer context  (set by lobby_football.gd before start_game)
var team_color             : int     = TEAM_MARK.COLOR_TEAM.RED
var network_players_lobby  : Spatial = null
var team_marks_lobby       : Spatial = null
var name_node_lobby        := ""

# True on the client that owns ball physics and bot AI (lowest sorted peer ID)
var _is_host := false

# ── Network packet definitions ────────────────────────────────────────────────
enum TYPE_DATA {
	SCORE,
	BOTS_IS_PLAYER_CONTROL,
}

enum NAME_DATA {
	TYPE_UPDATE,
	TYPE,
	IDX_OBJ,
	TYPE_OBJ,
	SCORE_RED,
	SCORE_BLUE,
	ROUND,
	BOTS_IS_PLAYER_CONTROL,
}

var _data_network_score := {
	NAME_DATA.TYPE_UPDATE : NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_LEVELS,
	NAME_DATA.TYPE        : TYPE_DATA.SCORE,
	NAME_DATA.IDX_OBJ     : "",
	NAME_DATA.TYPE_OBJ    : NetworkConst.TYPE_OBJ_LEVEL.FOOTBALL_GAME,
	NAME_DATA.SCORE_RED   : 0,
	NAME_DATA.SCORE_BLUE  : 0,
	NAME_DATA.ROUND       : 0,
}

var _data_network_bots_ctrl := {
	NAME_DATA.TYPE_UPDATE            : NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_LEVELS,
	NAME_DATA.TYPE                   : TYPE_DATA.BOTS_IS_PLAYER_CONTROL,
	NAME_DATA.IDX_OBJ                : "",
	NAME_DATA.TYPE_OBJ               : NetworkConst.TYPE_OBJ_LEVEL.FOOTBALL_GAME,
	NAME_DATA.BOTS_IS_PLAYER_CONTROL : false,
}


# ─────────────────────────────────────────────────────────────────────────────
# Per-frame
# ─────────────────────────────────────────────────────────────────────────────

func _process(_delta) -> void:
	_input_player()
	var character : Spatial = Singletones.get_Global().player_character.get_character()
	_area_trap_ball_player.global_transform.origin = character.global_transform.origin
	_area_trap_ball_player.global_rotation.y       = character.global_rotation.y


func _physics_process(_delta) -> void :
	var areas : Array = _ball.get_area_ball().get_overlapping_areas()
	_go_npc_to_ball(areas)
	_check_ball_on(areas)
	_random_go_to_ball()


# ─────────────────────────────────────────────────────────────────────────────
# Entry / exit
# ─────────────────────────────────────────────────────────────────────────────

func start_game() -> void :
	_success = false
	_camera_level_start_trans = _camera.global_transform

	if Singletones.get_Global().ui_touch_controller:
		Singletones.get_Global().ui_touch_controller.get_stick_right().connect(
				"click", self, "_StickRight_click")
		Singletones.get_Global().ui_touch_controller.change_icon_jumo_to(ICON_KICK_FOOTBAL)

	_init_input_map()
	_init_color_team()
	_init_enemys_and_friends()
	_init_player()
	_init_players_network()
	_init_poses_players_and_bots()
	_init_shapes()
	_init_ui()
	_init_fans()
	_init_gate_and_side()

	_determine_host()

	var net_api = Singletones.get_Network().api
	if net_api and not net_api.is_connected("host_changed", self, "_on_network_host_changed"):
		net_api.connect("host_changed", self, "_on_network_host_changed")

	_welcome()

	Analitics.send_event_level_start(
			AchivmentsConsts.FAVORITE_SOCCER.to_lower(), 1, "none", "world_of_sorting")


func exit() -> void :
	if Singletones.get_Global().ui_touch_controller:
		Singletones.get_Global().ui_touch_controller.get_stick_right().disconnect(
				"click", self, "_StickRight_click")
		Singletones.get_Global().ui_touch_controller.reset_icon_jump()

	InputMap.action_erase_events("jump_forward")
	InputMap.action_erase_events("active")
	var ev = InputEventKey.new()
	ev.scancode = KEY_SPACE
	InputMap.action_add_event("jump_forward", ev)
	ev = InputEventKey.new()
	ev.scancode = KEY_E
	InputMap.action_add_event("active", ev)

	var player_char = Singletones.get_Global().player_character.get_character()
	player_char.fcm.pop_state()
	player_char.fcm.push_state(player_char.fcm.IDLE)
	player_char.update_reward_items(Singletones.get_Global().last_clother)

	var net_api = Singletones.get_Network().api
	if net_api and net_api.is_connected("host_changed", self, "_on_network_host_changed"):
		net_api.disconnect("host_changed", self, "_on_network_host_changed")

	queue_free()

	Analitics.send_event_level_end(
			AchivmentsConsts.FAVORITE_SOCCER.to_lower(), 1, "none",
			"win" if _success else "close", "world_of_sorting")


func _exit_out_game() -> void :
	Singletones.get_GameUiDelegate().share.emit_signal("close")


func _play_dialog(key_text: String) -> void :
	_audio_dialog.stream = ResourceLoader.load(
			Singletones.get_LocaleSounds().get_sound_path(key_text), "", true)
	_audio_dialog.play()


# ─────────────────────────────────────────────────────────────────────────────
# Host determination  — lowest sorted peer ID becomes host
# ─────────────────────────────────────────────────────────────────────────────

func _determine_host() -> void :
	var ids := []
	var my_id : String = Singletones.get_Global().player_character.name
	ids.append(my_id)

	if network_players_lobby and is_instance_valid(network_players_lobby):
		for npl in network_players_lobby.get_children():
			ids.append(npl.name)

	ids.sort()

	if ids[0] == my_id:
		_become_host()
	else:
		_lose_host()


func _become_host() -> void :
	Logger.log_i(self, " Become match host")
	_is_host = true
	_ball.is_player = true
	_set_control_bots(true)
	_send_score()   # push current state to late-joiners


func _lose_host() -> void :
	Logger.log_i(self, " Lose match host")
	_is_host = false
	_ball.is_player = false
	_set_control_bots(false)


# ─────────────────────────────────────────────────────────────────────────────
# Input map
# ─────────────────────────────────────────────────────────────────────────────

func _init_input_map() -> void :
	InputMap.action_erase_events("jump_forward")
	InputMap.action_erase_events("active")
	var ev = InputEventKey.new()
	ev.scancode = KEY_SPACE
	InputMap.action_add_event("active", ev)

	var evnt := InputEventAction.new()
	evnt.action = "active"
	evnt.pressed = true
	evnt.strength = 1.0
	Input.parse_input_event(evnt)
	yield(get_tree().create_timer(0.05), "timeout")
	evnt = InputEventAction.new()
	evnt.action = "active"
	evnt.pressed = false
	evnt.strength = 0.0
	Input.parse_input_event(evnt)


# ─────────────────────────────────────────────────────────────────────────────
# Team colour balance  (cap each team at COUNT_PLAYERS_IN_TEAM)
# ─────────────────────────────────────────────────────────────────────────────

func _init_color_team() -> void :
	if not team_marks_lobby or not is_instance_valid(team_marks_lobby):
		return

	var color_pl := {}
	for tml in team_marks_lobby.get_children():
		color_pl[tml.name] = tml

	var names_pl : Array = color_pl.keys()
	if names_pl.empty():
		return
	names_pl.sort()

	var count_red  := 0
	var count_blue := 0
	for nm in names_pl:
		var mark : TEAM_MARK = color_pl[nm]
		if not mark or not is_instance_valid(mark):
			continue
		if mark.color_team == TEAM_MARK.COLOR_TEAM.RED:
			count_red += 1
			if count_red > COUNT_PLAYERS_IN_TEAM:
				mark.set_side_team(TEAM_MARK.COLOR_TEAM.BLUE)
		else:
			count_blue += 1
			if count_blue > COUNT_PLAYERS_IN_TEAM:
				mark.set_side_team(TEAM_MARK.COLOR_TEAM.RED)


# ─────────────────────────────────────────────────────────────────────────────
# Bots  — fill empty team slots with AI players
# ─────────────────────────────────────────────────────────────────────────────

func _init_enemys_and_friends() -> void :
	var count_pl_red  := 0
	var count_pl_blue := 0

	if team_marks_lobby and is_instance_valid(team_marks_lobby):
		for tml in team_marks_lobby.get_children():
			if tml.color_team == TEAM_MARK.COLOR_TEAM.RED: count_pl_red  += 1
			else:                                           count_pl_blue += 1

	var count_bot_red  := int(max(COUNT_PLAYERS_IN_TEAM - count_pl_red,  0))
	var count_bot_blue := int(max(COUNT_PLAYERS_IN_TEAM - count_pl_blue, 0))

	# Seeded RNG → identical bot skins on every client
	var rng := RandomNumberGenerator.new()
	var ids := []
	ids.append(Singletones.get_Global().player_character.name)
	if network_players_lobby and is_instance_valid(network_players_lobby):
		for npl in network_players_lobby.get_children():
			ids.append(npl.name)
	ids.sort()
	rng.seed = int(ids[0]) if not ids.empty() else 0

	var char_list : Array = _characters.get_characters_list()

	for i in count_bot_red:
		var bot : BOT = ResourceLoader.load(BOT_PATH, "", true).instance()
		bot.name = "f_%d" % i
		_friends.add_child(bot)
		bot.name_node_lobby  = name_node_lobby
		bot.global_position  = _pos_start_team_red.global_position \
				+ Vector3(randf() * 14.0 - 7.0, 0.0, randf() * 14.0 - 7.0)
		bot.rotation.y       = PI
		bot.is_friend        = true
		bot.set_gate_pos(_pos_gate_enemy)
		bot.set_ball(_ball)
		bot.is_player_control = false   # host enables after _become_host()
		var cp : Array = _characters.get_character_model_path(
				char_list[rng.randi() % char_list.size()])
		bot.change_skin(cp[0])
		bot.update_reward_items(_get_random_clothes(rng))

	for i in count_bot_blue:
		var bot : BOT = ResourceLoader.load(BOT_PATH, "", true).instance()
		bot.name = "e_%d" % i
		_enemys.add_child(bot)
		bot.name_node_lobby  = name_node_lobby
		bot.global_position  = _pos_start_team_blue.global_position \
				+ Vector3(randf() * 14.0 - 7.0, 0.0, randf() * 14.0 - 7.0)
		bot.is_friend        = false
		bot.set_gate_pos(_pos_gate_friend)
		bot.set_ball(_ball)
		bot.is_player_control = false
		var cp : Array = _characters.get_character_model_path(
				char_list[rng.randi() % char_list.size()])
		bot.change_skin(cp[0])
		bot.update_reward_items(_get_random_clothes(rng))


func _get_random_clothes(rng: RandomNumberGenerator) -> Array :
	var clothes := [
		RewardItemsConst.hats_list     [rng.randi() % RewardItemsConst.hats_list.size()],
		RewardItemsConst.skirts_list   [rng.randi() % RewardItemsConst.skirts_list.size()],
		RewardItemsConst.capes_list    [rng.randi() % RewardItemsConst.capes_list.size()],
		RewardItemsConst.bows_list     [rng.randi() % RewardItemsConst.bows_list.size()],
		RewardItemsConst.glasses_list  [rng.randi() % RewardItemsConst.glasses_list.size()],
		RewardItemsConst.amulets_list  [rng.randi() % RewardItemsConst.amulets_list.size()],
		RewardItemsConst.brasletes_list[rng.randi() % RewardItemsConst.brasletes_list.size()],
	]
	for i in clothes.size():
		if rng.randi() % 100 > 35: clothes[i] = ""
	if rng.randi() % 100 > 30:    clothes[1] = ""
	return clothes


# ─────────────────────────────────────────────────────────────────────────────
# Local player  — position + dress
# ─────────────────────────────────────────────────────────────────────────────

func _init_player() -> void :
	var player = Singletones.get_Global().player_character

	_clother_do_game = player.get_reward_items()
	if not (RewardItemsConst.HAT_FOOTBAL_TEAM_BLUE  in _clother_do_game or
			RewardItemsConst.CAPE_FOOTBAL_TEAM_BLUE  in _clother_do_game or
			RewardItemsConst.CAPE_FOOTBAL_TEAM_RED   in _clother_do_game or
			RewardItemsConst.HAT_FOOTBAL_TEAM_RED    in _clother_do_game):
		Singletones.get_Global().last_clother = _clother_do_game

	match team_color:
		TEAM_MARK.COLOR_TEAM.RED:
			player.global_position = _pos_start_team_red.global_position \
					+ Vector3(randf() * 10.0 - 5.0, 0.0, randf() * 10.0 - 5.0)
			player.direction = Vector3.FORWARD
			_camera_player_rotation = Vector2.ZERO
			player.update_reward_items([
				RewardItemsConst.HAT_FOOTBAL_TEAM_RED,
				RewardItemsConst.CAPE_FOOTBAL_TEAM_RED,
			])

		TEAM_MARK.COLOR_TEAM.BLUE:
			player.global_position = _pos_start_team_blue.global_position \
					+ Vector3(randf() * 10.0 - 5.0, 0.0, randf() * 10.0 - 5.0)
			player.direction = Vector3.BACK
			_camera_player_rotation = Vector2(0.0, PI)
			player.update_reward_items([
				RewardItemsConst.HAT_FOOTBAL_TEAM_BLUE,
				RewardItemsConst.CAPE_FOOTBAL_TEAM_BLUE,
			])

	Singletones.get_GameUiDelegate().share.controler.rotation.y = _camera_player_rotation.y
	Singletones.get_GameUiDelegate().share.controler.rotation.x = _camera_player_rotation.x
	player.freez      = true
	player.enabled    = false
	player.move_force = false
	player.visible    = true


# ─────────────────────────────────────────────────────────────────────────────
# Network player proxies  — area that follows each remote player's position
# ─────────────────────────────────────────────────────────────────────────────

func _init_players_network() -> void :
	if not network_players_lobby or not is_instance_valid(network_players_lobby):
		return
	for npl in network_players_lobby.get_children():
		var area : AREA_ALLOC_PL_NET = \
				ResourceLoader.load(AREA_ALLOC_PL_NET_PATH, "", true).instance()
		area.name   = npl.name
		_areas_alloc_pl_net.add_child(area)
		area.pl_net = npl
		npl.connect("tree_exited", self, "_on_network_player_exited", [area])


func _on_network_player_exited(area : AREA_ALLOC_PL_NET) -> void :
	if not area or not is_instance_valid(area): return
	area.name += "_del"
	area.queue_free()


# ─────────────────────────────────────────────────────────────────────────────
# Spawn positions  — sorted peer IDs → deterministic slot assignment
# ─────────────────────────────────────────────────────────────────────────────

func _init_poses_players_and_bots() -> void :
	if not team_marks_lobby   or not is_instance_valid(team_marks_lobby):   return
	if not network_players_lobby or not is_instance_valid(network_players_lobby): return

	var color_pl := {}
	for tml in team_marks_lobby.get_children():
		color_pl[tml.name] = tml.color_team

	var ids_pl := {}
	ids_pl[Singletones.get_Global().player_character.name] = \
			Singletones.get_Global().player_character
	for npl in network_players_lobby.get_children():
		ids_pl[npl.name] = npl

	var names_pl : Array = ids_pl.keys()
	if names_pl.empty(): return
	names_pl.sort()

	var idx_red  := -1
	var idx_blue := -1

	for nm in names_pl:
		var is_red : bool = \
				color_pl.get(nm, TEAM_MARK.COLOR_TEAM.RED) == TEAM_MARK.COLOR_TEAM.RED
		if is_red:
			idx_red += 1
			if idx_red < _poses_spawn_red_pl.get_child_count() and ids_pl.has(nm):
				var node = ids_pl[nm]
				if node is PLAYER_NETWORK:
					node.set_rotate_y(0.0)
					node.set_position(
							_poses_spawn_red_pl.get_child(idx_red).global_position)
					node.update_clothes([
						RewardItemsConst.HAT_FOOTBAL_TEAM_RED,
						RewardItemsConst.CAPE_FOOTBAL_TEAM_RED,
					])
				else:
					node.global_position = \
							_poses_spawn_red_pl.get_child(idx_red).global_position
		else:
			idx_blue += 1
			if idx_blue < _poses_spawn_blue_pl.get_child_count() and ids_pl.has(nm):
				var node = ids_pl[nm]
				if node is PLAYER_NETWORK:
					node.set_rotate_y(PI)
					node.set_position(
							_poses_spawn_blue_pl.get_child(idx_blue).global_position)
					node.update_clothes([
						RewardItemsConst.HAT_FOOTBAL_TEAM_BLUE,
						RewardItemsConst.CAPE_FOOTBAL_TEAM_BLUE,
					])
				else:
					node.global_position = \
							_poses_spawn_blue_pl.get_child(idx_blue).global_position

	for bot in _friends.get_children():
		idx_red += 1
		if idx_red < _poses_spawn_red_pl.get_child_count():
			bot.global_position = \
					_poses_spawn_red_pl.get_child(idx_red).global_position

	for bot in _enemys.get_children():
		idx_blue += 1
		if idx_blue < _poses_spawn_blue_pl.get_child_count():
			bot.global_position = \
					_poses_spawn_blue_pl.get_child(idx_blue).global_position


# ─────────────────────────────────────────────────────────────────────────────
# Shapes  — seeded shuffle so all clients show the same texture sequence
# ─────────────────────────────────────────────────────────────────────────────

func _init_shapes() -> void :
	_shapes_list = _shapes.get_shapes_list()

	var ids := []
	ids.append(Singletones.get_Global().player_character.name)
	if network_players_lobby and is_instance_valid(network_players_lobby):
		for npl in network_players_lobby.get_children():
			ids.append(npl.name)

	ids.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(ids[0]) if not ids.empty() else 0

	for i in _shapes_list.size() - 1:
		var j : int = rng.randi_range(i, _shapes_list.size() - 1)
		var tmp   = _shapes_list[i]
		_shapes_list[i] = _shapes_list[j]
		_shapes_list[j] = tmp

	_change_mat_ball()


# ─────────────────────────────────────────────────────────────────────────────
# UI
# ─────────────────────────────────────────────────────────────────────────────

func _init_ui() -> void :
	_hint_mobile.visible      = false
	_area_hint_mobile.visible = false

	for i in _score_shapes_friend.get_child_count():
		_score_shapes_friend.get_child(i).hide_shape()
		_score_shapes_enemy.get_child(i).hide_shape()

	for i in _score_back_friend.get_child_count():
		_score_back_friend.get_child(i).visible = false
		_score_back_enemy.get_child(i).visible  = false
	for i in SCORE_MAX:
		_score_back_friend.get_child(i).visible = true
		_score_back_enemy.get_child(i).visible  = true

	_score_icon_friend.texture = _characters.get_characters_icon(_character_friend)
	_score_icon_enemy.texture  = _characters.get_characters_icon(_character_enemy)

	Singletones.get_GameUiDelegate().share.set_ui_star_visible(false)
	Singletones.get_Global().ui_touch_controller.show_hints_wasd_mouse()


# ─────────────────────────────────────────────────────────────────────────────
# Fans
# ─────────────────────────────────────────────────────────────────────────────

func _init_fans() -> void :
	for fan in _fans.get_children():
		get_tree().create_timer(randi() % 10 * 0.1).connect(
				"timeout", self, "_timer_fan_timeout", [fan])

func _timer_fan_timeout(fan: Spatial) -> void :
	fan.fcm.push_state(fan.FCM.ACTION)
	fan.set_action_idx(2)


# ─────────────────────────────────────────────────────────────────────────────
# Gate / side  (blue team shoots toward the red gate)
# ─────────────────────────────────────────────────────────────────────────────

func _init_gate_and_side() -> void :
	if team_color == TEAM_MARK.COLOR_TEAM.BLUE:
		_goalkeep_friend.is_friend = false
		_goalkeep_enemy.is_friend  = true
		_pos_goal_player.global_position = _pos_goal_pl_red.global_position


# ─────────────────────────────────────────────────────────────────────────────
# Camera
# ─────────────────────────────────────────────────────────────────────────────

func _welcome() -> void :
	_to_camera_level()
	_play_dialog("WELCOME_TO_THE_SOCCER_FIELD")
	_animation_camera.play("welcome")

func _begin_game() -> void :
	_hint_mobile.visible      = true
	_area_hint_mobile.visible = true
	_all_play()

func _play_animation_label_start() -> void :
	_animation_label_start.play("play")

func _to_camera_level() -> void :
	get_viewport().get_camera().target = _camera.get_path()

func _to_camera_player() -> void :
	get_viewport().get_camera().target = \
			Singletones.get_GameUiDelegate().share.character_camera_x2.get_path()

func _to_camera_level_tween(trans: Transform) -> void :
	_current_tween = TWEEN.CAMERA_LEVEL
	_tween.interpolate_property(_camera, "global_transform",
			Singletones.get_GameUiDelegate().share.character_camera_x2.global_transform,
			trans, 1.5)
	_tween.start()

func _to_camera_player_tween() -> void :
	_current_tween = TWEEN.CAMERA_PLAYER
	Singletones.get_GameUiDelegate().share.controler.rotation.y = _camera_player_rotation.y
	Singletones.get_GameUiDelegate().share.controler.rotation.x = _camera_player_rotation.x
	_tween.interpolate_property(_camera, "global_transform",
			_camera.global_transform,
			Singletones.get_GameUiDelegate().share.character_camera_x2.global_transform,
			1.5)
	_tween.start()

func _rortate_camera_player_to_spawn_ball_tween() -> void :
	if _score_friend == SCORE_MAX or _score_enemy == SCORE_MAX: return

	_current_tween = TWEEN.ROTATE
	var d2s : Vector3 = _area_trap_ball_player.global_transform.origin.direction_to(
			_pos_spawn_ball.global_transform.origin)
	d2s.y = 0.0

	var rot := Vector3.ZERO
	rot.y = d2s.angle_to(Vector3.FORWARD)
	rot.z = Singletones.get_GameUiDelegate().share.controler.rotation.z
	if _area_trap_ball_player.transform.origin.x < 0:
		rot.y = 2 * PI - rot.y
	if abs(rot.y - Singletones.get_GameUiDelegate().share.controler.rotation.y) > PI:
		rot.y -= 2 * PI

	_tween.interpolate_property(
			Singletones.get_GameUiDelegate().share.controler, "rotation",
			Singletones.get_GameUiDelegate().share.controler.rotation,
			rot, 1.0)
	_tween.start()


# ─────────────────────────────────────────────────────────────────────────────
# NPC movement helpers
# ─────────────────────────────────────────────────────────────────────────────

func _all_play() -> void :
	Singletones.get_Global().player_character.freez   = false
	Singletones.get_Global().player_character.enabled = true
	for f in _friends.get_children(): f.play_game()
	for e in _enemys.get_children():  e.play_game()
	_goalkeep_friend.play_game()
	_goalkeep_enemy.play_game()

func _all_stand() -> void :
	Singletones.get_Global().player_character.freez   = true
	Singletones.get_Global().player_character.enabled = false
	for f in _friends.get_children(): f.stand()
	for e in _enemys.get_children():  e.stand()
	_goalkeep_friend.stand()
	_goalkeep_enemy.stand()

func _go_npc_to_ball(areas: Array) -> void :
	if areas.empty():
		_go_enemy_to_ball()
		_go_friend_to_ball()

func _go_enemy_to_ball() -> void :
	if not _ball.can_trap: return
	var best_dist := 10000.0
	var best : KinematicBody = _enemys.get_child(0)
	for e in _enemys.get_children():
		e.stop_go_to_ball()
		var d : float = e.global_transform.origin.distance_to(_ball.global_transform.origin)
		if d < best_dist:
			best_dist = d
			best = e
	best.go_to_ball()

func _go_friend_to_ball() -> void :
	if not _ball.can_trap: return
	var best_dist := 10000.0
	var best : KinematicBody = _friends.get_child(0)
	for f in _friends.get_children():
		f.stop_go_to_ball()
		var d : float = f.global_transform.origin.distance_to(_ball.global_transform.origin)
		if d < best_dist:
			best_dist = d
			best = f
	best.go_to_ball()

func _check_ball_on(areas: Array) -> void :
	if areas.empty():
		_ball_on = BALL_ON.NONE
		return
	var on_e := false
	var on_f := false
	for area in areas:
		if area.is_friend: on_f = true
		else:              on_e = true
	if on_f and on_e:
		_ball_on = BALL_ON.NONE
	elif on_f:
		_ball_on = BALL_ON.FRIENDS
		for f in _friends.get_children(): f.stop_go_to_ball()
	elif on_e:
		_ball_on = BALL_ON.ENEMYS
		for e in _enemys.get_children(): e.stop_go_to_ball()

func _random_go_to_ball() -> void:
	if randi() % 60 == 0:
		if _ball_on == BALL_ON.FRIENDS: _go_enemy_to_ball()
		if _ball_on == BALL_ON.ENEMYS:  _go_friend_to_ball()

func _all_go_to_center() -> void :
	_ball.can_trap = false
	for e in _enemys.get_children():
		e.stop_go_to_ball()
		e.set_target(_pos_spawn_ball)
	for f in _friends.get_children():
		f.stop_go_to_ball()
		f.set_target(_pos_spawn_ball)

func _all_go_to_ball() -> void :
	_ball.can_trap = true
	for e in _enemys.get_children(): e.set_target(_ball)
	for f in _friends.get_children(): f.set_target(_ball)


# ─────────────────────────────────────────────────────────────────────────────
# Bot AI on/off  — only the host drives bots
# ─────────────────────────────────────────────────────────────────────────────

func _set_control_bots(turn: bool) -> void :
	for e in _enemys.get_children(): e.is_player_control = turn
	for f in _friends.get_children(): f.is_player_control = turn
	if turn:
		_send_control_bots()


# ─────────────────────────────────────────────────────────────────────────────
# Player input
# ─────────────────────────────────────────────────────────────────────────────

func _input_player() -> void :
	if Input.is_action_just_pressed("active") or _is_click_right_stick:
		_is_click_right_stick = false
		if _is_ball_traped_player:
			var d2g : Vector3 = \
					(_pos_goal_player.global_transform.origin
					 - _area_trap_ball_player.global_transform.origin)
			d2g.y = 0.0
			d2g = d2g.normalized()
			if d2g.dot(_area_trap_ball_player.get_direction()) > 0.5:
				_area_trap_ball_player.kick_ball(true, _pos_goal_player)
			else:
				_area_trap_ball_player.kick_ball(false)
		else:
			for f in _friends.get_children(): f.pass_to_player()


# ─────────────────────────────────────────────────────────────────────────────
# Ball
# ─────────────────────────────────────────────────────────────────────────────

func _spawn_ball() -> void :
	_change_mat_ball()
	_ball.global_transform.origin = _pos_spawn_ball.global_transform.origin
	_ball.linear_velocity  = Vector3.ZERO
	_ball.angular_velocity = Vector3.ZERO
	_all_go_to_ball()
	_goalkeep_enemy.look_to_ball()
	_goalkeep_friend.look_to_ball()

func _change_mat_ball() -> void :
	var icon : AtlasTexture = _shapes.get_shape_icon(_shapes_list[_round])
	var region_start := Vector2(icon.region.position.x, icon.region.position.y)
	var uv_offset    := Vector2(
			0.125 * (region_start.x / 256.0),
			0.125 * (region_start.y / 256.0))
	_ball.change_mat_ball(icon, region_start, uv_offset)

func _despawn_ball() -> void :
	_ball.global_transform.origin = _pos_spawn_ball.global_transform.origin - Vector3.UP * 100.0
	_ball.linear_velocity  = Vector3.ZERO
	_ball.angular_velocity = Vector3.ZERO


# ─────────────────────────────────────────────────────────────────────────────
# Score / victory
# ─────────────────────────────────────────────────────────────────────────────

func _great(is_friend: bool) -> void :
	var shape_icon = _shapes.get_shape_icon(_shapes_list[_round - 1])

	if is_friend:
		var idx := _score_friend - 1
		if _score_shapes_friend.get_child_count() > idx:
			_score_shapes_friend.get_child(idx).set_texture_and_show(shape_icon)
		_animation.play("goal_friend")
		_goalkeep_enemy.stop_go_to_ball()
		_goalkeep_enemy.look_to_spawn_ball()
	else:
		var idx := _score_enemy - 1
		if _score_shapes_enemy.get_child_count() > idx:
			_score_shapes_enemy.get_child(idx).set_texture_and_show(shape_icon)
		_animation.play("goal_enemy")
		_goalkeep_friend.stop_go_to_ball()
		_goalkeep_friend.look_to_spawn_ball()

	_all_go_to_center()
	Logger.log_i(self, "SCORE F:E   %d : %d" % [_score_friend, _score_enemy])

	yield(_animation, "animation_finished")

	if _score_friend == SCORE_MAX: _victory(true)
	if _score_enemy  == SCORE_MAX: _victory(false)


func _victory(is_friend: bool) -> void :
	_all_stand()
	var player_char = Singletones.get_Global().player_character.get_character()

	var win_self : bool = \
			(is_friend     and team_color == TEAM_MARK.COLOR_TEAM.RED) or \
			(not is_friend and team_color == TEAM_MARK.COLOR_TEAM.BLUE)

	if win_self:
		Singletones.get_Achivment().push_achivment(AchivmentsConsts.FAVORITE_SOCCER)
		_success = true
		player_char.fcm.pop_state()
		player_char.fcm.push_state(player_char.fcm.IDLE)
		player_char.fcm.pop_state()
		player_char.fcm.push_state(player_char.fcm.ACTION)
		player_char.set_action_idx(2)
	else:
		player_char.fcm.pop_state()
		player_char.fcm.push_state(player_char.fcm.IDLE)

	if is_friend:
		_animation.play("victory_friend")
		for f in _friends.get_children(): f.victory()
		_goalkeep_friend.victory()
	else:
		_animation.play("victory_enemy")
		for e in _enemys.get_children(): e.victory()
		_goalkeep_enemy.victory()

	_play_dialog("THE_MATCH_IS_OVER")
	_to_camera_level_tween(_camera_level_start_trans)
	_to_camera_level()


func _play_shapes_sound() -> void :
	_shapes.play_sound(_shapes_list[_round - 1])


# ─────────────────────────────────────────────────────────────────────────────
# Network send  (host only)
# ─────────────────────────────────────────────────────────────────────────────

func _send_score() -> void :
	if not _is_host: return
	_data_network_score[NAME_DATA.IDX_OBJ]    = get_parent().name
	_data_network_score[NAME_DATA.SCORE_RED]  = _score_friend
	_data_network_score[NAME_DATA.SCORE_BLUE] = _score_enemy
	_data_network_score[NAME_DATA.ROUND]      = _round
	var key := NetworkConst.GLOBAL_TYPE_DATA.OPEN_GAME
	Singletones.get_Network().api.setup_data(key, _data_network_score)
	Singletones.get_Network().api.send_data_to_all()


func _send_control_bots() -> void :
	if not _is_host: return
	_data_network_bots_ctrl[NAME_DATA.IDX_OBJ]                = get_parent().name
	_data_network_bots_ctrl[NAME_DATA.BOTS_IS_PLAYER_CONTROL] = true
	var key := NetworkConst.GLOBAL_TYPE_DATA.OPEN_GAME
	Singletones.get_Network().api.setup_data(key, _data_network_bots_ctrl)
	Singletones.get_Network().api.send_data_to_all()


# ─────────────────────────────────────────────────────────────────────────────
# Network receive  (called by lobby_football.gd → update_network_data)
# ─────────────────────────────────────────────────────────────────────────────

func update_network_data(data: Dictionary) -> void :
	match data[NAME_DATA.TYPE_OBJ] as int:

		NetworkConst.TYPE_OBJ_LEVEL.FOOTBALL_GAME:
			match data[NAME_DATA.TYPE] as int:

				TYPE_DATA.SCORE:
					# Non-host clients apply score from the host
					if not _is_host:
						_apply_score_from_network(
								data.get(NAME_DATA.SCORE_RED,  0) as int,
								data.get(NAME_DATA.SCORE_BLUE, 0) as int,
								data.get(NAME_DATA.ROUND,      0) as int)

				TYPE_DATA.BOTS_IS_PLAYER_CONTROL:
					# Host announced it owns the bots — non-hosts must release
					if not _is_host:
						_set_control_bots(false)

		NetworkConst.TYPE_OBJ_LEVEL.FOOTBALL_BALL:
			if _ball and is_instance_valid(_ball):
				_ball.update_network_data(data)

		NetworkConst.TYPE_OBJ_LEVEL.FOOTBALL_BOT:
			for f in _friends.get_children():
				if f and is_instance_valid(f): f.update_network_data(data)
			for e in _enemys.get_children():
				if e and is_instance_valid(e): e.update_network_data(data)


func _apply_score_from_network(score_red: int, score_blue: int, round_in: int) -> void :
	# Only advance if the remote score is strictly higher than local
	if score_red > _score_friend and score_blue <= _score_enemy:
		_score_friend = score_red
		_score_enemy  = score_blue
		_round = round_in
		_great(true)
	elif score_blue > _score_enemy and score_red <= _score_friend:
		_score_friend = score_red
		_score_enemy  = score_blue
		_round = round_in
		_great(false)
	elif score_red > _score_friend and score_blue > _score_enemy:
		_score_friend = score_red
		_score_enemy  = score_blue
		_round = round_in
		_great(true)


# ─────────────────────────────────────────────────────────────────────────────
# Host migration
# ─────────────────────────────────────────────────────────────────────────────

func _on_network_host_changed(new_host_id: String, old_host_id: String) -> void :
	Logger.log_i(self, " Host changed: %s → %s" % [old_host_id, new_host_id])
	var my_id : String = Singletones.get_Global().player_character.name
	if my_id == new_host_id:
		_become_host()
	else:
		_lose_host()


# ─────────────────────────────────────────────────────────────────────────────
# Signal handlers
# ─────────────────────────────────────────────────────────────────────────────

func _on_TrapBall_trap_ball():
	# Player trapped the ball — if we are the host, take ball authority
	if _is_host:
		_ball.is_player = true
	_is_ball_traped_player = true
	_set_control_bots(true)
	for f in _friends.get_children(): f.stop_go_to_ball()


func _on_TrapBallPlayer_untrap_ball():
	_is_ball_traped_player = false
	_timer_kick_ball.time_left = 0.0


func _on_GateFriend_goal():
	if not _is_host: return   # only host registers goals — prevents double-count
	_score_enemy += 1
	_round += 1
	_great(false)
	_send_score()

func _on_GateEnemy_goal():
	if not _is_host: return
	_score_friend += 1
	_round += 1
	_great(true)
	_send_score()


func _on_AreaAllocationBallFriend_body_entered(_body): _goalkeep_friend.go_to_ball()
func _on_AreaAllocationBallFriend_body_exited(_body):  _goalkeep_friend.stop_go_to_ball()
func _on_AreaAllocationBallEnemy_body_entered(_body):  _goalkeep_enemy.go_to_ball()
func _on_AreaAllocationBallEnemy_body_exited(_body):   _goalkeep_enemy.stop_go_to_ball()

func _on_goalkeeper_trap_ball():   _all_go_to_center()
func _on_goalkeeper_untrap_ball(): _all_go_to_ball()


func _on_Tween_tween_all_completed():
	if _current_tween == TWEEN.CAMERA_PLAYER:
		_current_tween = TWEEN.NONE
		Singletones.get_Global().player_character.direction = Vector3.ZERO
		Singletones.get_GameUiDelegate().share.controler.rotation.y = _camera_player_rotation.y
		Singletones.get_GameUiDelegate().share.controler.rotation.x = _camera_player_rotation.x
		_to_camera_player()

	if _current_tween == TWEEN.ROTATE:
		_current_tween = TWEEN.NONE
		_spawn_ball()

	if _current_tween == TWEEN.CAMERA_LEVEL:
		_current_tween = TWEEN.NONE
		if _score_friend == SCORE_MAX or _score_enemy == SCORE_MAX:
			_animation_camera.play("victory")


func _on_TimerHintMobile_timeout():  _hint_mobile.visible = true

func _on_Area2D_input_event(_viewport, event, _shape_idx):
	if event is InputEventScreenTouch:
		if event.pressed:
			_timer_hint_mobile.stop()
			_hint_mobile.visible = false
		else:
			_timer_hint_mobile.stop()
			_timer_hint_mobile.start()

func _StickRight_click() -> void : _is_click_right_stick = true

var _is_dialog_kick_voiced := false
func _on_AreaDialog_body_entered(_body: Node) -> void:
	if not _is_dialog_kick_voiced:
		_is_dialog_kick_voiced = true
		if OS.get_name() in PlatformsInfo.get_names_os_pc():
			_play_dialog("PRESS_SPACE_TO_KICK")
		else:
			_play_dialog("TO_KICK_THE_BALL")
