extends Node2D

# Big shot burst - 20-radius circle that expands from turret tip

var radius: float = 0.0
var max_radius: float = 20.0
var expand_time: float = 0.1
var hold_time: float = 0.05
var fade_time: float = 0.1
var color: Color = Color(0.82, 0.82, 0.7, 1.0)

func _ready():
    var tween = create_tween()
    # Expand
    tween.tween_method(set_radius, 0.0, max_radius, expand_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
    # Hold
    tween.tween_interval(hold_time)
    # Fade
    tween.tween_property(self, "modulate:a", 0.0, fade_time)
    tween.tween_callback(queue_free)

func set_radius(r: float):
    radius = r
    queue_redraw()

func _draw():
    draw_circle(Vector2.ZERO, radius, color)
