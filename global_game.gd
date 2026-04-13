extends "res://globals/singletones_v2/interfaces/IGlobalGame.gd"

#signal change_viewport_scale(scale_viewport, size_viewport)

const GlobalSetups := preload("res://globals/global_setups.gd")
const PlatformsInfo := preload("res://content/platforms_info/platforms_info.gd")

var _scale_viewport := 1.0

#var is_has_multiplayer := true
#var is_demo_cargames := false
#
#enum GAMES {
#	PARK,
#	CARGAMES
#}

var _resol_world := {
	GAMES.PARK : Vector2(1920, 1080),
	GAMES.CARGAMES : Vector2(1080, 1080)
}

#var current_game : int = GAMES.PARK
#
#var need_show_screen_cargames_out := false

var _timer_update := Timer.new()

func _ready():
	if GlobalSetups.IS_STANDALONE:
		current_game = GAMES.CARGAMES
	else:
		current_game = GAMES.PARK

	add_child(_timer_update)
	_timer_update.one_shot = true
	_timer_update.connect("timeout", self, "_resized", [], CONNECT_DEFERRED)
	_timer_update.wait_time = 1.0
	_on_Viewport_resized()
	get_viewport().connect("size_changed", self, "_on_Viewport_resized")

	_setup_has_multiplayer()

func change_game(game: int) -> void :
	if not current_game == game:
		need_show_screen_cargames_out = true
	
	current_game = game
	_on_Viewport_resized()

func get_scale_viewport() -> float :
	return _scale_viewport

func _setup_has_multiplayer() -> void :
	is_has_multiplayer = GlobalSetups.ENABLE_MULTIPLAYER and GlobalSetups.ENABLE_MULTIPLAYER_NAKAMA
	
#	match OS.get_name():
#		PlatformsInfo.NAME_OS_IOS, PlatformsInfo.NAME_OS_OSX:
#			is_has_multiplayer = GlobalSetups.ENABLE_MULTIPLAYER and GlobalSetups.ENABLE_MULTIPLAYER_IOS
#		PlatformsInfo.NAME_OS_ANDROID:
#			is_has_multiplayer = GlobalSetups.ENABLE_MULTIPLAYER and GlobalSetups.ENABLE_MULTIPLAYER_ANDROID


func force_update() -> void :
	_on_Viewport_resized()

var _resized_start := false
func _on_Viewport_resized():
	if _resized_start :
		return
	_resized_start = true
	_timer_update.start()

func _resized() -> void :
	var model_name :=  OS.get_model_name()
	var lowp := false
	if model_name.find_last("iPad2") > 0 :
		Engine.target_fps = 30
		lowp = true
	elif model_name.find_last("iPad1") > 0 :
		Engine.target_fps = 30
		lowp = true
	elif model_name.find_last("iPhone9") > 0 :
		Engine.target_fps = 30
		lowp = true
	elif model_name.find_last("iPhone8") > 0 :
		Engine.target_fps = 30
		lowp = true
	elif model_name in ["iPhone9,3", "iPhone9,2", "iPhone9,1", "iPhone9", "iPad2,1", "iPad2,2", "iPad2,3"] :
		Engine.target_fps = 30
		lowp = true
	
	
	
	var viewport_size := get_viewport().size
	var W : float = viewport_size.x
	var H : float = viewport_size.y
	var wh_max := max(W, H)
	var wh_min := min(W, H)
	if wh_max == 0 or wh_min == 0 :
		push_warning("Resulution is zero!")
		_resized_start = false
		return
	var f := abs(wh_max / wh_min)
	
	var stretch_mode := SceneTree.STRETCH_MODE_VIEWPORT
	
	if OS.get_name() in PlatformsInfo.get_names_os_mobile():
		stretch_mode = SceneTree.STRETCH_MODE_VIEWPORT
		if f < 1.7 and current_game == GAMES.CARGAMES:
			_scale_viewport = 0.5
		else:
			_scale_viewport = 0.55 if lowp else 1.0
	else:
		if not GlobalSetups.IS_RATIO_MOBILE_ON_PC:
			stretch_mode = SceneTree.STRETCH_MODE_2D
			_scale_viewport = 0.6 if lowp else 0.7
		else:
			stretch_mode = SceneTree.STRETCH_MODE_2D
			if f < 1.7 and current_game == GAMES.CARGAMES:
				_scale_viewport = 0.5
			else:
				_scale_viewport = 0.6 if lowp else 1.0
	
	Logger.log_i(self, "_on_Viewport_resized, viewport_size ", viewport_size)
	
	var resol : Vector2 = _resol_world[current_game]
	get_tree().set_screen_stretch(
		stretch_mode,
		SceneTree.STRETCH_ASPECT_EXPAND,
		Vector2(1280, 720) if lowp else resol,
		_scale_viewport
	)
	
	yield(get_tree(), "idle_frame")
	if not is_instance_valid(self) or is_queued_for_deletion() : return
	yield(get_tree(), "idle_frame")
	if not is_instance_valid(self) or is_queued_for_deletion() : return
	
	Logger.log_i(self, " emit signal change_viewport_scale ", _scale_viewport)
	Logger.log_i(self, " FXAA enable ", get_viewport().fxaa)
	emit_signal("change_viewport_scale", _scale_viewport, get_viewport().size)
	
	
	_resized_start = false
	
	return



func get_current_home_object_price() -> int :
	return 100
