class_name OffscreenCleaner
extends Node

@export var delay: float = 1.0

var _timers: Dictionary = {}  # instance_id -> seconds off-screen

func _process(delta):
    var rect = get_viewport().get_visible_rect()
    var ct = get_viewport().get_canvas_transform()
    var bodies = get_tree().root.find_children("*", "CharacterBody2D", true, false)
    var active_ids = {}

    for body in bodies:
        var id = body.get_instance_id()
        active_ids[id] = true

        if not body.can_process() or not body.is_visible_in_tree() or body.velocity == Vector2.ZERO or body.is_in_group("do_not_cull"):
            _timers.erase(id)
            continue

        var pos = ct * body.global_position
        if rect.has_point(pos) or _moving_toward_screen(body.velocity, pos, rect):
            _timers.erase(id)
            continue

        _timers[id] = _timers.get(id, 0.0) + delta
        if _timers[id] >= delay:
            _timers.erase(id)
            body.queue_free()

    for id in _timers.keys():
        if not active_ids.has(id):
            _timers.erase(id)

func _moving_toward_screen(vel: Vector2, pos: Vector2, rect: Rect2) -> bool:
    if pos.x < rect.position.x and vel.x <= 0: return false
    if pos.x > rect.end.x    and vel.x >= 0: return false
    if pos.y < rect.position.y and vel.y <= 0: return false
    if pos.y > rect.end.y    and vel.y >= 0: return false
    return true
