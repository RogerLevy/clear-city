extends Node2D

var _pixelated_viewport: Node

## Base response speed (0 = instant, 1 = frozen)
@export_range(0.0, 0.99) var response_time: float = 0.5:
	set(v):
		response_time = v
		_update_shader_params()

## How much change affects response
@export_range(0.0, 2.0) var change_sensitivity: float = 1.0:
	set(v):
		change_sensitivity = v
		_update_shader_params()

## Asymmetric response ratio
@export_range(0.5, 2.0) var rise_fall_ratio: float = 1.2:
	set(v):
		rise_fall_ratio = v
		_update_shader_params()

var _render_viewport: SubViewport
var _blend_rect: ColorRect
var _output: Sprite2D
var _game_viewport: SubViewport
var _prev_texture: ImageTexture
var _skip := 3

func _ready() -> void:
	_setup.call_deferred()
	visibility_changed.connect(_on_visibility_changed)

func _exit_tree() -> void:
	if _pixelated_viewport:
		_pixelated_viewport.visible = true

func _on_visibility_changed() -> void:
	if _pixelated_viewport:
		_pixelated_viewport.visible = not visible

func _setup() -> void:
	var pv = get_tree().current_scene.get_node_or_null("%PixelatedViewport")
	if pv:
		_game_viewport = pv.get_node_or_null("SubViewport")

	if _game_viewport == null:
		push_warning("LCDResponse: Could not find %PixelatedViewport/SubViewport")
		return

	_pixelated_viewport = pv
	pv.visible = false

	var size := _game_viewport.size

	# SubViewport to render the blended result (so we can capture it)
	_render_viewport = SubViewport.new()
	_render_viewport.size = size
	_render_viewport.transparent_bg = true
	_render_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_render_viewport)

	# ColorRect with LCD response shader inside the viewport
	_blend_rect = ColorRect.new()
	_blend_rect.size = Vector2(size)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://darkblue/effects/lcd_response.gdshader")
	mat.set_shader_parameter("current_frame", _game_viewport.get_texture())
	_blend_rect.material = mat
	_render_viewport.add_child(_blend_rect)

	# Output displays the render viewport
	_output = Sprite2D.new()
	_output.centered = false
	_output.texture = _render_viewport.get_texture()
	_output.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_output)

	_prev_texture = ImageTexture.new()
	_update_shader_params()

func _update_shader_params() -> void:
	if _blend_rect and _blend_rect.material:
		_blend_rect.material.set_shader_parameter("response_time", response_time)
		_blend_rect.material.set_shader_parameter("change_sensitivity", change_sensitivity)
		_blend_rect.material.set_shader_parameter("rise_fall_ratio", rise_fall_ratio)

func _process(_delta: float) -> void:
	if _render_viewport == null:
		return
	if _skip > 0:
		_skip -= 1
		return
	RenderingServer.frame_post_draw.connect(_capture, CONNECT_ONE_SHOT)

func _capture() -> void:
	# Capture our OUTPUT (the blended result) for next frame's "previous"
	var img := _render_viewport.get_texture().get_image()
	if img == null or img.is_empty():
		return

	if _prev_texture.get_image() == null:
		_prev_texture = ImageTexture.create_from_image(img)
	else:
		_prev_texture.update(img)

	_blend_rect.material.set_shader_parameter("prev_frame", _prev_texture)
