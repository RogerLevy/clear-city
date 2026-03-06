class_name StarfieldParticles
extends Node2D

@export var star_count: int = 500
@export var star_bias: float = 1.6
@export var scroll_speed: float = 1.0
@export var star_texture: Texture2D = null

var _stars: PackedFloat32Array  # stride 3: x, y, speed

func _ready():
    _init_stars.call_deferred()

func _init_stars():
    _stars.resize(star_count * 3)
    var vp = get_viewport().get_visible_rect().size
    for i in star_count:
        var idx = i * 3
        _stars[idx] = randf() * vp.x
        _stars[idx + 1] = randf() * vp.y
        _stars[idx + 2] = pow(randf(), star_bias) * 0.75 + 0.05

func _process(delta: float):
    if _stars.is_empty(): return
    var vp_w = get_viewport().get_visible_rect().size.x
    for i in star_count:
        var idx = i * 3
        _stars[idx] -= _stars[idx + 2] * scroll_speed * 60.0 * delta
        if _stars[idx] < 0.0:
            _stars[idx] += vp_w
    queue_redraw()

func _draw():
    if star_texture:
        _draw_textured()
    else:
        _draw_rects()

func _draw_rects():
    if _stars.is_empty(): return
    for i in star_count:
        var idx = i * 3
        var spd = _stars[idx + 2]
        draw_rect(Rect2(_stars[idx], _stars[idx + 1], 2, 2), Color.WHITE)

func _draw_textured():
    if _stars.is_empty(): return
    for i in star_count:
        var idx = i * 3
        var spd = _stars[idx + 2]
        draw_texture(star_texture, Vector2(_stars[idx], _stars[idx + 1]), Color.WHITE)

func set_scroll_speed(speed: float):
    scroll_speed = speed

func set_star_bias(bias: float):
    star_bias = bias
    _init_stars()
