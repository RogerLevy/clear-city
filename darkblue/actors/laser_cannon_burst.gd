extends Node2D

var radius: float = 0.0
var max_radius: float = 25.0
var expand_time: float = 0.15
var color: Color = g.COLOR_MAIN
var tween: Tween

func _ready():
    tween = create_tween()
    # Expand
    tween.tween_method(set_radius, 0.0, max_radius, expand_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
    # Shrink
    tween.tween_method(set_radius, max_radius, 0.0, expand_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
    tween.tween_callback(queue_free)

func set_radius(r: float):
    radius = r
    queue_redraw()

func _draw():
    draw_circle(Vector2.ZERO, radius, color)
