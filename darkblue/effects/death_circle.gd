extends Sprite2D

# Death circle effect - fills then erases

var radius: float = 16.0
var fill_time: float = 0.1
var erase_time: float = 0.33
var fill_ease: Tween.EaseType = Tween.EASE_OUT
var fill_trans: Tween.TransitionType = Tween.TRANS_EXPO
var erase_ease: Tween.EaseType = Tween.EASE_OUT
var erase_trans: Tween.TransitionType = Tween.TRANS_EXPO
var speed: float = 1

var mat: ShaderMaterial


func _ready():
    # Create material from shader
    var shader = preload("res://darkblue/effects/death_circle.gdshader")
    mat = ShaderMaterial.new()
    mat.shader = shader
    material = mat

    # Create a white texture for the shader to work with
    var size = int(radius * 2.0)
    var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
    img.fill(Color.WHITE)
    var tex = ImageTexture.create_from_image(img)
    texture = tex
    centered = true

    # Start animation
    mat.set_shader_parameter("fill_radius", 0.0)
    mat.set_shader_parameter("cutout_radius", 0.0)

    var tween = create_tween()
    # Fill phase
    tween.tween_method(set_fill_radius, 0.0, 1.0, fill_time * (1.0 / speed)).set_ease(fill_ease).set_trans(fill_trans)
    # Erase phase
    tween.tween_method(set_cutout_radius, 0.0, 1.0, erase_time * (1.0 / speed)).set_ease(erase_ease).set_trans(erase_trans)
    tween.tween_callback(queue_free)

func set_fill_radius(value: float):
    mat.set_shader_parameter("fill_radius", value)

func set_cutout_radius(value: float):
    mat.set_shader_parameter("cutout_radius", value)

static func spawn(parent: Node, pos: Vector2, r: float, col: Color = Color.WHITE, speed: float = 1) -> Sprite2D:
    var effect = load("res://darkblue/effects/death_circle.tscn").instantiate()
    effect.radius = r
    effect.global_position = pos
    effect.modulate = col
    effect.speed = speed
    parent.add_child(effect)
    return effect
