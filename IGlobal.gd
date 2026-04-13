extends Node

# debugs (for release all false) #####################################
const ENABLE_TEST_BUTTONS_SUB := false
const DISABLE_SUBSCRIPTIONS := false
const DISABLE_ADS_CAS := true
const ENABLE_ADS_CAS_FOR_PC := false
const IS_DEBUG := false
######################################################################

enum UIDeviceOrientation {
	UIDeviceOrientationUnknown,
	UIDeviceOrientationPortrait,            # Device oriented vertically, home button on the bottom
	UIDeviceOrientationPortraitUpsideDown,  # Device oriented vertically, home button on the top
	UIDeviceOrientationLandscapeLeft,       # Device oriented horizontally, home button on the right
	UIDeviceOrientationLandscapeRight,      # Device oriented horizontally, home button on the left
	UIDeviceOrientationFaceUp,              # Device oriented flat, face up
	UIDeviceOrientationFaceDown  
}

var character_paked_path := "res://resources/models/character_v2/full/dog/dog_player.tscn"
var player_character: KinematicBody = null
var controller = null
var ui_touch_controller: CanvasLayer = null
var path_system : Node = null
var reset_target: Spatial = null
#var current_character_index := 0
var last_pos := Vector3.ZERO
var quality := 2
var lock_jump := false

var lowp_texture_shrink := false

var count_running_games_in_session := 0
var count_drop_games_in_session := 0

var ortogonal_camera: Camera = null

var is_only_world_sorting := false

var is_restart_scales_items_level := true

var is_tutorial := false
var enable_parent_control := true
var is_force_start := false

var is_day := true

var is_showed_list_players_few_sec := false
var name_network_player_teleport : String = ""
var timer_teleport_fixe
var list_network_players := []

var level_teleport := ""
var level_mp_teleport := ""
var force_teleport_point_next := ""
var teleport_from_home_world := false

var show_screen_sub_in_start := false
var show_screen_sub_in_levels := true

var last_trigger: Node = null

var last_clother := []

var disabled_bots := false

var buffer_data := {
	"home_building": {
		"ui" : "",
		"need" : false
	}
}

var count_show_popup := 0 setget set_count_show_popup
func set_count_show_popup(val: int) -> void :
	if val < 0 :
		Logger.log_e(self, "COUNT SHOW POPUP < 0!!!!")
		val = 0
	count_show_popup = max(val, 0) as int

var is_free_camera := false
var sens_mouse := 0.002

var rate_me_count := 1
const RATE_ME_INTERVAL := 5

const InputEventScreenStickAction := preload("res://content/ui/input_event_screen_stick.gd")

var left_stick := InputEventScreenStickAction.new()
var right_stick := InputEventScreenStickAction.new()

var game_loaded := false
var is_in_game := false

var apple_id_app := "6444585586"

func check_update() -> void :
	pass

func get_enable_subscription_system() -> bool :
	return true

func setup_visible_hints_inside_game() -> void :
	pass

func get_closet_end_level_position() -> Vector3 :
	return Vector3.ZERO

func free_data() -> void :
	pass

func reload_game() -> void :
	pass

func register_notification() -> void :
	pass

func reload_singletone() -> void :
	pass

func paywall() -> void :
	pass

var paused_counted := 0 setget set_paused_counted
func set_paused_counted(_val: int) -> void :
	pass

func reset_player() -> void :
	pass

func move_player_from_to(_from: Spatial, _to: Spatial) -> void :
	pass

func run_player_from_to(_from: Spatial, _to: Spatial) -> void :
	pass

func set_disabled_player_to(_to: Spatial) -> void :
	pass


func on_store() -> void :
	pass

func on_like() -> void :
	pass

func on_more_games() -> void :
	pass


func get_screen_orientation() -> int :
	return OS.screen_orientation


func update_status_force() -> void :
	pass
