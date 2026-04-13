extends Node

const CAT := 1
const DOG := 2
const CRAZY := 3
const HERON := 4
const PANDA := 5
const PIG := 6
const RABBIT := 7

onready var _characters_list := [
	CAT,
	DOG,
	CRAZY,
	HERON,
	PANDA,
	PIG,
	RABBIT
]

onready var _scale_sprites := {
	CAT : 1.3,
	DOG : 1.0,
	CRAZY : 1.7,
	HERON : 1.0,
	PANDA : 1.1,
	PIG : 1.0,
	RABBIT : 1.0
}

onready var _characters_icons := {
	CAT : preload("res://resources/character_icons/cat_rocket.png"),
	DOG : preload("res://resources/character_icons/dog.png"),
	CRAZY : preload("res://resources/character_icons/hairy_ball_rocket.png"),
	HERON : preload("res://resources/character_icons/heron_rocket.png"),
	PANDA : preload("res://resources/character_icons/panda_rocket.png"),
	PIG : preload("res://resources/character_icons/Pig.png"),
	RABBIT : preload("res://resources/character_icons/rabbit_2.png")
}

onready var _characters_models_dict := {
	CAT : [
		"res://resources/models/character_v2/full/kitty/kitty_player.tscn"
	],
	DOG : [
		"res://resources/models/character_v2/full/dog/dog_player.tscn"
	],
	CRAZY : [
		"res://resources/models/character_v2/full/hair_ball/hair_ball_player.tscn"
	],
	HERON : [
		"res://resources/models/character_v2/full/heron/heron_player.tscn"
	],
	PANDA : [
		"res://resources/models/character_v2/full/panda/panda_player.tscn"
	],
	PIG : [
		"res://resources/models/character_v2/full/pig/pig_player.tscn"
	],
	RABBIT : [
		"res://resources/models/character_v2/full/rabbit/rabbit_player.tscn"
	]
}

onready var _remap_player_character := {
	"res://resources/models/character_v2/full/kitty/kitty_player.tscn" : CAT,
	"res://resources/models/character_v2/full/dog/dog_player.tscn" : DOG,
	"res://resources/models/character_v2/full/hair_ball/hair_ball_player.tscn" : CRAZY,
	"res://resources/models/character_v2/full/heron/heron_player.tscn" : HERON,
	"res://resources/models/character_v2/full/panda/panda_player.tscn" : PANDA,
	"res://resources/models/character_v2/full/pig/pig_player.tscn" : PIG,
	"res://resources/models/character_v2/full/rabbit/rabbit_player.tscn" : RABBIT
}

func get_characters_list() -> Array :
	return _characters_list.duplicate()

func get_characters_icon(type_character: int) -> Texture :
	return _characters_icons[type_character]

func get_characters_models_dict() -> Dictionary :
	return _characters_models_dict.duplicate()

func get_character_model_path(idx_char: int) -> Array :
	return _characters_models_dict.get(idx_char, DOG)

func get_characters_models_list_one_type(type_character: int) -> Array :
	return _characters_models_dict[type_character].duplicate()

func get_character_from_path_player(path: String) -> int :
	if _remap_player_character.has(path):
		return _remap_player_character[path]
	else:
		return CAT

func get_scale_sprite(type_character: int) -> float :
	return _scale_sprites[type_character]
