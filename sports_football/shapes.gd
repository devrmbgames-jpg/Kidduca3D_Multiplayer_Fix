extends Node

const WORDMAP := preload("res://content/houses/words_photo/wordmap.gd")

const CIRCLE := 1
const RECT := 2
const SQUARE := 3
const TRINGLE := 4
const HEXAGON := 5
const RHOMB := 6
const STAR := 7
const HEART := 8
const PENTA := 9
const OVAL := 10

const _shape_list := [
	CIRCLE,
	RECT,
	SQUARE,
	TRINGLE,
	HEXAGON,
	RHOMB,
	STAR,
	HEART,
	PENTA,
	OVAL
]

const _shape_text := {
	CIRCLE : WORDMAP.W_CIRCLE,
	RECT : WORDMAP.W_RECTANGLE,
	SQUARE : WORDMAP.W_SQUARE,
	TRINGLE : WORDMAP.W_TRIANGLE,
	HEXAGON : WORDMAP.W_HEXAGON,
	RHOMB : WORDMAP.W_RHOMB,
	STAR : WORDMAP.W_STAR,
	HEART : WORDMAP.W_HEART,
	PENTA : WORDMAP.W_PENTAGON,
	OVAL : WORDMAP.W_OVAL
}

onready var _sounds := {
	CIRCLE : $AudioCircle,
	RECT : $AudioRect,
	SQUARE : $AudioSquare,
	TRINGLE : $AudioTringle,
	HEXAGON : $AudioHexagon,
	RHOMB : $AudioRombh,
	STAR : $AudioStar,
	HEART : $AudioHeart,
	PENTA : $AudioPenta,
	OVAL : $AudioOval,
}

const _SHAPES_ICON_PATH := {
	CIRCLE : ("res://resources/word_icons/word_icons/circle.tres"),
	RECT : ("res://resources/word_icons/word_icons/rectangle.tres"),
	SQUARE : ("res://resources/word_icons/word_icons/square.tres"),
	TRINGLE : ("res://resources/word_icons/word_icons/triangle1.tres"),
	HEXAGON : ("res://resources/word_icons/word_icons/hexagon.tres"),
	RHOMB : ("res://resources/word_icons/word_icons/rhomb.tres"),
	STAR : ("res://resources/word_icons/word_icons/star.tres"),
	HEART : ("res://resources/word_icons/word_icons/heart.tres"),
	PENTA : ("res://resources/word_icons/word_icons/pentagon.tres"),
	OVAL : ("res://resources/word_icons/word_icons/oval.tres"),
}

onready var _scale_shapes_sprite := {
	CIRCLE : 0.8,
	RECT : 0.8,
	SQUARE : 0.8,
	TRINGLE : 0.8,
	HEXAGON : 0.8,
	RHOMB : 0.8,
	STAR : 0.8,
	HEART : 0.8,
	PENTA : 0.8,
	OVAL : 0.8,
}

func play_sound(type_shape: int) -> void :
	_sounds[type_shape].play()

static func get_text(type_shape: int) -> String :
	return _shape_text[type_shape]

static func get_shapes_list() -> Array :
	return _shape_list.duplicate()

static func get_shape_icon(type_shape: int) -> Texture :
	var path : String = _SHAPES_ICON_PATH.get(type_shape, WORDMAP.BUG_WORD)
	return ResourceLoader.load(path, "", GlobalSetupsConsts.NO_CACHED) as Texture

func get_scale_shape_sprite(type_shape: int) -> float :
	return _scale_shapes_sprite[type_shape]
