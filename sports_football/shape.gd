extends Control

onready var _shape := $TextureRectShape
onready var _animation := $AnimationPlayer

func show_shape() -> void :
	visible = true
	_animation.play("show")

func hide_shape() -> void :
	visible = false

func set_texture(tex: Texture) -> void :
	_shape.texture = tex

func set_texture_and_show(tex: Texture) -> void :
	set_texture(tex)
	show_shape()
