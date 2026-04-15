extends Sprite2D

var scroll_speed: float = 0.5
var _starfield: StarfieldParticles

func _ready():
    _starfield = get_tree().current_scene.get_node_or_null("%Starfield")
    if _starfield and texture:
        _starfield.set_mask(texture, _get_mask_offset())
        print("Initial mask offset: ", _get_mask_offset(), " global_pos: ", global_position)

func _get_mask_offset() -> Vector2:
    var tex_offset = offset
    if centered:
        tex_offset -= texture.get_size() / 2
    return global_position + tex_offset

var _debug_counter := 0
func _physics_process(delta: float) -> void:
    position.x += g.scroll_speed.x * delta
    if _starfield:
        var offset = _get_mask_offset()
        _starfield.update_mask_offset(offset)
        _debug_counter += 1
        if _debug_counter % 60 == 0:
            print("Mask offset: ", offset)
