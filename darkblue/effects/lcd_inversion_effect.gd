@tool
extends ColorRect

@export_range(0.0, 1.0) var inversion: float = 0.0:
	set(v):
		inversion = v
		_update_shader()

@export_range(0.0, 1.0) var tilt_strength: float = 0.5:
	set(v):
		tilt_strength = v
		_update_shader()

@export_range(0.0, 1.0) var tilt_center: float = 0.5:
	set(v):
		tilt_center = v
		_update_shader()

@export var color_dark: Color = Color(0.75, 0.78, 0.65, 1.0):
	set(v):
		color_dark = v
		_update_shader()

@export var color_mid: Color = Color(0.45, 0.50, 0.35, 1.0):
	set(v):
		color_mid = v
		_update_shader()

@export var color_light: Color = Color(0.15, 0.20, 0.12, 1.0):
	set(v):
		color_light = v
		_update_shader()

func _ready():
	_update_shader()

func _update_shader():
	if not material: return
	material.set_shader_parameter("inversion", inversion)
	material.set_shader_parameter("tilt_strength", tilt_strength)
	material.set_shader_parameter("tilt_center", tilt_center)
	material.set_shader_parameter("color_dark", color_dark)
	material.set_shader_parameter("color_mid", color_mid)
	material.set_shader_parameter("color_light", color_light)
