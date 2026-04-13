#class_name Delegator
extends Spatial

signal goto_menu()
signal open_sscreen_learn()
signal change_world(world_num)
signal finished_animation_first_game()
signal finished_func_start_game()
signal loaded_finished()
signal hide_occluders_camera()

const Analitics := preload("res://content/analitics/analitics.gd")
const PopupFeedbackFabrick := preload("res://content/ui/popup_rateme/popup_rateme_fabrick.gd")
const PopupMoreGamesFabric := preload("res://content/ui/popup_more_games/popup_more_games_fabric.gd")
const PlatformsInfo := preload("res://content/platforms_info/platforms_info.gd")
const WorldsConsts := preload("res://content/world_map/worlds_consts.gd")
const NetworkConst := preload("res://content/network/network_const.gd")
const CharacterConst := preload("res://content/character/characters_consts.gd")
const RewardItemsConst := preload("res://content/ui/reward_items/reward_items_const.gd")
const LevelColorConst := preload("res://content/character/name_player/level_color_const.gd")

const TITLE_LOAD_PKG_PATH := ("res://content/ui/title_load.tscn")

const POPUP_PLAY_MP_GAME_PATH := "res://content/ui/network/poup_play_mp_game/popup_play_mp_game.tscn"
const POPUP_PLAY_MP_GAME := preload("res://content/ui/network/poup_play_mp_game/popup_play_mp_game.gd")

const SUB_FABRIC := preload("res://content/ui/subscription/subscription_v3/subscription_fabric_v3.gd")
const SCREEN_SUB := preload("res://content/ui/subscription/subscription_v3/screen_subscription_v3.gd")
const SubscriptionConst := preload("res://content/ui/subscription/subscription_const.gd")

const CUBEMAP_MANAGER := preload("res://content/cubemaps/cubemaps_manager.gd")

const BOT_PATH := "res://content/character/player_network.tscn"
const BOT := preload("res://content/character/player_network.gd")

var is_loaded := false
var is_change_world := false
var _count_go_to_player := 0

const LOW := 0
const MED := 1
const HIGH := 2
const ULTRA := 3

var world_distance_far := [
	70, #35,
	70, #45,
	80, #55,
	100
]

var level_distance_far := [
	55, #30,
	55, #30,
	65, #40,
	85
]

var current_game
var current_name_game := ""

const PLAYER_CHARACTER_PATH := ("res://content/character/PlayerCharacter.tscn")
const PlayerCharacter := preload("res://content/character/character_v2.gd")

const POPUP_DAILY_GIFT_PATH := "res://content/ui/gift_window/gift_window.tscn"

var _levels_path := {
}

var _levels_pos := {
}

onready var pos_spawn_test := $PosSpawnTest

onready var _path_system := $PointsPath/PathSystem
onready var _points_levels := $PointsPath/PointsLevels
onready var _players_network := $RoomList/Island/PlayersNetwork
onready var _timer_spawn_bot := $TimerSpawnBot

onready var _teleport_point_to_home_world := $"%TeleportToHomePoint" as Spatial

onready var _cubemap_manager := $CubemapsManager

onready var _timer_level_before_screen_sub := $TimerLevelBeforeScreenSub

onready var _level_list := $RoomList/Island/Levels
onready var _direction_light := $DirectionalLightPool/DirectionalLight

onready var _ui_toch_controller = $ui_touch_controller

onready var _env := $WorldEnvironment
var _env_params: Environment = null

onready var player_camera = $InterpolatedCamera as Camera
var player: PlayerCharacter = null

onready var _pos_start_teleport := $PosStartTeleport
onready var _pos_first_spawn_player := $PosFirstSpawnPlayer
onready var _pos_car_games := $PosCarGames

var start_game_position: Transform

onready var _enemy := $RoomList/Island/Enemy
onready var _camera_nemu := $CameraMenu
onready var _stars := $RoomList/Island/Stars
onready var _anim_occl := $CameraMenu/AnimationOccl

onready var _price_objects := $RoomList/Island/PriceObjects

onready var _stars_pool_game_state := $StarsPoolGameState

onready var _arrow := $Arrow

onready var _particle_snow := $"%CPUParticlesSnow" as CPUParticles

var need_show_video_tutor := false

var _camera_menu_enable := true


export(WorldsConsts.WORLDS) var world_type := WorldsConsts.WORLDS.WORLD_FIRST
export(bool) var pathfind_disabled := false


# network
enum TYPE_DATA {
	ADD_PLAYER_NETWORK,
	DEL_PLAYER_NETWORK,
	ADD_BOT,
	SHOW_POPUP_PLAY_MP_GAME,
}
enum NAME_DATA {
	TYPE_UPDATE,
	TYPE,
	IDX_OBJ,
	NAME,
	IDX_POS,
	BOT_NAME,
	BOT_POS,
	BOT_TARGET,
	BOT_NUM_WORLD,
	BOT_IDX_CHARACTER,
	BOT_CLOTHES,
	BOT_LEVEL_ACHIV,
	BOT_IS_ACTIVE_SUB,
	POPUP_PLAY_MP_GAME_NAME_ACHIV,
	POPUP_PLAY_MP_GAME_TIME,
	POPUP_PLAY_MP_GAME_OFFSET_TIME,
}

var _data_network_add_player_network := {
	NAME_DATA.TYPE_UPDATE : NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_WORLD,
	NAME_DATA.TYPE : TYPE_DATA.ADD_PLAYER_NETWORK,
	NAME_DATA.NAME : "",
	NAME_DATA.IDX_POS : 0,
}

var _data_network_del_player_network := {
	NAME_DATA.TYPE_UPDATE : NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_WORLD,
	NAME_DATA.TYPE : TYPE_DATA.ADD_PLAYER_NETWORK,
	NAME_DATA.IDX_POS : 0,
}

var _data_network_add_bot := {
	NAME_DATA.TYPE_UPDATE : NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_WORLD,
	NAME_DATA.TYPE : TYPE_DATA.ADD_BOT,
	NAME_DATA.BOT_NAME : "",
	NAME_DATA.BOT_POS : null,
	NAME_DATA.BOT_TARGET : "",
	NAME_DATA.BOT_NUM_WORLD : 0,
	NAME_DATA.BOT_IDX_CHARACTER : 0,
	NAME_DATA.BOT_CLOTHES : [],
	NAME_DATA.BOT_LEVEL_ACHIV : 0.2,
	NAME_DATA.BOT_IS_ACTIVE_SUB : false,
}

var _data_network_show_popup_play_mp_game := {
	NAME_DATA.TYPE_UPDATE : NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_WORLD,
	NAME_DATA.TYPE : TYPE_DATA.SHOW_POPUP_PLAY_MP_GAME,
	NAME_DATA.POPUP_PLAY_MP_GAME_NAME_ACHIV : "",
	NAME_DATA.POPUP_PLAY_MP_GAME_TIME : 0,
	NAME_DATA.POPUP_PLAY_MP_GAME_OFFSET_TIME : 0,
}


var _bot_names := [
	"SunnyBunny",
	"HappyPaws",
	"FrostyBear",
	"SpeedyTurtle",
	"SillyKitty",
	"StarrySky",
	"MagicBubbles",
	"JellyBean",
	"GigglyPanda",
	"JasonFun",
	"LoganLion",
	"TinyRainbow",
	"BubblePop",
	"ThunderPuff",
	"EthanJoy",
	"WigglyWorm",
	"TylerSmiles",
	"HappyDino",
	"ConnorTiger",
	"BouncyFrog",
	"CuddlyKoala",
	"BrandonBear",
	"GummyShark",
	"LollipopStar",
	"NathanSpark",
	"GiggleMonster",
	"FireflyGlow",
	"Marshmallow",
	"AustinBubbles",
	"TwinkleToes",
	"DoodleBug",
	"DylanSunny",
	"ZippyZebra",
	"SnappyTurtle",
	"FluffyBunny",
	"CuddlyPuppy",
	"RyanRocket",
	"SqueezyPeach",
	"CalebPanda",
	"WaffleSprout",
	"JollyMonkey",
	"JacobSmiley",
	"CupcakeZoom",
	"TootsieTiger",
	"MasonBumble",
	"GummyGiggles",
	"WigglyPanda",
	"LiamHug",
	"CheekyChipmunk",
	"BouncySprout",
	"PuddingPaws",
	"JumpyLlama",
	"NoahZoom",
	"SnuggleDuck",
	"RainbowRacer",
	"PoppyToad",
	"SillyGiggles",
	"ZacharySprout",
	"TippyTiger",
	"SqueakyMouse",
	"DoodleDaisy",
	"CarterZippy",
	"JollyKangaroo",
	"BuzzyBee",
	"HunterSunny",
	"WigglesWoof",
	"FuzzyBubbles",
	"ElijahCupcake",
	"CloudyKitten",
	"TinkerBear",
	"ChocoBunny",
	"WyattHug",
	"SprinklesJoy",
	"OwenPudding",
	"StarryKitten",
	"GoofyPaws",
	"SnappyFox",
	"JumpyJelly",
	"WobblyPenguin",
	"ZoomyCheetah",
	"FluffyLamb",
	"ColtonSnuggles",
	"TippyToad",
	"PuddingKitty",
	"WigglyHedgehog",
	"CupcakeBunny",
	"LandonHoppy",
	"FuzzyBear",
	"SmileyStar",
	"IsaacChoco",
	"TwinkleLamb",
	"SnappyHug",
	"JumpyCupcake",
	"SqueezyBear",
	"EvanBouncy",
	"DizzyMonkey",
	"JordanGiggles",
	"WobblyBubbles",
	"TinyRainbow",
	"JellyWiggles",
]


func _to_string() -> String:
	return "[Delegate]"

func _init() -> void :
	print(self, "create ...")

func _ready():
#	if OS.get_name() in PlatformsInfo.get_names_os_pc() :
#		if _direction_light :
#			_direction_light.shadow_enabled = true
	
	
	_cubemap_manager.start_cubemaps()
	Singletones.get_PopupsManager().connect("show_all_popups_finished", self, "_PopupsManager_show_all_popups_finished")
	Singletones.get_PopupsManager().connect("create_popup", self, "_PopupsManager_create_popup")
	call_deferred("_deferred_init_post_ready")
	
	call_deferred("_start_timer_spawn_bot")
	
	for node in get_tree().get_nodes_in_group("UI_BUILD") :
		node.visible = false
	
	
	


func _change_grass_to_snow_mat(path: String) -> void :
	var mat := load(path) as Material3D
	mat.albedo_texture = load("res://resources/map_textures/snow.png")
	mat.albedo_color = Color.white
	mat.flags_unshaded = true
	mat.roughness = 1.0
	mat.metallic = 0.1
	mat.metallic_specular = 0.1


func _init_season_materials() -> void :
	var global_game := Singletones.get_GlobalGame()
	var season := global_game.get_season_type()
	
	if season == global_game.SEASON_CHRISMAS :
		_particle_snow.emitting = true
	
	match season :
		global_game.SEASON_CHRISMAS :
			
			_change_grass_to_snow_mat("res://resources/models/kenney_assets/naturekit/grass.material")
			_change_grass_to_snow_mat("res://resources/models/world_objects/mound/mound_mat.material")
			_change_grass_to_snow_mat("res://resources/models/world_objects/mound/mount_mat.material")
			
		
			
			var mat_terrain := load("res://resources/terrain/mat_terrain_shader.tres") as ShaderMaterial
			mat_terrain["shader_param/texture_grass_color"] = load("res://resources/models/map_textures/snow.png")
			mat_terrain["shader_param/texture_grass_modulate"] = Color.white
		_ :
			return

var msec := Time.get_ticks_msec()
var msec_limit := 2000
var wait_sec := 0.1

const AsyncWorldResourceLoaderNoBuilds := preload("res://content/world_map/async_world_resource_loader_no_builds.gd")
var _asyn_loader = null

func _deferred_init_post_ready() -> void :
	if _env :
		_env_params = _env.environment
	Singletones.get_Global().last_pos = Singletones.get_GameSaveCloud().game_state.player_position
	menu()
	
	yield(get_tree(), "idle_frame")
	if not is_inside_tree() : return
	
	_asyn_loader = AsyncWorldResourceLoaderNoBuilds.new()
	add_child(_asyn_loader)
	_asyn_loader.connect("finished_load_placeholders", self, "_deferred_placeholders", [], CONNECT_DEFERRED)
	_asyn_loader.connect("finished_load", self, "_on_asyn_loader_finished_loader", [], CONNECT_DEFERRED)
	
	if get_tree().current_scene == self :
		_cubemap_manager.stop_cubemaps()
		player_camera.current = true
		
		

func _deferred_placeholders() -> void :
	_ready_prev()
	_set_levels_path()
	_set_levels_pos()
	_stars_pool_game_state.load_coins()
	
	_anim_occl.play("play")

func _on_asyn_loader_finished_loader() -> void :
	is_loaded = true
	if _asyn_loader.is_inside_tree() :
		_asyn_loader.queue_free()
	else :
		_asyn_loader.free()
	
	_asyn_loader = null
	if _direction_light :
		_ui_toch_controller.init_button_day_night(_env.environment, _direction_light, _cubemap_manager)
	#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MouseCursor.visible_cursor = true
	Logger.log_i(self, "SHOW MOUSE MAIN WORLD")
	emit_signal("loaded_finished")
	_ready_post()
	
	if _camera_menu_enable :
		_camera_nemu.current = true
	else :
		player_camera.current = true
	
	if get_tree().current_scene == self :
		_cubemap_manager.stop_cubemaps()
		player_camera.current = true
		player_camera.far = 1000000.0
		player_camera.fov = 120.0
	

func _exit_tree() -> void:
	if is_instance_valid(_asyn_loader) :
		if _asyn_loader.is_inside_tree() :
			_asyn_loader.queue_free()
		else :
			_asyn_loader.free()
		_asyn_loader = null

func _hide_title_load() -> void :
	emit_signal("hide_occluders_camera")


func _ready_prev() -> void : # virtual
	pass

func _ready_post() -> void : # virtual
	_init_season_materials()
	
	if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES3 :
		var mat_house := load("res://resources/materials/mat_default_AO.tres") as ShaderMaterial
		mat_house["shader_param/vertex_color"] = 0.8
		mat_house["shader_param/power"] = 1.0
		mat_house["shader_param/brightness"] = 0.656
		mat_house["shader_param/contrast"] = 1.142
		mat_house["shader_param/saturation"] = 1.519
		
		mat_house = load("res://resources/materials/mat_default_AO_TEX.tres") as ShaderMaterial
		mat_house["shader_param/vertex_color"] = 0.8
		mat_house["shader_param/power"] = 1.0
		mat_house["shader_param/brightness"] = 0.656
		mat_house["shader_param/contrast"] = 1.142
		mat_house["shader_param/saturation"] = 1.519
		
		
		var mat_tree_large := load("res://resources/models/tree_low/mat_SMTreeLarge_base.material")
		mat_tree_large["shader_param/brightness"] = 0.737
		mat_tree_large["shader_param/contrast"] = 1.304
		mat_tree_large["shader_param/saturation"] = 1.166
		
		var mat_tree_palm := load("res://resources/models/tree_low/mat_SMPalmBush_base.material")
		mat_tree_palm["shader_param/brightness"] = 0.737
		mat_tree_palm["shader_param/contrast"] = 1.304
		mat_tree_palm["shader_param/saturation"] = 1.166
		
		
		var mat_laminary := load("res://resources/materials/mat_shader_laminary.tres") as ShaderMaterial
		mat_laminary["shader_param/vertex_color"] = 0.8
		mat_laminary["shader_param/power"] = 1.0
		mat_laminary["shader_param/brightness"] = 0.656
		mat_laminary["shader_param/contrast"] = 1.142
		mat_laminary["shader_param/saturation"] = 1.519
		
		
		var mat_corel := load("res://resources/materials/mat_shader_corel.tres") as ShaderMaterial
		mat_corel["shader_param/vertex_color"] = 0.8
		mat_corel["shader_param/power"] = 1.0
		mat_corel["shader_param/brightness"] = 0.656
		mat_corel["shader_param/contrast"] = 1.142
		mat_corel["shader_param/saturation"] = 1.519
		
func _set_levels_path() -> void : # virtual
	pass

func _set_levels_pos() -> void : # virtual
	pass


func update_network_global_data(data: Dictionary, _peer_id: String) -> void :
	match data[NAME_DATA.TYPE_UPDATE] as int:
		NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_PLAYER_NETWORK:
			var path : String = "RoomList/Island/PlayersNetwork/"
			if not has_node(path + str(data[NAME_DATA.IDX_OBJ])):
				var path_dog := "res://content/character/player_network.tscn"
				var dog = ResourceLoader.load(path_dog, "", GlobalSetupsConsts.NO_CACHED).instance()
				dog.name = str(data[NAME_DATA.IDX_OBJ])
				_players_network.add_child(dog)
				
			else:
				var player_network = get_node(path + str(data[NAME_DATA.IDX_OBJ]))
				if is_instance_valid(player_network):
					if player_network.has_method("update_network_data"):
						player_network.update_network_data(data)
		NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_PLAYER_NETWORK_LEVEL:
			if current_game and is_instance_valid(current_game):
				if current_game.has_method("update_network_data"):
					current_game.update_network_data(data)
		NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_PLAYER:
			if player and is_instance_valid(player):
				if player.has_method("update_network_data"):
						player.update_network_data(data)
		NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_WORLD:
			match data[NAME_DATA.TYPE] as int:
				TYPE_DATA.ADD_BOT:
					Logger.log_i(self, " Update network data. Create bot")
					var pra : PoolRealArray = data[NAME_DATA.BOT_POS]
					var pos := Vector3(pra[0], pra[1], pra[2])
					_create_bot_locale(
						data[NAME_DATA.BOT_NAME] as String,
						pos,
						data[NAME_DATA.BOT_TARGET] as String,
						data[NAME_DATA.BOT_NUM_WORLD] as int,
						data[NAME_DATA.BOT_IDX_CHARACTER] as int,
						data[NAME_DATA.BOT_CLOTHES] as Array,
						data.get(NAME_DATA.BOT_LEVEL_ACHIV, 0.2) as float,
						data.get(NAME_DATA.BOT_IS_ACTIVE_SUB, false) as bool
					)
				TYPE_DATA.SHOW_POPUP_PLAY_MP_GAME:
					show_popup_mp_game(
						data.get(NAME_DATA.POPUP_PLAY_MP_GAME_NAME_ACHIV, "") as String,
						data.get(NAME_DATA.POPUP_PLAY_MP_GAME_TIME, 0) as int,
						data.get(NAME_DATA.POPUP_PLAY_MP_GAME_OFFSET_TIME, 0) as int
					)
		NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_LEVELS:
			if current_game and is_instance_valid(current_game):
				if current_game.has_method("update_network_data"):
					current_game.update_network_data(data)
		NetworkConst.TYPE_DATA_OPEN_GAME.UPDATE_OG_TRIGGER:
			var path : String = "RoomList/Island/Enemy/"
			var path_full : String = path + str(data[NAME_DATA.IDX_OBJ])
			if has_node(path_full):
				var enemy = get_node(path_full)
				if is_instance_valid(enemy):
					if enemy.has_method("update_network_data"):
						enemy.update_network_data(data)


func _create_bot() -> void :
	Logger.log_i(self, " Create bot")
	
	if _points_levels.get_child_count() == 0 :
		return
	
	var name_bot : String = _bot_names[randi() % _bot_names.size()]
	var pos_bot : Vector3 = Vector3(randi() % 300 - 150, 0.0, randi() % 300 - 150)
	#var pos_bot : Vector3 = _pos_start_teleport.global_position # test start pos
	var target : String = _points_levels.get_child(randi() % _points_levels.get_child_count()).name
	var num_world : int = Singletones.get_GameSaveCloud().game_state.world_num
	var idx_character : int = randi() % CharacterConst.LIST_PATH.size()
	var clothes := [
		RewardItemsConst.hats_list[randi() % RewardItemsConst.hats_list.size()],
		RewardItemsConst.skirts_list[randi() % RewardItemsConst.skirts_list.size()],
		RewardItemsConst.capes_list[randi() % RewardItemsConst.capes_list.size()],
		RewardItemsConst.bows_list[randi() % RewardItemsConst.bows_list.size()],
		RewardItemsConst.glasses_list[randi() % RewardItemsConst.glasses_list.size()],
		RewardItemsConst.amulets_list[randi() % RewardItemsConst.amulets_list.size()],
		RewardItemsConst.brasletes_list[randi() % RewardItemsConst.brasletes_list.size()],
	]
	for i in clothes.size():
		if randi() % 100 > 35:
			clothes[i] = ""
	if randi() % 100 > 30:
		clothes[1] = ""
	var level_achiv : float = randf() * LevelColorConst.MAX_LEVEL
	var is_active_sub : bool = (randf() > 0.7)
	_create_bot_locale(name_bot, pos_bot, target, num_world, idx_character, clothes, level_achiv, is_active_sub)
	
	_data_network_add_bot[NAME_DATA.BOT_NAME] = name_bot
	var step := 0.01
	_data_network_add_bot[NAME_DATA.BOT_POS] = PoolRealArray([
		stepify(pos_bot.x, step),
		stepify(pos_bot.y, step),
		stepify(pos_bot.z, step),
	])
	_data_network_add_bot[NAME_DATA.BOT_TARGET] = target
	_data_network_add_bot[NAME_DATA.BOT_NUM_WORLD] = num_world
	_data_network_add_bot[NAME_DATA.BOT_IDX_CHARACTER] = idx_character
	_data_network_add_bot[NAME_DATA.BOT_CLOTHES] = clothes
	_data_network_add_bot[NAME_DATA.BOT_LEVEL_ACHIV] = level_achiv
	_data_network_add_bot[NAME_DATA.BOT_IS_ACTIVE_SUB] = is_active_sub
	var key : int = NetworkConst.GLOBAL_TYPE_DATA.OPEN_GAME
	if Singletones.get_Network() :
		if Singletones.get_Network().api :
			Singletones.get_Network().api.setup_data(key, _data_network_add_bot)
			Singletones.get_Network().api.send_data_to_all()
	

func _create_bot_locale(
			name_bot: String,
			pos_bot: Vector3,
			target: String,
			num_world: int,
			idx_character: int,
			clothes : Array,
			level_achiv : float,
			is_active_sub : bool
		) -> void :
	Logger.log_i(self, " Create bot locale")
	if not num_world == Singletones.get_GameSaveCloud().game_state.world_num:
		Logger.log_i(self, " Create bot locale. NOT create - num world other")
		return
	if not _points_levels.has_node(target):
		Logger.log_i(self, " Create bot locale. NOT create - point level not has target")
		return

	var bot = ResourceLoader.load(BOT_PATH, "", GlobalSetupsConsts.NO_CACHED).instance()
	_players_network.add_child(bot)
	
	bot.is_bot = true
	bot.update_name_player(name_bot)
	bot.update_idx_character(idx_character)
	bot.update_clothes(clothes)
	bot.update_level(level_achiv)
	bot.update_is_active_sub(is_active_sub)
	bot.update_num_world(num_world)
	var point_target : Position3D = _points_levels.get_node(target)
	var list_points : Array = _path_system.find_and_get_path_to_point(pos_bot, point_target)
	bot.set_points_path_and_run(list_points)

	Logger.log_i(self, " Create bot locale completed")


func start() -> void :
	
	_cubemap_manager.stop_cubemaps()
	_play_world_music()
	
	_ui_toch_controller.close_menu()
	
	_setup_visible_hints_outside_game()
	
	if Singletones.get_Global().last_pos == Vector3.ZERO :
		var pkg_player: PackedScene = ResourceLoader.load(PLAYER_CHARACTER_PATH, "", GlobalSetupsConsts.NO_CACHED)
		player = pkg_player.instance()
		add_child(player)
		player.owner = self
		
		#_animation_first_game()
		#yield(self, "finished_animation_first_game")
	else:
		if need_show_video_tutor:
			need_show_video_tutor = false
			var pkg_title_load: PackedScene = ResourceLoader.load(TITLE_LOAD_PKG_PATH, "", GlobalSetupsConsts.NO_CACHED)
			var title_load = pkg_title_load.instance()
			add_child(title_load)
			title_load.show_menu_list_players_and_add_list_players(Singletones.get_Global().list_network_players)
			title_load.start_title_timer(5.0)
			yield(title_load, "begin_hide")
		
		var pkg_player: PackedScene = ResourceLoader.load(PLAYER_CHARACTER_PATH, "", GlobalSetupsConsts.NO_CACHED)
		player = pkg_player.instance()
		add_child(player)
		player.owner = self
	
	_ui_toch_controller.get_ui().show()
	_setup_visible_hints_outside_game()
	_setup_visible_ui_elements()
	
	if Singletones.get_LearnSystem().is_learning():
		_ui_toch_controller.get_ui().hide()
		_ui_toch_controller.get_ui_learning_run().show()
		MouseCursor.visible_cursor = true
	
	_camera_menu_enable = false
	_camera_nemu.current = false
	player_camera.current = true
	_to_world_render()
	if Singletones.get_Global().last_pos != Vector3.ZERO :
		player.transform.origin = Singletones.get_Global().last_pos + Vector3.UP
		if pathfind_disabled :
			player.global_transform.origin = _pos_start_teleport.global_transform.origin
		else :
			player.global_transform.origin = _path_system.find_first_point(player.global_transform.origin).global_transform.origin
	else :
		_player_to_start_pos()
	
	if is_change_world:
		player_to_pos_start_teleport()
	
	_arrow.target_player_path = player.get_path()
	
	_level_list.visible = true
	_stars.visible = true
	player_camera.target = Singletones.get_GameUiDelegate().share.character_camera.get_path()
	call_deferred("_reset_player_deferred")
	emit_signal("finished_func_start_game")
	
	var force_play_level := Singletones.get_EventHandler().get_open_level()
	if force_play_level.empty():
		if not Singletones.get_GameSaveCloud().game_state.daily_gifts.is_rewarded_current_day() :
#			var popup: Node = ResourceLoader.load(POPUP_DAILY_GIFT_PATH, "", GlobalSetupsConsts.NO_CACHED).instance()
#			popup.connect("open_gift", _ui_toch_controller, "play_animation_add_reward_item")
#			get_tree().current_scene.add_child(popup)
			Singletones.get_PopupsManager().add_popup_path(POPUP_DAILY_GIFT_PATH)
	
	_start_post()
	
	if Singletones.get_PopupsManager().is_empty():
		call_deferred("_start_next_level_from_learn_system")
		if Singletones.get_LearnSystem().is_learning() or is_change_world:
			var level : float = LevelColorConst.get_level_from_achiv_real()
			player.show_star_to_new_level(level)
	
	get_tree().create_timer(0.5).connect("timeout", self, "teleport_to_point_from_map")
	call_deferred("teleport_to_point_from_map")
	call_deferred("teleport_to_point_from_popup_mp_game")

func _start_post() -> void : # virtual
	pass

func _play_world_music() -> void : # virtual
	pass

func _animation_first_game() -> void : # virtual
	pass

func _player_to_start_pos() -> void :
	#player_to_pos_start_teleport()
	player.transform.origin = _pos_first_spawn_player.transform.origin

func player_to_pos_start_teleport() -> void :
	player.transform.origin = _pos_start_teleport.transform.origin

func menu() -> void :
	_cubemap_manager.start_cubemaps()
	player_camera.target = NodePath()
	if _ui_toch_controller :
		if  _ui_toch_controller.get_ui() :
			 _ui_toch_controller.get_ui().hide()
	if player :
		player.queue_free()
	player = null
	_arrow.player = null
	_camera_menu_enable = true
	_camera_nemu.current = true
	player_camera.current = false
	_stars.visible = false
	_to_world_render()
	if Singletones.get_MusicManager() :
		Singletones.get_MusicManager().stop()
	#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _to_level_render() -> void :
	var distance := level_distance_far[Singletones.get_Global().quality] as float
	
	player_camera.far = distance
	_camera_nemu.far = distance
	if _env_params and _env_params.fog_enabled :
		_env_params.fog_depth_begin = distance - 10
		_env_params.fog_depth_end = distance - 5

func _to_custom_render(distance: float) -> void :
	player_camera.far = distance
	_camera_nemu.far = distance
	if _env_params and _env_params.fog_enabled :
		_env_params.fog_depth_begin = distance - 10
		_env_params.fog_depth_end = distance - 5


func _to_world_render() -> void :
	var distance := world_distance_far[Singletones.get_Global().quality] as float
	
	player_camera.far = distance
	_camera_nemu.far = distance
	if _env_params and _env_params.fog_enabled :
		_env_params.fog_depth_begin = distance - 15
		_env_params.fog_depth_end = distance - 5

func _rateus_after_event_handler() -> void :
	var popup: Node = ResourceLoader.load(
		"res://content/ui/popup_rateme_v2/popup_request_rateus_v4.tscn",
		"", 
		GlobalSetupsConsts.NO_CACHED).instance()
	get_tree().current_scene.add_child(popup)
	popup.type_rateus = popup.TYPE_RATEUS.NATIVE



func go_to_player(game):
	Singletones.get_Global().is_in_game = false
	Singletones.get_Global().lock_jump = false
	Singletones.get_Global().ui_touch_controller.grab_all_screen_stick(false)
	_go_to_player_prev(game)
	
	var camera := get_viewport().get_camera()
	if camera :
		if "interpolate_weight" in camera :
			camera.interpolate_weight = 0.5
	
	var force_play_level := Singletones.get_EventHandler().get_open_level()
	if not force_play_level.empty():
		pass
		#_rateus_after_event_handler()
	
	Singletones.get_EventHandler().clear()
	
	_timer_level_before_screen_sub.stop()
	pass #TODO print("close")
	AudioServer.set_bus_volume_db(3, -10.0) # Footstep
	_arrow.visible_arrow(false)
	_to_world_render()
	var root_node = game
	root_node.call_deferred("exit")
	get_tree().paused = false
	Singletones.get_GameUiDelegate().share.disconnect("close", self, "_on_close_goto_game")
	_ui_toch_controller.get_ui().show()
	_ui_toch_controller.get_menu().show()
	_ui_toch_controller.get_teleport().show()
	_ui_toch_controller.get_custom_char().show()
	_ui_toch_controller.set_visible_advanced_button(true)
	_ui_toch_controller.set_visible_buttons_emotion(true)
	_ui_toch_controller.show_stick_right()
	_ui_toch_controller.enable_second_coll_left_stick(false)
	_ui_toch_controller.get_button_day_night().change_to_back_from_level()
	_ui_toch_controller.get_control_menu_list_players().show()
	_ui_toch_controller.show_menu_list_players_few_seconds()
	_ui_toch_controller.to_free_game()
	_ui_toch_controller.reset_icon_jump()
	
	
	if Singletones.get_LearnSystem().is_learning():
		_ui_toch_controller.get_ui().hide()
		_ui_toch_controller.get_ui_learning_run().show()
		MouseCursor.visible_cursor = true
		_reset_triggers()
	else :
		_ui_toch_controller.call_deferred("force_mode_player")
		get_tree().create_timer(0.5).connect("timeout", _ui_toch_controller, "force_mode_player")
		
	
	Singletones.get_GameUiDelegate().share.visible = false
	Singletones.get_GameUiDelegate().share.set_ui_star_visible(true)
	_setup_visible_hints_outside_game()
	player_camera.target = Singletones.get_GameUiDelegate().share.character_camera.get_path()
	if Singletones.get_GameUiDelegate().share.character_camera.global_transform.origin.distance_to(player_camera.global_transform.origin) > 50 :
		player_camera.global_transform = Singletones.get_GameUiDelegate().share.character_camera.global_transform
	player.global_transform = start_game_position
	Logger.log_i(self, " Set player position - ", player.global_transform.origin)
	_reset_player_deferred()
	_players_network.visible = true
	player.send_in_game(false)
	player.send_in_lobby(false)
	player.send_is_host(false)
	
	_play_world_music()
	
	current_name_game = ""
	
	for node in get_tree().get_nodes_in_group("HIDE_IN_LEVEL") :
		node.visible = true
	
	if _direction_light :
		_direction_light.visible = true
	Singletones.get_GameUiDelegate().share.force_black()
	Singletones.get_GameUiDelegate().share.transperent_show()
	
	_ui_toch_controller.enable_snow(true)
	
	Singletones.get_Achivment().show_popup_reward_last_achivment()
	
	_go_to_player_post(game)
	
	#PopupFeedbackFabrick.show_feedback()
	#PopupMoreGamesFabric.show_popup_more_games_levels()
	
	_count_go_to_player += 1
	if _count_go_to_player > 2 :
		Singletones.get_Global().register_notification()
	
	if Singletones.get_PopupsManager().is_empty():
		call_deferred("_start_next_level_from_learn_system")
	
	get_tree().create_timer(3.0).connect("timeout", self, "_reset_triggers")
	
	if Singletones.get_Global().teleport_from_home_world :
		if _teleport_point_to_home_world :
			player.global_position = _teleport_point_to_home_world.global_position
	

func _reset_triggers() -> void :
	Singletones.get_Global().last_trigger = null

func _start_next_level_from_learn_system() -> void :
	if not Singletones.get_LearnSystem().is_learning():
		return
	Singletones.get_Global().last_trigger = null
	
	Logger.log_i(self, " Learning. Start next level from learn system")
	
	if not Singletones.get_Global().player_character or not is_instance_valid(Singletones.get_Global().player_character):
		return
	
	#var key_level_current : String = Singletones.get_LearnSystem().get_current_key_level()
	if Singletones.get_LearnSystem().count_closed_levels_before_start_learning < Singletones.get_Global().count_drop_games_in_session:
		Logger.log_i(self, " Learning. Close learn lesson from close game")
		Analitics.send_event_simple("close_learn_lesson_from_close_game")
		_close_learning_and_goto_menu()
		return
	
	var key_level : String = Singletones.get_LearnSystem().get_key_next_level()
	Logger.log_i(self, " Learning. Key next level ", key_level)
	if not key_level.empty():
		_path_system.find_path_and_run(
			Singletones.get_Global().player_character.global_transform.origin,
			key_level
		)
		_ui_toch_controller.get_ui().hide()
		_ui_toch_controller.get_ui_learning_run().show()
	
	_ui_toch_controller.add_icons_achivs_to_learn_screen()
	
	if Singletones.get_LearnSystem().is_skip_run_after_teleport:
		_on_ui_touch_controller_skip_run_to_level()
		Singletones.get_LearnSystem().is_skip_run_after_teleport = false
	
	if Singletones.get_LearnSystem().is_end_learning:
		Logger.log_i(self, " Learning. Completed learn lesson")
		Analitics.send_event_simple("completed_learn_lesson")
		_close_learning_and_goto_menu()

func _close_learning_and_goto_menu() -> void :
	Logger.log_i(self, " Close learning and goto menu")
	_ui_toch_controller.get_ui_learning_run().hide()
	_path_system.stop_run()
	_ui_toch_controller.clear_path_levels()
	Singletones.get_LearnSystem().clear_list_levels()
	if player and player.is_on_floor() :
		Singletones.get_Global().last_pos = player.transform.origin
	emit_signal("goto_menu")
	emit_signal("open_sscreen_learn")

func is_need_learn_level() -> bool :
	if not Singletones.get_LearnSystem().is_learning():
		return true
		#return false # test
	
	if not Singletones.get_Global().player_character or not is_instance_valid(Singletones.get_Global().player_character):
		return false
	
	var point_level : Spatial = _path_system.get_point_level()
	if not point_level:
		return true
	
	var dist : float = point_level.global_transform.origin.distance_to(
		Singletones.get_Global().player_character.global_transform.origin
	)
	if dist < 2.5:
		return true
	return false

#TODO EventHandler
#TODO EventHandler
#TODO EventHandler
func teleport_to_point_from_event(point_level: String) -> void :
	if not Singletones.get_Global().player_character or not is_instance_valid(Singletones.get_Global().player_character):
		return
	
	if point_level.empty() :
		Logger.log_e(self, " teleport to point from event is empty! ", point_level)
		return
	
	if _path_system.force_teleport_player_to_point_level(point_level) :
		pass
		#Singletones.get_EventHandler().clear() # moved to go_to_player(game)
	else :
		Logger.log_w(self, " teleport to point from event failed! %s point not found!" % point_level)
		_path_system.force_teleport_player_to_point_level("TELEPORT")
		#emit_signal("change_world", world_type)
#TODO EventHandler
#TODO EventHandler
#TODO EventHandler

func teleport_to_point_from_map(force_now := false) -> void :
	
	
	if not Singletones.get_Global().player_character or not is_instance_valid(Singletones.get_Global().player_character):
		Logger.log_i(self, " teleport to point from map failed! Player is null")
		return
	
	var point_level : String = Singletones.get_Global().level_teleport
	if point_level == "SHOW_MAP_MENU":
		Logger.log_i(self, " show map menu from button play free")
		Singletones.get_Global().level_teleport = ""
		_ui_toch_controller._open_menu()
		return
	
	if point_level.empty() :
		Logger.log_i(self, " teleport to point from map is empty! ", point_level)
		return
	
	if Singletones.get_Global().teleport_from_home_world and not force_now:
		force_now = true
	
	if not force_now and _path_system.force_teleport_player_to_near_point_level(point_level) :
		Singletones.get_Global().level_teleport = ""
	elif force_now and _path_system.force_teleport_player_to_point_level(point_level) :
		Singletones.get_Global().level_teleport = ""
	else :
		Logger.log_i(self, " teleport to point from map failed! %s point not found!" % point_level)
		var teleport := "TELEPORT"
		if not Singletones.get_Global().force_teleport_point_next.empty() :
			teleport = Singletones.get_Global().force_teleport_point_next
			Singletones.get_Global().force_teleport_point_next = ""
			
		_path_system.force_teleport_player_to_point_level(teleport)

func teleport_to_point_from_popup_mp_game() -> void :
	if not Singletones.get_Global().player_character or not is_instance_valid(Singletones.get_Global().player_character):
		Logger.log_i(self, " teleport to point from popup mp game! Player is null")
		return
	
	var point_level : String = Singletones.get_Global().level_mp_teleport
	
	if point_level == "SHOW_MAP_MENU":
		Logger.log_i(self, " show map menu from button play free")
		Singletones.get_Global().level_mp_teleport = ""
		_ui_toch_controller._open_menu()
		return
	
	if point_level.empty() :
		Logger.log_i(self, " teleport to point from popup mp game is empty! ", point_level)
		return
	
	if _path_system.force_teleport_player_to_point_level(point_level) :
		Singletones.get_Global().level_mp_teleport = ""
	else :
		Logger.log_i(self, " teleport to point from popup mp game failed! %s point not found!" % point_level)
		_path_system.force_teleport_player_to_point_level("TELEPORT")


func show_popup_mp_game(id_achiv: String, time: int, offset_time: int) -> void :
	if has_node("PopupMPGame"):
		return
	if id_achiv.empty() or time < 1 or offset_time < 0:
		return
	
	var player__ = Singletones.get_Global().player_character
	if not player__ or not is_instance_valid(player__):
		return
	if player__.in_game or player__.in_lobby:
		return
	
	var popup : POPUP_PLAY_MP_GAME = ResourceLoader.load(POPUP_PLAY_MP_GAME_PATH, "", true).instance()
	popup.name = "PopupMPGame"
	add_child(popup)
	popup.world = self
	popup.start_popup(id_achiv, time, offset_time)

func send_show_popup_mp_game(id_achiv: String, time: int, offset_time: int) -> void :
	if has_node("PopupMPGame"):
		return
	if id_achiv.empty() or time < 1 or offset_time < 0:
		return
	
	_data_network_show_popup_play_mp_game[NAME_DATA.POPUP_PLAY_MP_GAME_NAME_ACHIV] = id_achiv
	_data_network_show_popup_play_mp_game[NAME_DATA.POPUP_PLAY_MP_GAME_TIME] = time
	_data_network_show_popup_play_mp_game[NAME_DATA.POPUP_PLAY_MP_GAME_OFFSET_TIME] = offset_time
	var key : int = NetworkConst.GLOBAL_TYPE_DATA.OPEN_GAME
	Singletones.get_Network().api.setup_data(key, _data_network_show_popup_play_mp_game)
	Singletones.get_Network().api.send_data_to_all()


func _PopupRateus_stars_less_five() -> void :
	PopupMoreGamesFabric.show_popup_more_games()

func _go_to_player_prev(_game) -> void : # virtual
	pass

func _go_to_player_post(_game) -> void : # virtual
	Logger.log_i(self, " super -> go to player pos ")

func _reset_player_deferred() -> void :
	if player and is_instance_valid(player):
		Singletones.get_Global().reset_player()
		player.set_collision_mask_bit(1, true)
		player_camera.current = true
		player.in_game = false
		player.in_lobby = false
		player.is_host = false
		player.visible = true
		player.freez = false
		player.enabled = true
		player.move_force = false
		player.run_force = false
		player.direction = Vector3.ZERO
	current_game = null
	_enemy.visible = true
	
	Singletones.get_Global().reset_target = null

func _load_level(game_name: String) -> void :
	var node_pos_level = _levels_pos[game_name]
	if node_pos_level:
		print(self, " load BEGIN ", "   LEVEL ", game_name, "   ", Time.get_ticks_msec(), " ", Engine.get_idle_frames())
		var scene_pkg = ResourceLoader.load(_levels_path[game_name], "", GlobalSetupsConsts.NO_CACHED)
		print(self, " load END ", "   LEVEL ", game_name, "   ", Time.get_ticks_msec(), " ", Engine.get_idle_frames())
		
		print(self, " instance BEGIN", "   LEVEL ", game_name, "   ", Time.get_ticks_msec(), " ", Engine.get_idle_frames())
		var scene : Spatial = scene_pkg.instance()
		print(self, " instance END", "   LEVEL ", game_name, "   ", Time.get_ticks_msec(), " ", Engine.get_idle_frames())
		scene.name = game_name
		print(self, " add node to tree BEGIN ", "   LEVEL ", game_name, "   ", Time.get_ticks_msec(), " ", Engine.get_idle_frames())
		_level_list.add_child(scene)
		print(self, " add node to tree END ", "   LEVEL ", game_name, "   ", Time.get_ticks_msec(), " ", Engine.get_idle_frames())
		
		scene.global_transform = node_pos_level.global_transform
		

func go_to_game_deferred(game: String, is_free := false, is_multiplayer := false) -> void :
	if not ProjectSettings.get_setting("monetization/is_free_level") :
		is_free = false
	go_to_game(game, is_free, is_multiplayer)
	#call_deferred("go_to_game", game, is_free, is_multiplayer)

func _resume_character_controlled() -> void :
	_reset_player_deferred()
	

func _stop_character_controlled() -> void :
	player.get_character().fcm.pop_state()
	player.get_character().fcm.push_state(player.get_character().fcm.IDLE)
	player.direction = Vector3.ZERO
	player.in_game = true
	#player.visible = false
	player.freez = true
	player.enabled = false
	player.run_force = false
	player.move_force = false
	_players_network.visible = false

#func go_to_game(game: String, is_free := false) -> void :

func go_to_game(game: String, is_free := false, is_multiplayer := false) -> void :
	Singletones.get_Global().is_in_game = true
	Singletones.get_Global().ui_touch_controller.grab_all_screen_stick(false)
	
	if OS.get_name() in PlatformsInfo.get_names_os_tv() :
		MouseCursor.visible_cursor = true
	_go_to_game_prev(game)
	
	_arrow.visible_arrow(true)
	AudioServer.set_bus_volume_db(3, -70.0) # Footstep
	start_game_position = player.global_transform
	if not game == "DressCollect":
		start_game_position.origin = Singletones.get_Global().get_closet_end_level_position()
		Singletones.get_Global().count_running_games_in_session += 1
	player.start_game_position = start_game_position
	if current_game :
		return
	_to_level_render()
	_ui_toch_controller.get_ui().hide()
	_ui_toch_controller.get_teleport().hide()
	_ui_toch_controller.get_custom_char().hide()
	_ui_toch_controller.set_visible_advanced_button(false)
	_ui_toch_controller.set_visible_buttons_emotion(false)
	_ui_toch_controller.get_ui_learning_run().hide()
	_ui_toch_controller.get_menu_list_players().hide_list_player()
	_ui_toch_controller.get_control_menu_list_players().hide()
	_ui_toch_controller.close_menu()
	_ui_toch_controller.get_button_day_night().change_to_day_for_level()
	player.get_character().fcm.pop_state()
	player.get_character().fcm.push_state(player.get_character().fcm.IDLE)
	player.direction = Vector3.ZERO
	player.visible = false
	player.freez = true
	player.enabled = false
	player.run_force = false
	player.move_force = false
	for node in get_tree().get_nodes_in_group("HIDE_IN_LEVEL") :
		node.visible = false
	_players_network.visible = false
	if not is_multiplayer:
		player.in_game = true
		player.send_in_game(true)
	else:
		player.in_lobby = true
		player.send_in_lobby(true)
	
	#_direction_light.visible = false
	Singletones.get_GameUiDelegate().share.force_black()
	Singletones.get_GameUiDelegate().share.transperent_show()
	Singletones.get_Global().setup_visible_hints_inside_game()
	current_name_game = game
	var root_node = _level_list.get_node(game)
	if root_node:
		current_game = root_node
		print(root_node)
		Singletones.get_GameUiDelegate().share.visible = true
		Singletones.get_GameUiDelegate().share.connect("close", self, "_on_close_goto_game", [root_node])
		root_node.start_game()
		_enemy.visible = false
		if not is_free :
			_timer_level_before_screen_sub.wait_time = SubscriptionConst.get_time_level_before_screen_sub(game)
			if Singletones.get_LearnSystem().is_learning():
				_timer_level_before_screen_sub.wait_time *= 0.5
				if game.find("ColoringCanvas") != -1 :
					_timer_level_before_screen_sub.wait_time = 17.0
			_timer_level_before_screen_sub.start()
	
	_go_to_game_post(game)

func _go_to_game_prev(_game: String) -> void : # virtual
	pass

func _go_to_game_post(_game: String) -> void : # virtual
	pass

func _setup_visible_hints_outside_game() -> void:
	var platrform_type := PlatformsInfo.get_platform_type() # PC, MOBILE

	for node in get_tree().get_nodes_in_group("UI_HINT") :
		if node is CanvasItem or node is Spatial :
			node.visible = false
			if node.is_in_group("OUTSIDE_GAME") :
				if node.is_in_group(platrform_type):
					node.visible = true

func _setup_visible_ui_elements() -> void :
	var platrform_type := PlatformsInfo.get_platform_type() # PC, MOBILE

	for node in get_tree().get_nodes_in_group("UI_ELEMENT") :
		if node is CanvasItem or node is Spatial :
			node.visible = false
			if node.is_in_group(platrform_type):
				node.visible = true


func _on_close_goto_game(node: Node) -> void :
	go_to_player(node)


func _on_ui_touch_controller_goto_menu() -> void:
	emit_signal("goto_menu")


func _on_AreaEndWorld_body_entered(body: Node) -> void:
	if body is KinematicBody :
		if body == player :
			var p : Vector3 = Singletones.get_Global().get_closet_end_level_position()
			body.freez = true
			body.global_transform.origin = p
			yield(get_tree(), "idle_frame")
			body.freez = false
			
			Singletones.get_Global().last_pos = p
			start_game_position.origin = p
			_set_levels_pos()


func _on_ui_touch_controller_teleport_to_start():
	player_to_pos_start_teleport()


func _on_AnimationOccl_animation_finished(_anim_name):
	_hide_title_load()


func _on_ui_touch_controller_teleport_to_car_games():
	player.transform.origin = _pos_car_games.transform.origin

func create_subs() -> void :
	var screen_sub : SCREEN_SUB = SUB_FABRIC.create()
	if screen_sub:
		screen_sub.connect("cancel_purchase_sub", self, "_ScreenSub_cancel_purchase_sub")

func _ScreenSub_cancel_purchase_sub() -> void :
	PopupMoreGamesFabric.show_popup_more_games_sub()
	Singletones.get_GameUiDelegate().share.close_game_with_drop()

func _on_TimerLevelBeforeScreenSub_timeout() -> void:
	if Singletones.get_Global().show_screen_sub_in_levels:
		Singletones.get_SubsChecker().force_check()
		var screen_sub : SCREEN_SUB = SUB_FABRIC.create()
		if screen_sub:
			screen_sub.connect("cancel_purchase_sub", self, "_ScreenSub_cancel_purchase_sub")




func _on_ui_touch_controller_skip_run_to_level() -> void:
	_ui_toch_controller.get_ui_learning_run().hide()
	Singletones.get_LearnSystem().setup_skip_run_after_teleport()
	_path_system.teleport_player_to_target_point()




func _on_PathSystem_last_point() -> void:
	_ui_toch_controller.get_ui_learning_run().hide()


func _on_ui_touch_controller_close_learning() -> void:
	Logger.log_i(self, " Close learn lesson from close button")
	Analitics.send_event_simple("close_learn_lesson_from_close_button")
	_close_learning_and_goto_menu()



func _PopupsManager_show_all_popups_finished() -> void:
	Logger.log_i(self, " SIGNAL Show all popups PopupsManager")
	if not player or not is_instance_valid(player):
		Logger.log_w(self, "  |-- Player is NULL")
		return
	
	if not _ui_toch_controller.get_inventory().visible:
		var level : float = LevelColorConst.get_level_from_achiv_real()
		player.show_star_to_new_level(level)
	
	call_deferred("_start_next_level_from_learn_system")

func _PopupsManager_create_popup(popup, path: String) -> void :
	if path == "res://content/ui/popup_rateme/popup_request_rateus_v3.tscn":
		popup.is_no_write = false
		popup.connect("stars_less_five", self, "_PopupRateus_stars_less_five")
	if path == POPUP_DAILY_GIFT_PATH:
		popup.connect("open_gift", _ui_toch_controller, "play_animation_add_reward_item")


func _on_ui_touch_controller_swap_level(key_level) -> void:
	if Singletones.get_LearnSystem().swap_next_level(key_level):
		_start_next_level_from_learn_system()


func _on_PathSystem_unit_path(unit: float) -> void:
	_ui_toch_controller.set_unit_path_levels(unit)



func _on_ui_touch_controller_pressed_button_to_learn() -> void:
	_close_learning_and_goto_menu()


func _on_ui_touch_controller_pressed_button_achiv(achiv: String) -> void:
	#_ui_toch_controller.close_menu()
	_ui_toch_controller.close_menu_with_anim()
	Singletones.get_Global().level_teleport = achiv
	teleport_to_point_from_map()


#var _list_paths := []
#func _make_path() -> void :
#	var point_target : Position3D = _points_levels.get_child(randi() % _points_levels.get_child_count())
#	var pos_bot := Vector3(randi()%300 - 150, 0.0, randi()%300 - 150)
#	var list_points : Array = _path_system.find_and_get_path_to_point(pos_bot, point_target)
#	_list_paths.append(list_points)


func _start_timer_spawn_bot() -> void :
	var count_players_network := 0
	for pl in _players_network.get_children():
		if pl is BOT:
			if not pl.is_bot:
				count_players_network += 1
	
	var step := 5.0 # sec
	_timer_spawn_bot.wait_time = step + step * count_players_network
	_timer_spawn_bot.start()

func _on_TimerSpawnBot_timeout() -> void:
# TODO BOT SPAWNER
#	var is_need_bot := false
#	var bots_count := 0
#	for i in _players_network.get_child_count() :
#		var pl := _players_network.get_child(i)
#		if pl is BOT :
#			if pl.is_bot :
#				bots_count += 1
#
#	if bots_count < 10 :
	
	if Singletones.get_Global().disabled_bots :
		
		for idx in _players_network.get_child_count() :
			var bot := _players_network.get_child(idx)
			if bot and bot.is_bot and bot.is_queued_for_deletion() == false :
				bot.queue_free()
		
		call_deferred("_start_timer_spawn_bot")
		return
	
	_create_bot()
	call_deferred("_start_timer_spawn_bot")
	
	


func _on_TimerCheckConnection_timeout() -> void:
	$TimerCheckConnection.wait_time = 15
	if Singletones.get_Network().api:
		Singletones.get_Network().api.check_connection_and_connect_to_open_game()


func _on_ui_touch_controller_change_world_to(id) -> void:
	if is_instance_valid(self) :
		emit_signal("change_world", id)
