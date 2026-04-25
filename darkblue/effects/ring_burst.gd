extends Sprite2D

# Ring burst effect - expands and fades out

var radius: float = 16.0
var duration: float = 0.5
var ease_type: Tween.EaseType = Tween.EASE_OUT
var trans_type: Tween.TransitionType = Tween.TRANS_QUART

var mat: ShaderMaterial
var thickness_px: float = 2.0
var ring_expansion: float = 0.4
var target: Node2D

func _ready():
    var shader = preload("res://darkblue/effects/ring_burst.gdshader")
    mat = ShaderMaterial.new()
    mat.shader = shader
    material = mat

    # Size texture so the ring can expand by ring_expansion in normalized space
    var texture_half = radius / (1.0 - ring_expansion)
    var size = int(texture_half * 2.0)
    var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
    img.fill(Color.WHITE)
    var tex = ImageTexture.create_from_image(img)
    texture = tex
    centered = true

    var norm_r = radius / texture_half
    var norm_thickness = thickness_px / texture_half
    mat.set_shader_parameter("radius", norm_r)
    mat.set_shader_parameter("thickness", norm_thickness)

    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_method(func(v): mat.set_shader_parameter("radius", v), norm_r, norm_r + ring_expansion, duration).set_ease(ease_type).set_trans(trans_type)
    tween.tween_property(self, "modulate:a", 0.0, duration).set_ease(ease_type).set_trans(trans_type)
    tween.set_parallel(false)
    tween.tween_callback(queue_free)

func _process(_delta):
    if target and is_instance_valid(target):
        global_position = target.global_position

static func spawn(parent: Node, pos: Vector2, r: float, col: Color = Color.WHITE, follow: Node2D = null) -> Sprite2D:
    var effect = load("res://darkblue/effects/ring_burst.tscn").instantiate()
    effect.radius = r
    effect.global_position = pos
    effect.modulate = col
    effect.target = follow
    parent.add_child(effect)
    return effect
