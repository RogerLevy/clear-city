class_name FloatingText
extends Label

@export var float_distance: float = 16.0
@export var float_time: float = 0.25
@export var hold_time: float = 0.25

func _ready():
    var tween = create_tween()
    tween.tween_property(self, "position:y", position.y - float_distance, float_time)
    tween.tween_interval(hold_time)
    tween.tween_callback(queue_free)

static func spawn(parent: Node, pos: Vector2, msg: String, font: Font = null, size: int = 16, color: Color = Color.WHITE) -> FloatingText:
    var ft = FloatingText.new()
    ft.text = msg
    ft.position = pos
    if font:
        ft.add_theme_font_override("font", font)
    ft.add_theme_font_size_override("font_size", size)
    ft.add_theme_color_override("font_color", color)
    parent.add_child(ft)
    return ft
