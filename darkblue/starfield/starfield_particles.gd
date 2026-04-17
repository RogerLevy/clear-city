class_name StarfieldParticles
extends Node2D

@export var star_count: int = 500
@export var star_bias: float = 1.6
@export var scroll_speed: float = 1.0
@export var star_texture: Texture2D = null

## Mask texture - stars won't draw where mask has key color
var mask_texture: Texture2D = null
var mask_image: Image = null
var mask_offset: Vector2 = Vector2.ZERO  # Position of mask sprite
var key_color: Color = Color(0,0,0) # Color(0.298, 0.298, 0.498)  # #4c4c7f
var key_threshold: float = 0.15  # Increased for anti-aliased edges

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
        _stars[idx] -= _stars[idx + 2] * scroll_speed * 50.0 * delta
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
        var x = _stars[idx]
        var y = _stars[idx + 1]
        if _is_masked(x, y):
            continue
        draw_rect(Rect2(x, y, 2, 2), Color.WHITE)

func _draw_textured():
    if _stars.is_empty(): return
    for i in star_count:
        var idx = i * 3
        var x = _stars[idx]
        var y = _stars[idx + 1]
        if _is_masked(x, y):
            continue
        draw_texture(star_texture, Vector2(x, y), Color.WHITE)

func set_scroll_speed(speed: float):
    scroll_speed = speed

func set_star_bias(bias: float):
    star_bias = bias
    _init_stars()

func set_mask(texture: Texture2D, offset: Vector2 = Vector2.ZERO):
    mask_texture = texture
    mask_offset = offset
    if texture:
        mask_image = texture.get_image()
        if mask_image:
            # Decompress if needed for pixel access
            if mask_image.is_compressed():
                mask_image.decompress()
    else:
        mask_image = null

func update_mask_offset(offset: Vector2):
    mask_offset = offset

func _is_masked(x: float, y: float) -> bool:
    if not mask_image:
        return false
    # Check center and corners of star area (stars are ~2-3 pixels)
    for ox in [0, 2]:
        for oy in [0, 2]:
            if _is_opaque_at(x + ox, y + oy):
                return true
    return false

func _is_opaque_at(x: float, y: float) -> bool:
    var mx = int(x - mask_offset.x)
    var my = int(y - mask_offset.y)
    if mx < 0 or my < 0 or mx >= mask_image.get_width() or my >= mask_image.get_height():
        return false
    return mask_image.get_pixel(mx, my).a > 0.01

func _is_key_at(x: float, y: float) -> bool:
    var mx = int(x - mask_offset.x)
    var my = int(y - mask_offset.y)
    if mx < 0 or my < 0 or mx >= mask_image.get_width() or my >= mask_image.get_height():
        return false
    var pixel = mask_image.get_pixel(mx, my)
    if pixel.a < 0.01:
        return false
    var dist = sqrt(pow(pixel.r - key_color.r, 2) + pow(pixel.g - key_color.g, 2) + pow(pixel.b - key_color.b, 2))
    return dist < key_threshold
