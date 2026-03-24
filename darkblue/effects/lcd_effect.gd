extends Node2D

## How fast pixels fade in - higher = faster
@export_range(0.01, 1.0) var fade_in_speed: float = 0.2
## How fast pixels fade out - higher = faster
@export_range(0.01, 1.0) var fade_out_speed: float = 0.1
## Alpha multiplier for the 1-pixel gap lines (0 = fully transparent)
@export_range(0.0, 1.0) var grille_gap_alpha: float = 0.5

var _game_viewport: SubViewport
var _pixelated_viewport: Node
var _cell_size: float

var _composite: SubViewport
var _prev_copy: SubViewport
var _copy_sprite: Sprite2D
var _shader_rect: ColorRect
var _mat: ShaderMaterial
var _output: Sprite2D
var _grille_mat: ShaderMaterial
var _initialized := false

func _ready() -> void:
    visibility_changed.connect(_on_visibility_changed)
    if visible:
        _setup.call_deferred()

func _exit_tree() -> void:
    if _pixelated_viewport:
        _pixelated_viewport.visible = true
    if RenderingServer.frame_post_draw.is_connected(_on_first_frame):
        RenderingServer.frame_post_draw.disconnect(_on_first_frame)

func _on_visibility_changed() -> void:
    if visible and not _initialized:
        _setup.call_deferred()
    if _pixelated_viewport:
        _pixelated_viewport.visible = not visible

func _setup() -> void:
    if _initialized:
        return
    _initialized = true

    var pv = get_tree().current_scene.get_node_or_null("%PixelatedViewport")
    if pv:
        _game_viewport = pv.get_node_or_null("SubViewport")

    if _game_viewport == null:
        push_warning("LCDEffect: Could not find %PixelatedViewport/SubViewport")
        return

    _pixelated_viewport = pv
    pv.visible = false

    var size := _game_viewport.size

    _prev_copy = SubViewport.new()
    _prev_copy.size = size
    _prev_copy.transparent_bg = true
    _prev_copy.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
    _prev_copy.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(_prev_copy)

    _copy_sprite = Sprite2D.new()
    _copy_sprite.centered = false
    _copy_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _copy_sprite.material = ShaderMaterial.new()
    (_copy_sprite.material as ShaderMaterial).shader = load("res://darkblue/effects/lcd_copy.gdshader") as Shader
    _prev_copy.add_child(_copy_sprite)

    _composite = SubViewport.new()
    _composite.size = size
    _composite.transparent_bg = true
    _composite.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
    _composite.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(_composite)

    _mat = ShaderMaterial.new()
    _mat.shader = load("res://darkblue/effects/lcd_effect.gdshader") as Shader
    _mat.set_shader_parameter("game_frame", _game_viewport.get_texture())
    _mat.set_shader_parameter("prev_output", _prev_copy.get_texture())
    _mat.set_shader_parameter("fade_in_speed", fade_in_speed)
    _mat.set_shader_parameter("fade_out_speed", fade_out_speed)

    _shader_rect = ColorRect.new()
    _shader_rect.size = Vector2(size)
    _shader_rect.material = _mat
    _composite.add_child(_shader_rect)

    _grille_mat = ShaderMaterial.new()
    _grille_mat.shader = load("res://darkblue/effects/pixel_grille.gdshader") as Shader
    _grille_mat.set_shader_parameter("gap_alpha", grille_gap_alpha)
    get_viewport().size_changed.connect(_update_grille_cell_size)
    _update_grille_cell_size()

    _output = Sprite2D.new()
    _output.centered = false
    _output.texture = _composite.get_texture()
    _output.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _output.material = _grille_mat
    add_child(_output)

    RenderingServer.frame_post_draw.connect(_on_first_frame, CONNECT_ONE_SHOT)

func _update_grille_cell_size() -> void:
    if _grille_mat and _game_viewport:
        var win := DisplayServer.window_get_size()
        var scale_x := float(win.x) / _game_viewport.size.x
        var scale_y := float(win.y) / _game_viewport.size.y
        _cell_size = round(min(scale_x, scale_y))
        _grille_mat.set_shader_parameter("cell_size", max(_cell_size, 1.0))

func _on_first_frame() -> void:
    _copy_sprite.texture = _composite.get_texture()

func _process(_delta: float) -> void:
    if _mat:
        _mat.set_shader_parameter("fade_in_speed", fade_in_speed)
        _mat.set_shader_parameter("fade_out_speed", fade_out_speed)
    if _grille_mat:
        _grille_mat.set_shader_parameter("gap_alpha", grille_gap_alpha)
