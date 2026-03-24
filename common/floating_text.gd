class_name FloatingText
extends Label

@export var float_distance: float = 16.0
@export var float_time: float = 0.25
@export var hold_time: float = 0.33

const SLOT_SPACING: float = 8.0
const MAX_SLOTS: int = 8
static var _slot_owners: Dictionary = {}  # owner -> Array[bool]
var _owner: Object
var _slot: int = -1

func _ready():
    var tween = create_tween()
    tween.tween_property(self, "position:y", position.y - float_distance, float_time)
    tween.tween_interval(hold_time)
    tween.tween_callback(_free_slot)

func _free_slot():
    if _owner and _slot >= 0 and _owner in _slot_owners:
        _slot_owners[_owner][_slot] = false
    queue_free()

static func _get_free_slot(owner: Object) -> int:
    if owner not in _slot_owners:
        var slots: Array[bool] = []
        slots.resize(MAX_SLOTS)
        slots.fill(false)
        _slot_owners[owner] = slots
    var slots: Array[bool] = _slot_owners[owner]
    for i in slots.size():
        if not slots[i]:
            slots[i] = true
            return i
    return 0  # fallback to bottom slot if all full

static func spawn(parent: Node, pos: Vector2, msg: String, font: Font = null, size: int = 16, color: Color = Color.WHITE, owner: Object = null) -> FloatingText:
    var ft = FloatingText.new()
    ft.text = msg
    ft._owner = owner if owner else parent
    ft._slot = _get_free_slot(ft._owner)
    ft.position = pos - Vector2(0, ft._slot * SLOT_SPACING)
    if font:
        ft.add_theme_font_override("font", font)
    ft.add_theme_font_size_override("font_size", size)
    ft.add_theme_color_override("font_color", color)
    parent.add_child(ft)
    return ft
