extends Actor2D

@export var range: float = 4.0:
    set(v):
        range = v
        _propagate(&"range", v)

@export var speed: float = 5.0:
    set(v):
        speed = v
        _propagate(&"speed", v)

@export var phase: float = 0.0:
    set(v):
        phase = v
        _propagate(&"phase", v)

@export var stagger_frames: int = 18
@export var range_factor: float = 0.8
@export var range_minimum: float = 2.0

func _ready():
    _propagate(&"range", range)
    _propagate(&"speed", speed)
    _propagate(&"phase", phase)
    super._ready()

func _propagate(prop: StringName, value: Variant):
    _propagate_to_children(self, prop, value)

func _propagate_to_children(node: Node, prop: StringName, value: Variant):
    for child in node.get_children():
        if prop in child:
            child.set(prop, value)
        for i in stagger_frames:
            await get_tree().process_frame
        var next_value = maxf(value * range_factor, range_minimum) if prop == &"range" else value
        _propagate_to_children(child, prop, next_value)
