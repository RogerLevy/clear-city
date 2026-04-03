extends Node2D

var _n:float = 0
@export var speed:float = 0
@export var range:float = 0
@export var phase:float = 0

func _physics_process(delta: float) -> void:
    _n += delta * speed
    rotation = sin( (_n + phase) / TAU ) * ( range / TAU )

#func _draw():
    #draw_circle( Vector2.ZERO, 8, g.COLOR_MAIN )
