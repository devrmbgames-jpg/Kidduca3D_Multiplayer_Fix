extends "res://globals/singletones_v2/interfaces/IGlobal.gd"

const UtilsScript := preload("res://scripts/utils.gd")
const Analitics := preload("res://content/analitics/analitics.gd")
const PlatformsInfo := preload("res://content/platforms_info/platforms_info.gd")
const SUB_FABRIC := preload("res://content/ui/subscription/subscription_v3/subscription_fabric_v3.gd")
const SCREEN_SUB := preload("res://content/ui/subscription/subscription_v3/screen_subscription_v3.gd")

const POPUP_UPDATE_PATH := "res://content/ui/popup_update.tscn"


var _check_update_http_request: HTTPRequest = null
var _popup_update: Node = null

var _timer_update_status := Timer.new()

func _to_string() -> String:
	return "[Global]"

func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(_timer_update_status)
	_timer_update_status.wait_time = 120.0
	_timer_update_status.start()
	_timer_update_status.connect("timeout", self, "_on_update_status")
	#call_deferred("check_update")

func register_notification() -> void :
	var cloud = GamePlugin.get_plugin("FirebaseCloudMessaging")
	if cloud :
		if cloud.has_method("setup") :
			cloud.setup()
	
	var apn = GamePlugin.get_plugin("APN")
	if apn :
		if apn.has_method("register_push_notifications") :
			apn.register_push_notifications(apn.PUSH_DEFAULT)

func check_update() -> void :
	var scene_tree := Engine.get_main_loop() as SceneTree
	if scene_tree:
		if OS.get_name() == "Windows" and scene_tree.root.get_node_or_null("SteamManager") :
			Logger.log_i("[Global]", " Steam version. Popup update NOT show")
			return
	
	if _check_update_http_request : return
	
	var http_request = HTTPRequest.new()
	_check_update_http_request = http_request
	add_child(http_request)
	http_request.connect("request_completed", self, "_check_update_http_request_completed", [], CONNECT_ONESHOT)

	# Perform a GET request. The URL below returns JSON as of writing.
	var error = http_request.request("https://www.rmbgames.com/version.txt")
	if error != OK:
		if _check_update_http_request and is_instance_valid(_check_update_http_request):
			_check_update_http_request.queue_free()
			_check_update_http_request = null
		push_error("An error occurred in the HTTP request.")


# Called when the HTTP request is completed.
func _check_update_http_request_completed(_result, _response_code, _headers, body):
	if _check_update_http_request and is_instance_valid(_check_update_http_request) :
		_check_update_http_request.queue_free()
		_check_update_http_request = null
	
	var response := body.get_string_from_utf8() as String
	var config := ConfigFile.new()
	config.parse(response)
	var version: String = config.get_value("VERSION", OS.get_name().to_lower(), "0.0.1") as String
	
	var version_split := version.split(".")
	if version_split.size() < 3 :
		return
	
	var major := version_split[0].to_int() * 1_000_000
	var minor := version_split[1].to_int() * 1_000
	var patch := version_split[2].to_int()
	var int_version := major + minor + patch
	
	var current_version: String = ProjectSettings.get_setting("application/config/game_version") as String
	
	if current_version.empty() :
		return
	
	var current_version_split := current_version.split(".")
	if current_version_split.size() < 3 :
		return
	
	var current_major := current_version_split[0].to_int() * 1_000_000
	var current_minor := current_version_split[1].to_int() * 1_000
	var current_patch := current_version_split[2].to_int()
	var current_int_version := current_major + current_minor + current_patch
	
	if int_version <= current_int_version :
		return
	
	_show_update()


func _show_update() -> void :
	if _popup_update and is_instance_valid(_popup_update):
		_popup_update.queue_free()
		_popup_update = null
		
	var popup_update := load(POPUP_UPDATE_PATH).instance() as Node
	add_child(popup_update)


func get_enable_subscription_system() -> bool :
	if DISABLE_SUBSCRIPTIONS:
		Logger.log_i(self, " DEBUG   DISABLE_SUBSCRIPTIONS")
		return false
	
	var scene_tree := Engine.get_main_loop() as SceneTree
	if scene_tree:
		if OS.get_name() == PlatformsInfo.NAME_OS_WINDOWS and scene_tree.root.get_node_or_null("SteamManager") :
			return false
	
	var val := true
	
	Logger.log_i(self, " get enable subs system:", val)
	return val


func setup_visible_hints_inside_game() -> void:
	var platrform_type := PlatformsInfo.get_platform_type() # PC, MOBILE

	for node in get_tree().get_nodes_in_group("UI_HINT") :
		if node is CanvasItem or node is Spatial :
			node.visible = false
			if node.is_in_group("INSIDE_GAME") :
				if node.is_in_group(platrform_type):
					node.visible = true


func get_closet_end_level_position() -> Vector3 :
	
	var distance := -1.0
	var to_position := Vector3.ZERO
	var player_pos: Vector3 = Vector3.ZERO
	if player_character and is_instance_valid(player_character):
		player_pos = player_character.global_transform.origin
	else :
		player_pos = last_pos
		player_pos.y = 30.0
	for node in get_tree().get_nodes_in_group("TELEPORT_END") :
		if node is RayCast :
			
			var target_pos: Vector3 = node.global_transform.origin
			target_pos.y = player_pos.y
#			if node.is_colliding() :
#				target_pos.y = node.get_collision_point().y + 2
			var next_distance := player_pos.distance_to(target_pos)
			if next_distance < distance or distance < 0.0:
				to_position = target_pos
				distance = next_distance
	#to_position.y = player_pos.y
	Logger.log_i(self, " RETURN CLOSET POSITION - ", to_position)
	return to_position

func free_data() -> void :
	pass

func reload_game() -> void :
	
	Logger.log_i(self, "\n\n *******************************************")
	Logger.log_i(self, " *******************************************\n\n")
	
	
	Logger.log_i(self, " reload game...")
	var curr_scene := get_tree().current_scene
	curr_scene.queue_free()
	
	Logger.log_i(self, " free current scene, wait free finished...")
	yield(curr_scene, "tree_exited")
	
	Logger.log_i(self, " free current scene finished!")
	curr_scene = null
	get_tree().current_scene = null
	
	Logger.log_i(self, " reload singletones...")
	for node in get_tree().root.get_children() :
		if node and is_instance_valid(node) :
			if node.has_method("reload_singletone") :
				Logger.log_i(self, " reload singletone ", node)
				node.reload_singletone()
	
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	
	Logger.log_i(self, " goto splashscreen")
	get_tree().change_scene("res://content/ui/SplashScreen/SplashScreen.tscn")
	
	Logger.log_i(self, "\n\n *******************************************")
	Logger.log_i(self, " *******************************************\n\n")
	

func reload_singletone() -> void :
	player_character = null
	ui_touch_controller = null
	reset_target = null
	#current_character_index = 0
	last_pos = Vector3.ZERO
	
	if OS.get_name() in PlatformsInfo.get_names_os_pc():
		quality = 3
	else:
		quality = 2
	
	ortogonal_camera = null

	is_tutorial = false

	count_show_popup = 0
	is_free_camera = false
	sens_mouse = 0.002

	rate_me_count = 1

	left_stick = InputEventScreenStickAction.new()
	right_stick = InputEventScreenStickAction.new()
	
	UtilsScript.disconnect_all_signals(self)

#var paused_counted := 0 setget set_paused_counted
func set_paused_counted(val: int) -> void :
	paused_counted = val
	Logger.log_i(self, " PAUSE COUNT := ", val)
	
	if Singletones.get_GlobalGame().current_game == Singletones.get_GlobalGame().GAMES.CARGAMES:
		if Singletones.get_RaceSetup().type_game == Singletones.get_RaceSetup().TYPE_GAME.ONLINE_GAME:
			return
	
	if is_inside_tree() :
		if paused_counted == 0 :
			get_tree().paused = false
		else :
			get_tree().paused = true
			_sutup_visible_mouse_in_pause()
		_video_pause(get_tree().paused)
		_pause_game(get_tree().paused)
	
	if paused_counted < 0 :
		Logger.log_e(self, "PAUSED COUNTED < 0")
		paused_counted = 0

func _sutup_visible_mouse_in_pause() -> void :
	if OS.get_name() in PlatformsInfo.get_names_os_used_mouse():
		if count_show_popup == 0:
			#Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			MouseCursor.visible_cursor = false
			Logger.log_i(self, "HIDE MOUSE GLOBAL")
		else:
			#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			MouseCursor.visible_cursor = true
			Logger.log_i(self, "SHOW MOUSE GLOBAL")

func _video_pause(turn: bool) -> void :
	for video in get_tree().get_nodes_in_group("VIDEO"):
		if video is VideoPlayer:
			video.paused = turn

func _pause_game(turn: bool) -> void :
	for game in get_tree().get_nodes_in_group("PAUSE_GAME"):
		if turn:
			game.pause_mode = Node.PAUSE_MODE_STOP
		else:
			game.pause_mode = Node.PAUSE_MODE_INHERIT

func reset_player() -> void :
	set_disabled_player_to(reset_target)

func move_player_from_to(from: Spatial, to: Spatial) -> void :
	if not from or not to :
		return
	if player_character and is_instance_valid(player_character):
		player_character.enabled = false
		player_character.freez = true
		player_character.global_transform.origin = from.global_transform.origin
		player_character.target_move = to.global_transform.origin
		player_character.move_force = true
		player_character.visible = true
		player_character.enabled = true
		player_character.freez = false
		player_character.direction = Vector3.ZERO
		player_character.linear_velocity = Vector3.ZERO
		player_character.update_fcm_force()
		player_character.set_collision_mask_bit(1, false)

func run_player_from_to(from: Spatial, to: Spatial) -> void :
	if not from or not to :
		return
	if player_character and is_instance_valid(player_character):
		player_character.enabled = false
		player_character.freez = true
		player_character.global_transform.origin = from.global_transform.origin
		player_character.target_move = to.global_transform.origin
		player_character.run_force = true
		player_character.visible = true
		player_character.enabled = true
		player_character.freez = false
		player_character.direction = Vector3.ZERO
		player_character.linear_velocity = Vector3.ZERO
		player_character.update_fcm_force()
		player_character.set_collision_mask_bit(1, false)

func set_disabled_player_to(to: Spatial) -> void :
	if not to :
		return
	
	if player_character and is_instance_valid(player_character):
		player_character.visible = false
		player_character.enabled = false
		player_character.freez = false
		player_character.global_transform.origin = to.global_transform.origin
		player_character.set_collision_mask_bit(1, true)

func paywall() -> void :
	_create_subs()

func _create_subs() -> void :
	var screen_sub : SCREEN_SUB = SUB_FABRIC.create()
	if screen_sub:
		screen_sub.connect("cancel_purchase_sub", self, "_ScreenSub_cancel_purchase_sub")

func _ScreenSub_cancel_purchase_sub() -> void :
	Singletones.get_GameUiDelegate().share.close_game_with_drop()

func on_store() -> void :
	match OS.get_name() :
		PlatformsInfo.NAME_OS_IOS :
			var url = "https://apps.apple.com/app/id%s" % apple_id_app
			Logger.log_i(self, " open url - ", url)
			OS.shell_open(url)
		PlatformsInfo.NAME_OS_OSX :
			var url = "https://apps.apple.com/app/id%s" % apple_id_app
			Logger.log_i(self, " open url - ", url)
			OS.shell_open(url)
		PlatformsInfo.NAME_OS_ANDROID :
			var url = "https://play.google.com/store/apps/details?id=rmb.games.knowledge.park.full.d3"
			OS.shell_open(url)
		PlatformsInfo.NAME_OS_WINDOWS :
			var url = "https://play.google.com/store/apps/details?id=rmb.games.knowledge.park.full.d3"
			OS.shell_open(url)

func on_like() -> void :
	
	match OS.get_name() :
		PlatformsInfo.NAME_OS_IOS :
			Logger.log_i(self, " pressed like button")
			var url = "https://apps.apple.com/app/id%s?action=write-review" % apple_id_app
			Logger.log_i(self, " open url - ", url)
			OS.shell_open(url)
		PlatformsInfo.NAME_OS_TVOS :
			Logger.log_i(self, " pressed like button")
			var url = "https://apps.apple.com/app/id%s?action=write-review" % apple_id_app
			Logger.log_i(self, " open url - ", url)
			OS.shell_open(url)
		PlatformsInfo.NAME_OS_OSX :
			Logger.log_i(self, " pressed like button")
			var url = "https://apps.apple.com/app/id%s?action=write-review" % apple_id_app
			Logger.log_i(self, " open url - ", url)
			OS.shell_open(url)
		PlatformsInfo.NAME_OS_ANDROID :
			Logger.log_i(self, " press like button")
			var url = "https://play.google.com/store/apps/details?id=rmb.games.knowledge.park.full.d3"
			OS.shell_open(url)
	
	Analitics.send_event_simple("press_the_button_like")
	
	Logger.log_i(self, " ON LIKE")

func on_more_games() -> void :
	match OS.get_name() :
		PlatformsInfo.NAME_OS_IOS, PlatformsInfo.NAME_OS_TVOS :
			Logger.log_i(self, " pressed more games button")
			var url = "https://apps.apple.com/app/id1578719705"
			Logger.log_i(self, " open url - ", url)
			OS.shell_open(url)
		PlatformsInfo.NAME_OS_OSX :
			Logger.log_i(self, " pressed more games button")
			var url = "https://apps.apple.com/app/id1578719705"
			Logger.log_i(self, " open url - ", url)
			OS.shell_open(url)
		PlatformsInfo.NAME_OS_ANDROID :
			Logger.log_i(self, " pressed more games button")
			var url = "https://play.google.com/store/apps/details?id=rmb.games.knowledge.park.full"
			OS.shell_open(url)
		PlatformsInfo.NAME_OS_WINDOWS :
			Logger.log_i(self, " pressed more games button")
			var url = "https://store.steampowered.com/app/1841910"
			OS.shell_open(url)
	
	Analitics.send_event_simple("press_the_button_more_games")
	
	Logger.log_i(self, " ON MORE GAMES")

func _exit_tree() -> void:
	set_paused_counted(0)

func get_screen_orientation() -> int :
	var store_kit_2 = GamePlugin.get_plugin("GodotStoreKit2")
	if store_kit_2 :
		return store_kit_2.get_screen_orientation()
	
	return OS.screen_orientation


var _current_play_time := 0.0
func update_status_force() -> void :
	_on_update_status()
	return

func _on_update_status() -> void :
	if Analitics and Singletones.get_Achivment() and Singletones.get_GameSaveCloud() :
		Analitics.send_event_simple("update_player_state", {
			"coin" : Singletones.get_Achivment().rmb_coin.get_value_current(),
			"coin_take" : Singletones.get_Achivment().rmb_coin.value_take,
			"coin_cost" : Singletones.get_Achivment().rmb_coin.value_cost,
			"total_play_time" : Singletones.get_GameSaveCloud().game_state.total_play_time,
			"current_play_time" : _current_play_time
		})


func _physics_process(delta: float) -> void:
	_current_play_time += delta
	var cloud := Singletones.get_GameSaveCloud()
	if cloud :
		if cloud.game_state :
			cloud.game_state.total_play_time += delta
