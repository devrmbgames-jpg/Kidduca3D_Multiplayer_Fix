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

# objects tree
onready var _ball := $BallMP
#onready var _mat_ball : ShaderMaterial = $Ball/football_ball.mesh.surface_get_material(0) as ShaderMaterial
onready var _pos_spawn_ball := $PosSpawnBall
#onready var _area_ball : Area = $Ball/AreaBall
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

# UI
onready var _score_shapes_friend := $"%ScoreShapesFriend"
onready var _score_shapes_enemy := $"%ScoreShapesEnemy"
onready var _score_back_friend := $"%ScoreBackFriend"
onready var _score_back_enemy := $"%ScoreBackEnemy"
onready var _animation_label_start := $"%AnimationPlayerLabelStart"
onready var _score_icon_friend := $"%TextureRectFriend"
onready var _score_icon_enemy := $"%TextureRectEnemy"
onready var _hint_mobile := $"%HintMobile"
onready var _area_hint_mobile := $"%AreaHintMobile"
onready var _timer_hint_mobile := $TimerHintMobile

# vars
onready var _ball_on = BALL_ON.NONE

onready var _timer_spawn_ball : SceneTreeTimer = get_tree().create_timer(0.0)

var _round := 0
var _score_friend := 0
var _score_enemy := 0

var _is_ball_traped_player := false
var _force_kick_ball := 0.0
var _force_kick_ball_max := 25.0
var _angle_direction_min := -10.0
var _angle_direction_max := -60.0
onready var _timer_kick_ball : SceneTreeTimer = get_tree().create_timer(0.0)
var _timer_sec_max := 3.0

var _shapes_list : Array

var _camera_player_rotation := Vector2.ZERO
var _camera_level_start_trans : Transform

var _current_tween = TWEEN.NONE

var _character_friend := 1
var _character_enemy := 1

var _success := false

var _is_click_right_stick := false

var team_color : int = TEAM_MARK.COLOR_TEAM.RED
var network_players_lobby : Spatial = null
var team_marks_lobby : Spatial = null
var name_node_lobby := ""

var _clother_do_game := []

# network
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
	NAME_DATA.TYPE : TYPE_DATA.SCORE,
	NAME_DATA.IDX_OBJ : "",
	NAME_DATA.TYPE_OBJ : NetworkConst.TYPE_OBJ_LEVEL.FOOTBALL_GAME,
	NAME_DATA.SCORE_RED : 0,
	NAME_DATA.SCORE_BLUE : 0,
	NAME_DATA.ROUND : 0,
}

var _data_network_bots_is_player_control := {
	NAME_DATA.TYPE_UPDATE : NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_LEVELS,
	NAME_DATA.TYPE : TYPE_DATA.BOTS_IS_PLAYER_CONTROL,
	NAME_DATA.IDX_OBJ : "",
	NAME_DATA.TYPE_OBJ : NetworkConst.TYPE_OBJ_LEVEL.FOOTBALL_GAME,
	NAME_DATA.BOTS_IS_PLAYER_CONTROL : false,
}


func _process(_delta) -> void:
	_input_player()
	#_process_timer_kick_ball()
	var character : Spatial = Singletones.get_Global().player_character.get_character()
	_area_trap_ball_player.global_transform.origin = character.global_transform.origin
	_area_trap_ball_player.global_rotation.y = character.global_rotation.y

func _physics_process(_delta) -> void :
	#var areas := _area_ball.get_overlapping_areas()
	var areas : Array = _ball.get_area_ball().get_overlapping_areas()
	_go_npc_to_ball(areas)
	_check_ball_on(areas)
	_random_go_to_ball()

func start_game() -> void :
	if Singletones.get_LearnSystem().is_learning():
		#SCORE_MAX = 1 # for mp disabled
		pass
	
	_success = false
	_camera_level_start_trans = _camera.global_transform
	
	if Singletones.get_Global().ui_touch_controller :
		Singletones.get_Global().ui_touch_controller.get_stick_right().connect("click", self, "_StickRight_click")
		Singletones.get_Global().ui_touch_controller.change_icon_jumo_to(ICON_KICK_FOOTBAL)
	
	
	_init_input_map()
	_init_color_team()
	_init_enemys_and_friends()
	_init_player()
	_init_players_network()
	_init_poses_players_and_bots()
	_init_host_control_bots()
	_init_shapes()
	_init_ui()
	_init_fans()
	_init_gate_ans_side()
	
	
	var net_api = Singletones.get_Network().api
	if net_api and not net_api.is_connected("host_changed", self, "_on_network_host_changed"):
		net_api.connect("host_changed", self, "_on_network_host_changed")
	
	if net_api and net_api.is_host():
		_become_match_host()
	else:
		_lose_match_host()
	
	_welcome()
	
	Analitics.send_event_level_start(
		AchivmentsConsts.FAVORITE_SOCCER.to_lower(),
		1,
		"none",
		"world_of_sorting"
	)

func exit() -> void :
	if Singletones.get_Global().ui_touch_controller :
		Singletones.get_Global().ui_touch_controller.get_stick_right().disconnect("click", self, "_StickRight_click")
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
	
	var clother_do_game := Singletones.get_Global().last_clother
	Logger.log_i(self, " change clother to ", clother_do_game)
	player_char.update_reward_items(clother_do_game)
	
	
	var net_api = Singletones.get_Network().api
	if net_api and net_api.is_connected("host_changed", self, "_on_network_host_changed"):
		net_api.disconnect("host_changed", self, "_on_network_host_changed")
	
	queue_free()
	
	Analitics.send_event_level_end(
		AchivmentsConsts.FAVORITE_SOCCER.to_lower(),
		1,
		"none",
		"win" if _success else "close",
		"world_of_sorting"
	)
	
	

func _exit_out_game() -> void :
	Singletones.get_GameUiDelegate().share.emit_signal("close")

func _play_dialog(key_text: String) -> void :
	_audio_dialog.stream = ResourceLoader.load(Singletones.get_LocaleSounds().get_sound_path(key_text), "", true)
	_audio_dialog.play()

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


func _init_color_team() -> void :
	var color_pl := {}
	if team_marks_lobby and is_instance_valid(team_marks_lobby):
		for tml in team_marks_lobby.get_children():
			color_pl[tml.name] = tml
		var names_pl : Array = color_pl.keys()
		
		if not names_pl.empty():
			names_pl.sort()
			
			var count_team_red := 0
			var count_team_blue := 0
			
			for nm in names_pl:
				var team : TEAM_MARK = color_pl[nm]
				if team and is_instance_valid(team):
					if team.color_team == TEAM_MARK.COLOR_TEAM.RED:
						count_team_red += 1
						if count_team_red > COUNT_PLAYERS_IN_TEAM:
							team.set_side_team(TEAM_MARK.COLOR_TEAM.BLUE)
					else:
						count_team_blue += 1
						if count_team_blue > COUNT_PLAYERS_IN_TEAM:
							team.set_side_team(TEAM_MARK.COLOR_TEAM.RED)


func _init_enemys_and_friends() -> void :
	var count_pl_red := 0
	var count_pl_blue := 0
	
	if team_marks_lobby and is_instance_valid(team_marks_lobby):
		for tml in team_marks_lobby.get_children():
			if tml.color_team == TEAM_MARK.COLOR_TEAM.RED:
				count_pl_red += 1
			else:
				count_pl_blue += 1
	
	var count_bot_red := COUNT_PLAYERS_IN_TEAM - count_pl_red
	var count_bot_blue := COUNT_PLAYERS_IN_TEAM - count_pl_blue
	
	var bots := []
	if count_bot_red > 0:
		for i in count_bot_red:
			var bot : BOT = ResourceLoader.load(BOT_PATH, "", true).instance()
			bot.name = "f_" + str(i)
			_friends.add_child(bot)
			bot.name_node_lobby = name_node_lobby
			bot.global_position = _pos_start_team_red.global_position \
				+ Vector3(randf() * 14.0 - 7.0, 0.0, randf() * 14.0 - 7.0)
			bot.rotation.y = PI
			bot.is_friend = true
			bot.set_gate_pos(_pos_gate_enemy)
			bot.set_ball(_ball)
			bot.is_player_control = false
			bots.append(bot)
	
	if count_bot_blue > 0:
		for i in count_bot_blue:
			var bot : BOT = ResourceLoader.load(BOT_PATH, "", true).instance()
			bot.name = "e_" + str(i)
			_enemys.add_child(bot)
			bot.name_node_lobby = name_node_lobby
			bot.global_position = _pos_start_team_blue.global_position \
				+ Vector3(randf() * 14.0 - 7.0, 0.0, randf() * 14.0 - 7.0)
			bot.is_friend = false
			bot.set_gate_pos(_pos_gate_friend)
			bot.set_ball(_ball)
			bot.is_player_control = false
			bots.append(bot)
	
	
	var characters_list : Array = _characters.get_characters_list()
	var random_clothes := []
	if network_players_lobby and is_instance_valid(network_players_lobby):
		var ids_pl := []
		ids_pl.append(Singletones.get_Global().player_character.name)
		for npl in network_players_lobby.get_children():
			ids_pl.append(npl.name)

		if not ids_pl.empty():
			ids_pl.sort()
			var rng = RandomNumberGenerator.new()
			rng.seed = int(ids_pl[0])
			for bot in bots:
				var num : int = rng.randi() % characters_list.size()
				var char_path : Array = _characters.get_character_model_path(characters_list[num])
				bot.change_skin(char_path[0])
				random_clothes = _get_random_clothes(rng)
				bot.update_reward_items(random_clothes)


func _get_random_clothes(rng: RandomNumberGenerator) -> Array :
	var clothes := [
		RewardItemsConst.hats_list[rng.randi() % RewardItemsConst.hats_list.size()],
		RewardItemsConst.skirts_list[rng.randi() % RewardItemsConst.skirts_list.size()],
		RewardItemsConst.capes_list[rng.randi() % RewardItemsConst.capes_list.size()],
		RewardItemsConst.bows_list[rng.randi() % RewardItemsConst.bows_list.size()],
		RewardItemsConst.glasses_list[rng.randi() % RewardItemsConst.glasses_list.size()],
		RewardItemsConst.amulets_list[rng.randi() % RewardItemsConst.amulets_list.size()],
		RewardItemsConst.brasletes_list[rng.randi() % RewardItemsConst.brasletes_list.size()],
	]
	for i in clothes.size():
		if rng.randi() % 100 > 35:
			clothes[i] = ""
	if rng.randi() % 100 > 30:
		clothes[1] = ""
	return clothes

func _init_player() -> void :
	var player = Singletones.get_Global().player_character
	#player.global_transform.origin = _pos_character_start.global_transform.origin
	_clother_do_game = player.get_reward_items()
	if not (
		RewardItemsConst.HAT_FOOTBAL_TEAM_BLUE in _clother_do_game or
		RewardItemsConst.CAPE_FOOTBAL_TEAM_BLUE in _clother_do_game or
		RewardItemsConst.CAPE_FOOTBAL_TEAM_RED in _clother_do_game or
		RewardItemsConst.HAT_FOOTBAL_TEAM_RED in _clother_do_game) :
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
	player.freez = true
	player.enabled = false
	player.move_force = false
	player.visible = true
	
	
	

func _init_players_network() -> void :
	if not network_players_lobby:
		return
	if not is_instance_valid(network_players_lobby):
		return
	
	for npl in network_players_lobby.get_children():
		var area_alloc_pl_net : AREA_ALLOC_PL_NET = ResourceLoader.load(AREA_ALLOC_PL_NET_PATH, "", true).instance()
		area_alloc_pl_net.name = npl.name
		_areas_alloc_pl_net.add_child(area_alloc_pl_net)
		area_alloc_pl_net.pl_net = npl
		npl.connect("tree_exited", self, "_NetworkPlayers_tree_exited", [area_alloc_pl_net])
		
		
		

func _NetworkPlayers_tree_exited(area_alloc_pl_net: AREA_ALLOC_PL_NET) -> void :
	if not area_alloc_pl_net:
		return
	if not is_instance_valid(area_alloc_pl_net):
		return
	area_alloc_pl_net.name += "_del"
	area_alloc_pl_net.queue_free()


func _init_poses_players_and_bots() -> void :
	var color_pl := {}
	if team_marks_lobby and is_instance_valid(team_marks_lobby):
		for tml in team_marks_lobby.get_children():
			color_pl[tml.name] = tml.color_team
	else:
		return
	
	if network_players_lobby and is_instance_valid(network_players_lobby):
		var ids_pl := {}
		ids_pl[Singletones.get_Global().player_character.name] = Singletones.get_Global().player_character
		for npl in network_players_lobby.get_children():
			ids_pl[npl.name] = npl
		var names_pl : Array = ids_pl.keys()
		
		print(self, "#############################################################")
		print(self, "#############################################################")
		print(self, "#############################################################")
		print(self, " COLOR_PL ", color_pl.keys())
		print(self, " IDS_pl   ", ids_pl.keys())
		
		if not names_pl.empty():
			names_pl.sort()
			
			var idx_pos_red := -1
			var idx_pos_blue := -1
			
			#set_position
			for nm in names_pl:
				if color_pl.get(nm, TEAM_MARK.COLOR_TEAM.RED) == TEAM_MARK.COLOR_TEAM.RED:
					idx_pos_red += 1
					if idx_pos_red < _poses_spawn_red_pl.get_child_count() and ids_pl.has(nm):
						if ids_pl[nm] is PLAYER_NETWORK:
							ids_pl[nm].set_rotate_y(0.0)
							ids_pl[nm].set_position(_poses_spawn_red_pl.get_child(idx_pos_red).global_position)
							ids_pl[nm].update_clothes([
								RewardItemsConst.HAT_FOOTBAL_TEAM_RED,
								RewardItemsConst.CAPE_FOOTBAL_TEAM_RED,
							])
						else:
							ids_pl[nm].global_position = _poses_spawn_red_pl.get_child(idx_pos_red).global_position
				else:
					idx_pos_blue += 1
					if idx_pos_blue < _poses_spawn_blue_pl.get_child_count() and ids_pl.has(nm):
						if ids_pl[nm] is PLAYER_NETWORK:
							ids_pl[nm].set_rotate_y(PI)
							ids_pl[nm].set_position(_poses_spawn_blue_pl.get_child(idx_pos_blue).global_position)
							ids_pl[nm].update_clothes([
								RewardItemsConst.HAT_FOOTBAL_TEAM_BLUE,
								RewardItemsConst.CAPE_FOOTBAL_TEAM_BLUE,
							])
						else:
							ids_pl[nm].global_position = _poses_spawn_blue_pl.get_child(idx_pos_blue).global_position
			
			for bot in _friends.get_children():
				idx_pos_red += 1
				if idx_pos_red < _poses_spawn_red_pl.get_child_count():
					bot.global_position = _poses_spawn_red_pl.get_child(idx_pos_red).global_position
			for bot in _enemys.get_children():
				idx_pos_blue += 1
				if idx_pos_blue < _poses_spawn_blue_pl.get_child_count():
					bot.global_position = _poses_spawn_blue_pl.get_child(idx_pos_blue).global_position


func _init_host_control_bots() -> void :
	if network_players_lobby and is_instance_valid(network_players_lobby):
		var ids_pl := []
		ids_pl.append(Singletones.get_Global().player_character.name)
		for npl in network_players_lobby.get_children():
			ids_pl.append(npl.name)

		if not ids_pl.empty():
			ids_pl.sort()
			var name_host : String = ids_pl[0]
			if name_host == Singletones.get_Global().player_character.name:
				_ball.is_player = true
				_set_control_bots(true)


func _init_shapes() -> void :
	_shapes_list = _shapes.get_shapes_list()
	if network_players_lobby and is_instance_valid(network_players_lobby):
		var ids_pl := []
		ids_pl.append(Singletones.get_Global().player_character.name)
		for npl in network_players_lobby.get_children():
			ids_pl.append(npl.name)
		
		if not ids_pl.empty():
			ids_pl.sort()
			var rng = RandomNumberGenerator.new()
			rng.seed = int(ids_pl[0])
			for i in _shapes_list.size() - 2:
				var j : int = rng.randi_range(i, _shapes_list.size() - 1)
				var tmp = _shapes_list[i]
				_shapes_list[i] = _shapes_list[j]
				_shapes_list[j] = tmp
		else:
			_shapes_list.shuffle()
	else:
		_shapes_list.shuffle()
	
	_change_mat_ball()


func _init_ui() -> void :
	_hint_mobile.visible = false
	_area_hint_mobile.visible = false
	
	for i in _score_shapes_friend.get_child_count():
		_score_shapes_friend.get_child(i).hide_shape()
		_score_shapes_enemy.get_child(i).hide_shape()
	
	for i in _score_back_friend.get_child_count():
		_score_back_friend.get_child(i).visible = false
		_score_back_enemy.get_child(i).visible = false
	for i in SCORE_MAX:
		_score_back_friend.get_child(i).visible = true
		_score_back_enemy.get_child(i).visible = true
	
	_score_icon_friend.texture = _characters.get_characters_icon(_character_friend)
	_score_icon_enemy.texture = _characters.get_characters_icon(_character_enemy)
	
	Singletones.get_GameUiDelegate().share.set_ui_star_visible(false)
	Singletones.get_Global().ui_touch_controller.show_hints_wasd_mouse()

func _init_fans() -> void :
	for fan in _fans.get_children():
		get_tree().create_timer(randi()%10 * 0.1).connect("timeout", self, "_timer_fan_timeout", [fan])

func _init_gate_ans_side() -> void :
	if team_color == TEAM_MARK.COLOR_TEAM.BLUE:
		_goalkeep_friend.is_friend = false
		_goalkeep_enemy.is_friend = true
		
		#_gate_friend.is_friend = false
		#_gate_enemy.is_friend = true
		
		_pos_goal_player.global_position = _pos_goal_pl_red.global_position


func _become_match_host() -> void :
	Logger.log_i(self, " Become match host")
	
	if _ball and is_instance_valid(_ball):
		_ball.force_take_authority()
	
	
	_set_control_bots(true)
	
	# полезно сразу разослать актуальный снимок
	_send_score()


func _lose_match_host() -> void :
	Logger.log_i(self, " Lose match host")
	
	if _ball and is_instance_valid(_ball):
		_ball.is_player = false
	
	_set_control_bots(false)



func _timer_fan_timeout(fan: Spatial) -> void :
	fan.fcm.push_state(fan.FCM.ACTION)
	fan.set_action_idx(2)

func _welcome() -> void :
	_to_camera_level()
	_play_dialog("WELCOME_TO_THE_SOCCER_FIELD")
	_animation_camera.play("welcome")

func _begin_game() -> void :
	_hint_mobile.visible = true
	_area_hint_mobile.visible = true
	_all_play()

func _play_animation_label_start() -> void :
	_animation_label_start.play("play")

func _all_play() -> void :
	Singletones.get_Global().player_character.freez = false
	Singletones.get_Global().player_character.enabled = true
	
	for friend in _friends.get_children():
		friend.play_game()
	for enemy in _enemys.get_children():
		enemy.play_game()
	_goalkeep_friend.play_game()
	_goalkeep_enemy.play_game()
	
	# TODO temp
	#_set_control_bots(true)

func _all_stand() -> void :
	Singletones.get_Global().player_character.freez = true
	Singletones.get_Global().player_character.enabled = false
	
	for friend in _friends.get_children():
		friend.stand()
	for enemy in _enemys.get_children():
		enemy.stand()
	_goalkeep_friend.stand()
	_goalkeep_enemy.stand()

func _to_camera_level() -> void :
	var camera := get_viewport().get_camera()
	camera.target = _camera.get_path()

func _to_camera_player() -> void :
	var camera := get_viewport().get_camera()
	camera.target = Singletones.get_GameUiDelegate().share.character_camera_x2.get_path()

func _to_camera_level_tween(trans: Transform) -> void :
	_current_tween = TWEEN.CAMERA_LEVEL
	_tween.interpolate_property(
		_camera,
		"global_transform",
		Singletones.get_GameUiDelegate().share.character_camera_x2.global_transform,
		trans,
		1.5
	)
	_tween.start()

func _to_camera_player_tween() -> void :
	_current_tween = TWEEN.CAMERA_PLAYER
	Singletones.get_GameUiDelegate().share.controler.rotation.y = _camera_player_rotation.y
	Singletones.get_GameUiDelegate().share.controler.rotation.x = _camera_player_rotation.x
	_tween.interpolate_property(
		_camera,
		"global_transform",
		_camera.global_transform,
		Singletones.get_GameUiDelegate().share.character_camera_x2.global_transform,
		1.5
	)
	_tween.start()

func _rortate_camera_player_to_spawn_ball_tween() -> void :
	if _score_friend == SCORE_MAX or _score_enemy == SCORE_MAX:
		return
	
	_current_tween = TWEEN.ROTATE
	var direct_to_spawn : Vector3 = _area_trap_ball_player.global_transform.origin.direction_to(
		_pos_spawn_ball.global_transform.origin
	)
	direct_to_spawn.y = 0.0
	
	var rot_to_spawn : Vector3 = Vector3.ZERO
	rot_to_spawn.x = 0.0
	rot_to_spawn.y = direct_to_spawn.angle_to(Vector3.FORWARD)
	rot_to_spawn.z = Singletones.get_GameUiDelegate().share.controler.rotation.z
	
	if _area_trap_ball_player.transform.origin.x < 0:
		rot_to_spawn.y = 2*PI -rot_to_spawn.y
	
	if abs(rot_to_spawn.y - Singletones.get_GameUiDelegate().share.controler.rotation.y) > PI:
		rot_to_spawn.y -= 2*PI
	
	_tween.interpolate_property(
		Singletones.get_GameUiDelegate().share.controler,
		"rotation",
		Singletones.get_GameUiDelegate().share.controler.rotation,
		rot_to_spawn,
		1.0
	)
	_tween.start()

func _go_npc_to_ball(areas: Array) -> void :
	if areas.empty():
		_go_enemy_to_ball()
		_go_friend_to_ball()

func _go_enemy_to_ball() -> void :
	if not _ball.can_trap:
		return
	
	var distance := 10000.0
	var enemy_goto : KinematicBody = _enemys.get_child(0)
	for enemy in _enemys.get_children():
		enemy.stop_go_to_ball()
		var distance_to_ball : float = enemy.global_transform.origin.distance_to(_ball.global_transform.origin)
		if distance_to_ball < distance:
			distance = distance_to_ball
			enemy_goto = enemy
	enemy_goto.go_to_ball()

func _go_friend_to_ball() -> void :
	if not _ball.can_trap:
		return
	
	var distance = 10000.0
	var friend_goto : KinematicBody = _friends.get_child(0)
	for friend in _friends.get_children():
		friend.stop_go_to_ball()
		var distance_to_ball : float = friend.global_transform.origin.distance_to(_ball.global_transform.origin)
		if distance_to_ball < distance:
			distance = distance_to_ball
			friend_goto = friend
	friend_goto.go_to_ball()

func _check_ball_on(areas: Array) -> void :
	if areas.empty():
		_ball_on = BALL_ON.NONE
	else:
		var ball_on_enemy := false
		var ball_on_friend := false
		for area in areas:
			if area.is_friend:
				ball_on_friend = true
			else:
				ball_on_enemy = true
		if ball_on_friend and ball_on_enemy:
			_ball_on = BALL_ON.NONE
		elif ball_on_friend:
			_ball_on = BALL_ON.FRIENDS
			for friend in _friends.get_children():
				friend.stop_go_to_ball()
		elif ball_on_enemy:
			_ball_on = BALL_ON.ENEMYS
			for enemy in _enemys.get_children():
				enemy.stop_go_to_ball()

func _random_go_to_ball() -> void:
	if randi() % 60 == 0:
		if _ball_on == BALL_ON.FRIENDS:
			_go_enemy_to_ball()
		if _ball_on == BALL_ON.ENEMYS:
			_go_friend_to_ball()

func _input_player() -> void :
	if Input.is_action_just_pressed("active") or _is_click_right_stick:
		_is_click_right_stick = false
		if _is_ball_traped_player:
			var direct_goal : Vector3 = _pos_goal_player.global_transform.origin - \
				_area_trap_ball_player.global_transform.origin
			direct_goal.y = 0.0
			direct_goal = direct_goal.normalized()
			var direct_player : Vector3 = _area_trap_ball_player.get_direction()
			if direct_goal.dot(direct_player) > 0.5:
				_area_trap_ball_player.kick_ball(true, _pos_goal_player)
			else:
				_area_trap_ball_player.kick_ball(false)
		else:
			for friend in _friends.get_children():
				friend.pass_to_player()

func _all_go_to_center() -> void :
	_ball.can_trap = false
	for enemy in _enemys.get_children():
		enemy.stop_go_to_ball()
		enemy.set_target(_pos_spawn_ball)
	for friend in _friends.get_children():
		friend.stop_go_to_ball()
		friend.set_target(_pos_spawn_ball)

func _all_go_to_ball() -> void :
	_ball.can_trap = true
	for enemy in _enemys.get_children():
		enemy.set_target(_ball)
	for friend in _friends.get_children():
		friend.set_target(_ball)

func _spawn_ball() -> void :
	_change_mat_ball()
	
	_ball.global_transform.origin = _pos_spawn_ball.global_transform.origin
	_ball.linear_velocity = Vector3.ZERO
	_ball.angular_velocity = Vector3.ZERO
	_all_go_to_ball()
	_goalkeep_enemy.look_to_ball()
	_goalkeep_friend.look_to_ball()

func _change_mat_ball() -> void :
	#_mat_ball.albedo_texture = _shapes.get_shape_icon(_shapes_list[_round])
	#_mat_ball.albedo_color = Color(0.78, 0.78, 0.78, 1.0)
	var icon : AtlasTexture = _shapes.get_shape_icon(_shapes_list[_round])
	var region_start : Vector2 = Vector2(icon.region.position.x, icon.region.position.y)
	var uv_offset : Vector2 = Vector2(
		0.125 * (region_start.x / 256.0),
		0.125 * (region_start.y / 256.0)
		)
	_ball.change_mat_ball(icon, region_start, uv_offset)
#	_mat_ball.set_shader_param("albedo_texture", icon)
#	_mat_ball.set_shader_param("region_start", region_start)
#	_mat_ball.set_shader_param("uv_offset", uv_offset)

func _despawn_ball() -> void :
	_ball.global_transform.origin = _pos_spawn_ball.global_transform.origin - Vector3.UP * 100.0
	_ball.linear_velocity = Vector3.ZERO
	_ball.angular_velocity = Vector3.ZERO

func _great(is_friend: bool) -> void :
	var _shape_icon = _shapes.get_shape_icon(_shapes_list[_round - 1])
	if is_friend:
		var friend_idx := _score_friend - 1
		if _score_shapes_friend.get_child_count() > friend_idx :
			var node := _score_shapes_friend.get_child(friend_idx)
			if node :
				node.set_texture_and_show(_shape_icon)
		
		
		_animation.play("goal_friend")
		_goalkeep_enemy.stop_go_to_ball()
		_goalkeep_enemy.look_to_spawn_ball()
	else:
		
		var enemy_idx := _score_enemy - 1
		if _score_shapes_enemy.get_child_count() > enemy_idx :
			var node := _score_shapes_enemy.get_child(enemy_idx)
			if node :
				node.set_texture_and_show(_shape_icon)
		
		_animation.play("goal_enemy")
		_goalkeep_friend.stop_go_to_ball()
		_goalkeep_friend.look_to_spawn_ball()
	
	_all_go_to_center()
	Logger.log_i(self, "SCORE F:E   ", _score_friend, " : ", _score_enemy)
	
	yield(_animation, "animation_finished")
	
	if _score_friend == SCORE_MAX:
		_victory(true)
	if _score_enemy == SCORE_MAX:
		_victory(false)
	

func _victory(is_friend: bool) -> void :
	_all_stand()
	var player_char = Singletones.get_Global().player_character.get_character()
	
	var win_self := true
	if is_friend:
		if team_color == TEAM_MARK.COLOR_TEAM.RED:
			win_self = true
		else:
			win_self = false
	else:
		if team_color == TEAM_MARK.COLOR_TEAM.RED:
			win_self = false
		else:
			win_self = true
	
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
		player_char.fcm.pop_state()
		player_char.fcm.push_state(player_char.fcm.IDLE)
	
	if is_friend:
		_animation.play("victory_friend")
		for friend in _friends.get_children():
			friend.victory()
		_goalkeep_friend.victory()
	else:
		_animation.play("victory_enemy")
		for enemy in _enemys.get_children():
			enemy.victory()
		_goalkeep_enemy.victory()
		
	
	_play_dialog("THE_MATCH_IS_OVER")
	_to_camera_level_tween(_camera_level_start_trans)
	_to_camera_level()

func _play_shapes_sound() -> void :
	_shapes.play_sound(_shapes_list[_round - 1])


func _set_control_bots(turn: bool) -> void :
	for enemy in _enemys.get_children():
		enemy.is_player_control = turn
	for friend in _friends.get_children():
		friend.is_player_control = turn
	
	if turn:
		_send_control_bots()


func _update_score_from_network(score_red: int, score_blue: int, round_in: int) -> void :
	if score_red > _score_friend and score_blue <= _score_enemy:
		_score_friend = score_red
		_score_enemy = score_blue
		_round = round_in
		_great(true)
	elif score_blue > _score_enemy and score_red <= _score_friend:
		_score_friend = score_red
		_score_enemy = score_blue
		_round = round_in
		_great(false)
	elif score_red > _score_friend and score_blue > _score_enemy:
		_score_friend = score_red
		_score_enemy = score_blue
		_round = round_in
		_great(true)


func _send_control_bots() -> void :
	_data_network_bots_is_player_control[NAME_DATA.IDX_OBJ] = get_parent().name
	_data_network_bots_is_player_control[NAME_DATA.BOTS_IS_PLAYER_CONTROL] = true
	
	var key : int = NetworkConst.GLOBAL_TYPE_DATA.OPEN_GAME
	Singletones.get_Network().api.setup_data(key, _data_network_bots_is_player_control)
	Singletones.get_Network().api.send_data_to_all()

func _send_score() -> void :
	_data_network_score[NAME_DATA.IDX_OBJ] = get_parent().name
	_data_network_score[NAME_DATA.SCORE_RED] = _score_friend
	_data_network_score[NAME_DATA.SCORE_BLUE] = _score_enemy
	_data_network_score[NAME_DATA.ROUND] = _round
	
	var key : int = NetworkConst.GLOBAL_TYPE_DATA.OPEN_GAME
	Singletones.get_Network().api.setup_data(key, _data_network_score)
	Singletones.get_Network().api.send_data_to_all()


func update_network_data(data: Dictionary) -> void :
	#print(self, data)
	match data[NAME_DATA.TYPE_OBJ] as int:
		NetworkConst.TYPE_OBJ_LEVEL.FOOTBALL_GAME:
			match data[NAME_DATA.TYPE] as int:
				TYPE_DATA.SCORE:
					_update_score_from_network(
						data.get(NAME_DATA.SCORE_RED, 0) as int,
						data.get(NAME_DATA.SCORE_BLUE, 0) as int,
						data.get(NAME_DATA.ROUND, 0) as int
					)
				TYPE_DATA.BOTS_IS_PLAYER_CONTROL:
					_set_control_bots(false)
		NetworkConst.TYPE_OBJ_LEVEL.FOOTBALL_BALL:
			if _ball and is_instance_valid(_ball):
				if _ball.has_method("update_network_data"):
					_ball.update_network_data(data)
		NetworkConst.TYPE_OBJ_LEVEL.FOOTBALL_BOT:
			for friend in _friends.get_children():
				if friend and is_instance_valid(friend):
					if friend.has_method("update_network_data"):
						friend.update_network_data(data)
			for enemy in _enemys.get_children():
				if enemy and is_instance_valid(enemy):
					if enemy.has_method("update_network_data"):
						enemy.update_network_data(data)
			pass



func _on_TrapBall_trap_ball():
	_ball.is_player = true
	_is_ball_traped_player = true
	_set_control_bots(true)
	for friend in _friends.get_children():
		friend.stop_go_to_ball()


func _on_TrapBallPlayer_untrap_ball():
	_is_ball_traped_player = false
	_timer_kick_ball.time_left = 0.0


func _on_GateFriend_goal():
	_score_enemy += 1
	_round += 1
	_great(false)
	_send_score()

func _on_GateEnemy_goal():
	_score_friend += 1
	_round += 1
	_great(true)
	_send_score()


func _on_AreaAllocationBallFriend_body_entered(_body):
	_goalkeep_friend.go_to_ball()


func _on_AreaAllocationBallFriend_body_exited(_body):
	_goalkeep_friend.stop_go_to_ball()


func _on_AreaAllocationBallEnemy_body_entered(_body):
	_goalkeep_enemy.go_to_ball()


func _on_AreaAllocationBallEnemy_body_exited(_body):
	_goalkeep_enemy.stop_go_to_ball()


func _on_goalkeeper_trap_ball():
	_all_go_to_center()


func _on_goalkeeper_untrap_ball():
	_all_go_to_ball()



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



func _on_TimerHintMobile_timeout():
	_hint_mobile.visible = true


func _on_Area2D_input_event(_viewport, event, _shape_idx):
	if event is InputEventScreenTouch:
		if event.pressed:
			_timer_hint_mobile.stop()
			_hint_mobile.visible = false
		else:
			_timer_hint_mobile.stop()
			_timer_hint_mobile.start()


func _StickRight_click() -> void :
	_is_click_right_stick = true


var _is_dialog_kick_voiced := false
func _on_AreaDialog_body_entered(_body: Node) -> void:
	if not _is_dialog_kick_voiced:
		_is_dialog_kick_voiced = true
		if OS.get_name() in PlatformsInfo.get_names_os_pc():
			_play_dialog("PRESS_SPACE_TO_KICK")
		else:
			_play_dialog("TO_KICK_THE_BALL")


func _on_network_host_changed(new_host_id: String, old_host_id: String) -> void :
	Logger.log_i(self, " Host changed old=%s new=%s" % [old_host_id, new_host_id])

	var my_id := Singletones.get_Network().api.get_peer_id()
	var am_i_host := my_id == new_host_id

	if am_i_host:
		_become_match_host()
	else:
		_lose_match_host()
