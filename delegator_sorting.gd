extends "res://content/world_map/delegator_class.gd"

const ClothConst := preload("res://content/houses/dress_collect/clothes_const.gd")
const ScalesItemsConst := preload("res://content/houses/scales_sorting/scales_items_consts.gd")
const GameScalesItems := preload("res://content/game_save_cloud/game_state_scales_items.gd")

var SCREEN_CARGAMES_IN_PKG_PATH := ("res://content/ui/menus/screens_car_games/screen_car_games_in.tscn")

onready var _enemy_teleport := $RoomList/Island/Enemy/EnemyTeleport

# zoo sorting level
var _pond := "RoomList/Island/Decorations/Zoo/Pond"
var _paddock := "RoomList/Island/Decorations/Zoo/Paddock"
var _aviary_ground := "RoomList/Island/Decorations/Zoo/AviaryGround"
var _carousel := "RoomList/Island/Decorations/Zoo/Carousel"
var _trans_pond : Transform
var _trans_paddock : Transform
var _trans_aviary_ground : Transform
var _trans_carousel : Transform
var _hide_zoo_list := [
	"RoomList/Island/Decorations/Zoo/Animals",
	"RoomList/Island/Clothes",
	"RoomList/Island/Stars"
]

# train sorting level
var _train_path := "RoomList/Island/Decorations/Train/TrainDecoration"
var _waiters_train_path := "RoomList/Island/Decorations/Train/Waiters"
var _animation_train_path := "RoomList/Island/Decorations/Train/AnimationPlayerTrain"

var _scale_decors_path := "RoomList/Island/Enemy/EnemyScalesSorting/ScalesDecor"

# dress
var _clothes_path := "RoomList/Island/Clothes"
var _page_book := 0

# scales sorting
onready var _scales_items_path := "RoomList/Island/ScalesItems"
onready var _enemy_scales_sorting_path := "RoomList/Island/Enemy/EnemyScalesSorting"

# classics
onready var _hide_classics_list_path := [
	"RoomList/Island/Decorations/Trees/Tree_3_in_line33",
	"RoomList/Island/Decorations/Trees/Tree_3_in_line16",
	"RoomList/Island/Decorations/Trees/Tree_3_in_line15",
	"RoomList/Island/Decorations/Trees/Tree_3_in_line36",
	"RoomList/Island/Decorations/Trees/Tree_3_in_line37",
	"RoomList/Island/Decorations/Trees/Tree_3_in_line32",
	"RoomList/Island/Decorations/Zoo/Tribune",
	"RoomList/Island/Decorations/BillBords/ZooEnterTitle",
	"RoomList/Island/Decorations/Zoo/Carousel",
	"RoomList/Island/Terrain/RailsPath",
	"RoomList/Island/Decorations/Lapms/street_lamp27",
	"RoomList/Island/Decorations/Chairs/chair17",
	"RoomList/Island/Decorations/Chairs/chair18",
	"RoomList/Island/Decorations/Classics",
	"RoomList/Island/Clothes",
	"RoomList/Island/Stars",
	"RoomList/Island/PriceObjects/SportsFootball/SignBuilderFootballLink3",
	"RoomList/Island/PriceObjects/SportsTennis/SignBuilderSportsLink2",
	"RoomList/Island/PriceObjects/SportsBasketball/SignBuilderSportsLink2",
	"RoomList/Island/PriceObjects/SmartZoologists",
	"RoomList/Island/Decorations/Zoo/Cashbox"
]
onready var _eiffel_path := "RoomList/Island/Decorations/Houses/eiffel_4"

# street alphabet
onready var _car_path := "RoomList/Island/Decorations/Cars/car_classic"
onready var _hide_street_alphabet_list_path := [
	"RoomList/Island/Decorations/Lapms/street_lamp6",
	"RoomList/Island/Decorations/Lapms/street_lamp7",
	"RoomList/Island/Decorations/Trees/Tree_3_in_line34",
	"RoomList/Island/Decorations/Trees/Tree_3_in_line35",
	"RoomList/Island/Decorations/Hospital/Path",
	"RoomList/Island/PriceObjects/SunnyDay/BuildStruct/Path",
	"RoomList/Island/Clothes",
	"RoomList/Island/Stars",
	"RoomList/Island/PriceObjects/SportsFootball/SignBuilderFootballLink3",
	"RoomList/Island/PriceObjects/SportsTennis/SignBuilderSportsLink2",
	"RoomList/Island/PriceObjects/SportsBasketball/SignBuilderSportsLink2",
	"RoomList/Island/PriceObjects/SportsFootball/SignBuilderFootballLink",
	"RoomList/Island/PriceObjects/SportsTennis/SignBuilderSportsLink",
	"RoomList/Island/PriceObjects/SportsBasketball/SignBuilderSportsLink"
]

# kitchen fish
onready var _hide_kitchen_fish_list_path := [
	"RoomList/Island/Decorations/KitchenFish",
]

# kitchen chicken
onready var _hide_kitchen_chicken_list_path := [
	"RoomList/Island/Decorations/KitchenFish",
	"RoomList/Island/Decorations/KitchenChicken/Chicken",
	"RoomList/Island/Decorations/KitchenChicken/Chicken2"
]

# hospital panda
onready var _hide_hospital_list_path := [
	"RoomList/Island/Decorations/Hospital/Path",
	"RoomList/Island/Decorations/Hospital/PandaOnGurneyDecor"
]

func _ready_prev() -> void : # override
	_ui_toch_controller.set_book_visible(true)
	_ui_toch_controller.connect("press_book", self, "_Ui_Toch_press_book")
	call_deferred("_connet_signal_clothes")
	if Singletones.get_Global().is_only_world_sorting:
		call_deferred("_remove_enemy_teleport")

func _ready_post() -> void : # override
	._ready_post()
	call_deferred("_check_actived_trigger_sorting")

func _start_post() -> void : # override
	._start_post()
	return

func _play_world_music() -> void : # override
	
	if not current_name_game == "DressCollect":
		Singletones.get_MusicManager().stop()
		yield(get_tree().create_timer(1.0), "timeout")
		Singletones.get_MusicManager().play(Singletones.get_MusicManager().PARIS_THEME)

func _connet_signal_clothes() -> void :
	var closthes := get_node(_clothes_path)
	for cloth in closthes.get_children():
		cloth.connect("push_cloth", self, "_ClothWorld_push_cloth")

func _check_actived_trigger_sorting() -> void :
	var state_scales : GameScalesItems = Singletones.get_GameSaveCloud().game_state.scales_items
	var scales_items := get_node(_scales_items_path)
	var count_items := scales_items.get_child_count() - state_scales.scales_items_list.size()
	
	if not Singletones.get_Global().is_restart_scales_items_level:
		for i in scales_items.get_child_count():
			var item_scale = scales_items.get_child(i)
			var item_name : String = ScalesItemsConst.get_name_item(item_scale.item)
			if state_scales.has_scales_item(item_name):
				item_scale.queue_free()
	else:
		if count_items > 0:
			for i in scales_items.get_child_count():
				var item_scale = scales_items.get_child(i)
				var item_name : String = ScalesItemsConst.get_name_item(item_scale.item)
				if state_scales.has_scales_item(item_name):
					item_scale.queue_free()
		else:
			state_scales.scales_items_list = []
			count_items = scales_items.get_child_count()
	
	if count_items < 8:
		var enemy_scales_sorting := get_node(_enemy_scales_sorting_path)
		enemy_scales_sorting.disable_trigger()

func _remove_enemy_teleport() -> void :
	_enemy_teleport.queue_free()

func _animation_first_game() -> void : # override
	yield(get_tree(), "idle_frame")
	if not is_instance_valid(self) or is_queued_for_deletion() : return
	yield(get_tree(), "idle_frame")
	if not is_instance_valid(self) or is_queued_for_deletion() : return
	yield(get_tree(), "idle_frame")
	if not is_instance_valid(self) or is_queued_for_deletion() : return
	emit_signal("finished_animation_first_game")

func _set_levels_path() -> void : # override
	_levels_path = {
		"SportsFootball" : "res://content/houses/sports_football/sports_football.tscn",
		"SportsTennis" : "res://content/houses/sports_tennis/sports_tennis.tscn",
		"SportsBasketball" : "res://content/houses/sports_basketball/sports_basketball.tscn",
		"ZooSortingHeron" : "res://content/houses/zoo_sorting/zoo_sorting.tscn",
		"TrainSorting" : "res://content/houses/train_sorting/train_sorting.tscn",
		"DressCollect" : "res://content/houses/dress_collect/dress_collect.tscn",
		"ScalesSorting" : "res://content/houses/scales_sorting/scales_sorting.tscn",
		"ClassicsGame" : "res://content/houses/classics_game/classics_game.tscn",
		"CraneAlphabet" : "res://content/houses/crane_alphabet/crane_alphabet.tscn",
		"StreetAlphabet" : "res://content/houses/street_alphabet/street_alphabet.tscn",
		"KitchenFish" : "res://content/houses/kitchen_fish/kitchen_fish.tscn",
		"KitchenChicken" : "res://content/houses/kitchen_chicken/kitchen_chicken.tscn",
		"HospitalPanda" : "res://content/houses/hospital_panda/hospital_panda.tscn"
	}

func _set_levels_pos() -> void : # override
	_levels_pos = {
		"SportsFootball" : $RoomList/Island/PosLevels/SportsFootball,
		"SportsTennis" : $RoomList/Island/PosLevels/SportsTennis,
		"SportsBasketball" : $RoomList/Island/PosLevels/SportsBasketball,
		"ZooSortingHeron" : $RoomList/Island/PosLevels/ZooSorting,
		"TrainSorting" : $RoomList/Island/PosLevels/TrainSorting,
		"DressCollect" : $RoomList/Island/PosLevels/DressCollect,
		"ScalesSorting" : $RoomList/Island/PosLevels/ScalesSorting,
		"ClassicsGame" : $RoomList/Island/PosLevels/ClassicsGame,
		"CraneAlphabet" : $RoomList/Island/PosLevels/CraneAlphabet,
		"StreetAlphabet" : $RoomList/Island/PosLevels/StreetAlphabet,
		"KitchenFish" : $RoomList/Island/PosLevels/KitchenFish,
		"KitchenChicken" : $RoomList/Island/PosLevels/KitchenChicken,
		"HospitalPanda" : $RoomList/Island/PosLevels/HospitalPanda
	}

func _go_to_player_prev(_game) -> void : # override
	var animation_train := get_node(_animation_train_path)
	animation_train.play("play")
	_price_objects.global_transform.origin.y += 20.0
	_enemy.global_transform.origin.y += 20.0

func _go_to_player_post(game) -> void : # override
	_ui_toch_controller.get_book().show()
	._go_to_player_post(game)

func _go_to_game_prev(_game: String) -> void : # override
	var animation_train := get_node(_animation_train_path)
	animation_train.stop()
	_price_objects.global_transform.origin.y -= 20.0
	_enemy.global_transform.origin.y -= 20.0

func _ClothWorld_push_cloth(type_cloth: int, cloth: Spatial) -> void :
	Logger.log_i(self, "add cloth to inventory  ", type_cloth)
	Singletones.get_GameSaveCloud().game_state.dress.push_cloth_to_inventory(ClothConst.get_name_cloth(type_cloth))
	_ui_toch_controller.play_animation_add_cloth(cloth.sprite_texture)

func _on_EnemySportsFootball_tap_on_enemy(game):
	_load_level(game)
	go_to_game(game, true)
	player_camera.current = true
	player.visible = true
	_ui_toch_controller.get_ui().show()
	_ui_toch_controller.get_menu().hide()
	_ui_toch_controller.get_book().hide()
	_to_custom_render(150)
	Singletones.get_MusicManager().play(Singletones.get_MusicManager().SHAPE_RUNNING)


func _on_EnemySportsTennis_tap_on_enemy(game):
	_load_level(game)
	go_to_game(game, true)
	player_camera.current = true
	player.visible = true
	_ui_toch_controller.get_menu().hide()
	_ui_toch_controller.get_book().hide()
	_to_custom_render(150)
	Singletones.get_MusicManager().play(Singletones.get_MusicManager().SHAPE_RUNNING)


func _on_EnemySportsBasketball_tap_on_enemy(game):
	_load_level(game)
	go_to_game(game, true)
	player_camera.current = true
	player.visible = true
	_ui_toch_controller.get_ui().show()
	_ui_toch_controller.get_menu().hide()
	_ui_toch_controller.get_book().hide()
	_to_custom_render(150)
	_direction_light.visible = false
	Singletones.get_MusicManager().play(Singletones.get_MusicManager().SHAPE_RUNNING)
	
func _on_EnemyTeleport_tap_on_enemy(game):
	if not is_instance_valid(self) or is_queued_for_deletion() : return
	emit_signal("change_world", game as int)

func _on_EnemyZooSortingHeron_tap_on_enemy(game):
	_load_level(game)
	var game_node = _level_list.get_node_or_null(game)
	if not game_node :
		return
	game_node.connect("tree_exited", self, "_ZooSorting_tree_exited")
	var pond := get_node(_pond)
	var paddock := get_node(_paddock)
	var aviary_ground := get_node(_aviary_ground)
	var carousel := get_node(_carousel)
	game_node.sets_animal_zones_decor(
		aviary_ground,
		paddock,
		pond,
		carousel
	)
	_trans_aviary_ground = aviary_ground.global_transform
	_trans_paddock = paddock.global_transform
	_trans_pond = pond.global_transform
	_trans_carousel = carousel.global_transform
	carousel.global_transform.origin.y -= 20.0
	for path in _hide_zoo_list:
		var obj := get_node(path)
		obj.visible = false
		obj.global_transform.origin.y -= 20.0
	go_to_game(game, true)
	player_camera.current = true
	player.visible = true
	_to_world_render()
	_ui_toch_controller.get_ui().show()
	_ui_toch_controller.get_menu().hide()
	_ui_toch_controller.get_book().hide()
	Singletones.get_MusicManager().play(Singletones.get_MusicManager().ZOO)


func _ZooSorting_tree_exited() -> void :
	for path in _hide_zoo_list:
		var obj := get_node(path)
		obj.visible = true
		obj.global_transform.origin.y += 20.0
	
	var pond := get_node(_pond)
	var paddock := get_node(_paddock)
	var aviary_ground := get_node(_aviary_ground)
	var carousel := get_node(_carousel)
	aviary_ground.global_transform = _trans_aviary_ground
	paddock.global_transform = _trans_paddock
	pond.global_transform = _trans_pond
	carousel.global_transform = _trans_carousel


func _on_EnemyTrainSorting_tap_on_enemy(game):
	_load_level(game)
	var train := get_node(_train_path)
	train.visible = false
	train.global_transform.origin.y -= 20.0
	var waiters_train := get_node(_waiters_train_path)
	waiters_train.visible = false
	waiters_train.global_transform.origin.y -= 20.0
	var game_node = _level_list.get_node_or_null(game)
	if not game_node :
		return
	
	game_node.connect("tree_exited", self, "_TrainSorting_tree_exited")
	go_to_game(game)
	_to_world_render()
	Singletones.get_MusicManager().play(Singletones.get_MusicManager().ALPHABET_BEACH)

func _TrainSorting_tree_exited() -> void :
	var train := get_node(_train_path)
	train.visible = true
	train.global_transform.origin.y += 20.0
	var waiters_train := get_node(_waiters_train_path)
	waiters_train.visible = true
	waiters_train.global_transform.origin.y += 20.0


func _Ui_Toch_press_book():
	var game = "DressCollect"
	_load_level(game)
	var game_node = _level_list.get_node_or_null(game)
	if not game_node :
		return
	
	game_node.connect("prev_close", self, "_DressBook_prev_close")
	game_node.page = _page_book
	var camera := get_viewport().get_camera()
	var trans : Transform = camera.global_transform
	game_node.global_transform = trans
	go_to_game(game)
	_to_world_render()

func _DressBook_prev_close(page: int) -> void :
	_page_book = page


func _on_EnemyScalesSorting_tap_on_enemy(game):
	_load_level(game)
	var enemy_scales_sorting := get_node(_enemy_scales_sorting_path)
	enemy_scales_sorting.global_transform.origin.y -= 20.0
	var scale_decors := get_node(_scale_decors_path)
	scale_decors.stop_animation()
	var game_node = _level_list.get_node_or_null(game)
	if not game_node :
		return
	var scales_item := get_node(_scales_items_path)
	game_node.items_world_node = scales_item
	game_node.set_tutorial(scales_item.get_child_count() >= 24)
	game_node.connect("tree_exited", self, "_ScalesSorting_tree_exited")
	scales_item.visible = false
	go_to_game(game, true)
	_to_world_render()
	Singletones.get_MusicManager().play(Singletones.get_MusicManager().QUIZ_FLOWER)

func _ScalesSorting_tree_exited() -> void :
	var scales_item := get_node(_scales_items_path)
	scales_item.visible = true
	var enemy_scales_sorting := get_node(_enemy_scales_sorting_path)
	if scales_item.get_child_count() < 8:
		enemy_scales_sorting.disable_trigger()
	enemy_scales_sorting.global_transform.origin.y += 20.0
	var scale_decors := get_node(_scale_decors_path)
	scale_decors.play_animation()


func _on_EnemyClassicsGame_tap_on_enemy(game):
	_load_level(game)
	var game_node = _level_list.get_node_or_null(game)
	if not game_node :
		return
	game_node.ui_toch_controller = _ui_toch_controller
	game_node.connect("tree_exited", self, "_EnemyClassicsGame_tree_exited")
	for path in _hide_classics_list_path:
		var obj := get_node(path)
		obj.visible = false
		obj.global_transform.origin.y -= 20.0
	var eiffel := get_node(_eiffel_path)
	eiffel.global_transform.origin.x += 11.0
	go_to_game(game)
	player_camera.current = true
	player.visible = true
	_ui_toch_controller.get_ui().show()
	_ui_toch_controller.get_menu().hide()
	_ui_toch_controller.get_book().hide()
	_to_world_render()
	Singletones.get_MusicManager().play(Singletones.get_MusicManager().SHAPE_RUNNING)

func _EnemyClassicsGame_tree_exited() -> void :
	for path in _hide_classics_list_path:
		var obj := get_node(path)
		obj.visible = true
		obj.global_transform.origin.y += 20.0
	var eiffel := get_node(_eiffel_path)
	eiffel.global_transform.origin.x -= 11.0


func _on_EnemyCraneAlphabet_tap_on_enemy(game):
	_load_level(game)
	go_to_game(game, true)
	_ui_toch_controller.get_menu().hide()
	_ui_toch_controller.get_book().hide()
	_ui_toch_controller.show_hints_wasd()
	_ui_toch_controller.hide_stick_right()
	Singletones.get_Global().player_character.freez = true
	Singletones.get_Global().player_character.enabled = false
	_to_custom_render(120)
	Singletones.get_MusicManager().play(Singletones.get_MusicManager().ALPHABET_BEACH)




func _on_EnemyStreetAlphabet_tap_on_enemy(game):
	_load_level(game)
	var game_node = _level_list.get_node_or_null(game)
	if not game_node :
		return
	
	game_node.connect("tree_exited", self, "_EnemyStreetAlphabet_tree_exited")
	var car := get_node(_car_path)
	game_node.set_car(car)
	for path in _hide_street_alphabet_list_path:
		var obj := get_node(path)
		obj.visible = false
		obj.global_transform.origin.y -= 20.0
	go_to_game(game)
	_to_world_render()
	Singletones.get_MusicManager().play(Singletones.get_MusicManager().CAR_NIGHT_THEME)

func _EnemyStreetAlphabet_tree_exited() -> void :
	for path in _hide_street_alphabet_list_path:
		var obj := get_node(path)
		obj.visible = true
		obj.global_transform.origin.y += 20.0


func _on_EnemyKitchenFish_tap_on_enemy(game):
	_load_level(game)
	var game_node = _level_list.get_node_or_null(game)
	if not game_node :
		return
	
	game_node.connect("tree_exited", self, "_EnemyKitchenFish_tree_exited")
	for path in _hide_kitchen_fish_list_path:
		var obj := get_node(path)
		obj.visible = false
		obj.global_transform.origin.y -= 20.0
	go_to_game(game, true)
	_ui_toch_controller.get_menu().hide()
	_ui_toch_controller.get_book().hide()
	_ui_toch_controller.show_hints_wasd()
	_ui_toch_controller.hide_stick_right()
	_to_custom_render(120)

func _EnemyKitchenFish_tree_exited() -> void :
	for path in _hide_kitchen_fish_list_path:
		var obj := get_node_or_null(path)
		if obj :
			obj.visible = true
			obj.global_transform.origin.y += 20.0


func _on_EnemyKitchenChicken_tap_on_enemy(game):
	_load_level(game)
	var game_node = _level_list.get_node_or_null(game)
	if not game_node :
		return
	
	game_node.connect("tree_exited", self, "_EnemyKitchenChicken_tree_exited")
	for path in _hide_kitchen_chicken_list_path:
		var obj := get_node_or_null(path)
		if obj :
			obj.visible = false
			obj.global_transform.origin.y -= 20.0
	go_to_game(game, true)
	Singletones.get_Global().player_character.freez = true
	Singletones.get_Global().player_character.enabled = false
	_ui_toch_controller.get_menu().hide()
	_ui_toch_controller.get_book().hide()
	_ui_toch_controller.show_hints_wasd()
	_ui_toch_controller.hide_stick_right()
	_to_world_render()

func _EnemyKitchenChicken_tree_exited() -> void :
	for path in _hide_kitchen_chicken_list_path:
		var obj := get_node(path)
		obj.visible = true
		obj.global_transform.origin.y += 20.0


func _on_EnemyHospitalPanda_tap_on_enemy(game):
	_load_level(game)
	var game_node = _level_list.get_node(game)
	game_node.connect("tree_exited", self, "_EnemyHospitalPanda_tree_exited")
	for path in _hide_hospital_list_path:
		var obj := get_node(path)
		obj.visible = false
		obj.global_transform.origin.y -= 20.0
	go_to_game(game)
	_to_world_render()

func _EnemyHospitalPanda_tree_exited() -> void :
	for path in _hide_hospital_list_path:
		var obj := get_node(path)
		obj.visible = true
		obj.global_transform.origin.y += 20.0


func _on_EnemyCarGames_tap_on_enemy(game):
	Singletones.get_GlobalGame().is_demo_cargames = false
	_play_car_games()

func _on_EnemyBuyGame_play_demo_cargames() -> void:
	Singletones.get_GlobalGame().is_demo_cargames = true
	_play_car_games()

func _play_car_games():
	Logger.log_i(self, " ENTER ENEMY CAR GAMES")
	Singletones.get_MusicManager().stop()
	
	yield(get_tree().create_timer(0.2), "timeout")
	Singletones.get_Global().last_pos = Singletones.get_Global().get_closet_end_level_position()
	Singletones.get_GameSaveCloud().game_state.player_position = Singletones.get_Global().last_pos
	player.global_transform.origin = Singletones.get_Global().last_pos
	
	#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MouseCursor.visible_cursor = true
	AudioServer.set_bus_volume_db(5, 6.0) # Effects
	
	Singletones.get_GlobalGame().change_game(Singletones.get_GlobalGame().GAMES.CARGAMES)
	
	var screen_cargames_in = ResourceLoader.load(SCREEN_CARGAMES_IN_PKG_PATH, "", GlobalSetupsConsts.NO_CACHED).instance()
	screen_cargames_in.connect("animation_screen_cargames_finished", self, "_Screen_animation_screen_cargames_finished")
	add_child(screen_cargames_in)

func _Screen_animation_screen_cargames_finished() -> void :
	get_tree().change_scene("res://content/ui/menus/menus.tscn")
