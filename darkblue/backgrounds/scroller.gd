extends Node2D

@export var parallax:float = 1

func _physics_process(delta: float) -> void:
    position.x += g.scroll_speed.x * delta * parallax
