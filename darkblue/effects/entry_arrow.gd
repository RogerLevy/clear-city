class_name EntryArrow
extends Node2D

enum Edge { TOP, BOTTOM, LEFT, RIGHT }

var edge: Edge = Edge.LEFT:
    set(value):
        edge = value
        _update_rotation()

var vessels: Array[Node] = []  # Vessels this arrow represents

func _ready():
    _update_rotation()
    # Set arrow color
    #var arrow = get_node_or_null("Arrow")
    #if arrow is Polygon2D:
        #arrow.color = g.COLOR_MAIN

func _update_rotation():
    match edge:
        Edge.LEFT:   rotation = 0
        Edge.RIGHT:  rotation = PI
        Edge.TOP:    rotation = PI / 2
        Edge.BOTTOM: rotation = -PI / 2

func _process(_delta):
    # Blink at 1/8th note interval (toggle every 0.25 beats)
    visible = (int(beat.current_beat * 4) % 2) == 0

func should_remove() -> bool:
    # Remove if all tracked vessels/bursts are on screen (and visible) or gone
    # Use content_scale_size since vessels are in the scaled viewport
    var screen = Vector2(get_tree().root.content_scale_size)
    for vessel in vessels:
        if not is_instance_valid(vessel):
            continue
        # Handle BurstSequence - remove when running and on-screen
        if vessel is BurstSequence:
            if not vessel.running:
                return false
            var pos = vessel.global_position
            if pos.x < 0 or pos.x > screen.x or pos.y < 0 or pos.y > screen.y:
                return false
            continue
        # Not visible yet = still waiting to enter
        if not vessel.is_visible_in_tree():
            return false
        var pos = vessel.global_position
        # Visible but still off-screen
        if pos.x < 0 or pos.x > screen.x or pos.y < 0 or pos.y > screen.y:
            return false
    return true
