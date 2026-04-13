extends Node

signal update_game_state()
signal start_load_game_state()
signal finished_load_game_state()
signal start_save_game_state()
signal finished_save_game_state()

signal connection_cloud_changed()
signal connection_cloud_success()
signal connection_cloud_failed()

const GameState := preload("res://content/game_save_cloud/game_state.gd")

const VERSION_SAVE := 2
const SAVE_NAME := "SAVE_VER_%d_" % VERSION_SAVE

const CONFIG_PATH := "user://config.cfg"
const CFG_SECTION_BASE := "FIRST_RUNNING"

export(float) var time_auto_save := 360.0


#var game_cloud: GameCloudBase = null
var game_state: GameState = GameState.new()

var config: ConfigFile = ConfigFile.new()
var is_loaded_save_game := false
var is_save_data_empty := false
var disabled := false
var id := "NONE"
var id_team := 0


func get_save_name() -> String :
	return ""

func reload_singletone() -> void :
	pass


func connected_cloud() -> void :
	pass


func disconnected_cloud() -> void :
	pass

func is_connected_cloud() -> bool :
	return false


func set_auto_reconnection(_val: bool) -> void :
	pass


func save_cfg() -> void :
	pass


func save_game_state() -> void :
	pass

func load_game_state() -> void :
	pass

func force_load_game_state() -> void :
	pass


##########################################
##########################################

func get_game_state() -> GameState :
	return null


###########################################
###########################################

func config_is_first_run() -> bool :
	return false

func config_accept_first_run() -> void :
	pass

###########################################
###########################################

#WARRNING! RESET ALL PROGRESS IN GAME
func reset_all_progress() -> void :
	pass

