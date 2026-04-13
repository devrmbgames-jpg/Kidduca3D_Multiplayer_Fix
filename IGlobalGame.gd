extends Node

signal change_viewport_scale(scale_viewport, size_viewport)

var is_has_multiplayer := true
var is_demo_cargames := false

enum GAMES {
	PARK,
	CARGAMES
}

var current_game : int = GAMES.PARK

var need_show_screen_cargames_out := false
var need_show_popup_more_games := false


func change_game(_game: int) -> void :
	pass

func get_scale_viewport() -> float :
	return 0.0


####################
####################
####################


const SEASON_UNKNOW := -1
const SEASON_NONE := 0
const SEASON_CHRISMAS := 1
const SEASON_HELLOWEEN := 2

const SEASON := {
	["0000-11-15", "0000-12-31"] : SEASON_CHRISMAS,
	#["0000-01-01", "0000-01-15"] : SEASON_CHRISMAS,
	
	["0000-10-01", "0000-11-15"] : SEASON_HELLOWEEN,
}

static func _get_season_type() -> int :
	
	var unix_time := OS.get_unix_time()
	
	
	#unix_time = Time.get_unix_time_from_datetime_string("YYYY-MM-DD")
	#push_warrning("!!! TEST DATE TIME !!!"_
	var year := Time.get_datetime_dict_from_unix_time(unix_time).year as int
	var year_text := str(year)
	var year_next_text := str(year + 1)
	
	for key in SEASON :
		var from := Time.get_unix_time_from_datetime_string(
			key[0].replace("0000", year_text)
		)
		var to := Time.get_unix_time_from_datetime_string(
			key[1].replace("0000", year_text).replace("1111", year_next_text)
		)
		if unix_time >= from and unix_time <= to :
			return SEASON[key]
	
	return SEASON_NONE

var season_current := SEASON_UNKNOW
func get_season_type() -> int :
	if season_current == SEASON_UNKNOW :
		season_current = _get_season_type()
	return season_current


func force_update() -> void :
	return

func get_current_home_object_price() -> int :
	return 0
