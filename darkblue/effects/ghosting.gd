extends Node2D

## Ghost trail intensity - higher = longer trails
@export_range(0.0, 0.99) var ghost_amount: float = 0.7:
	set(v):
		ghost_amount = v
		if _dim_rect:
			_dim_rect.color.a = 1.0 - v

var _accumulator: SubViewport
var _dim_rect: ColorRect
var _game_copy: TextureRect
var _output: Sprite2D
var _game_viewport: SubViewport

func _ready() -> void:
	_setup.call_deferred()

func _setup() -> void:
	# Find the game's SubViewport using unique name
	var pv = get_tree().current_scene.get_node_or_null("%PixelatedViewport")
	if pv:
		_game_viewport = pv.get_node_or_null("SubViewport")

	if _game_viewport == null:
		push_warning("GhostEffect: Could not find %PixelatedViewport/SubViewport")
		return

	var size := _game_viewport.size

	# Create accumulator viewport - NEVER clears, content persists
	_accumulator = SubViewport.new()
	_accumulator.size = size
	_accumulator.transparent_bg = true
	_accumulator.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	_accumulator.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_accumulator)

	# Dim rect - fades accumulated content each frame
	_dim_rect = ColorRect.new()
	_dim_rect.color = Color(0, 0, 0, 1.0 - ghost_amount)
	_dim_rect.size = Vector2(size)
	_accumulator.add_child(_dim_rect)

	# Game copy - draws current game content on top
	_game_copy = TextureRect.new()
	_game_copy.texture = _game_viewport.get_texture()
	_game_copy.size = Vector2(size)
	_game_copy.stretch_mode = TextureRect.STRETCH_SCALE
	_accumulator.add_child(_game_copy)

	# Output sprite - displays the accumulator
	_output = Sprite2D.new()
	_output.centered = false
	_output.texture = _accumulator.get_texture()
	_output.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_output.z_index = -1
	add_child(_output)
