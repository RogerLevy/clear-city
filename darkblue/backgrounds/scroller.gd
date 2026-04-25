extends Node2D

@export var parallax: float = 1
var _x: float = 0.0

func _ready() -> void:
    _x = position.x

func _physics_process(delta: float) -> void:
    _x += g.scroll_speed.x * delta * parallax
    position.x = round(_x)
