extends Control

var edit_mode

func _draw():
    if not edit_mode or not edit_mode.enabled:
        return

    var viewport = get_viewport()
    var canvas_transform = viewport.get_canvas_transform()
    var all_actors = edit_mode._find_all_actors(edit_mode.get_tree().current_scene)

    # Draw all actors with magenta 50% opacity
    for actor in all_actors:
        if actor != edit_mode.selected_actor and actor != edit_mode.hovered_actor:
            _draw_actor_rect(actor, Color(1, 0, 1, 0.5), canvas_transform)

    # Draw hover highlight (yellow)
    if edit_mode.hovered_actor and edit_mode.hovered_actor != edit_mode.selected_actor:
        _draw_actor_rect(edit_mode.hovered_actor, Color.YELLOW, canvas_transform)

    # Draw selected highlight (green)
    if edit_mode.selected_actor:
        _draw_actor_rect(edit_mode.selected_actor, Color.GREEN, canvas_transform)

func _draw_actor_rect(actor: Actor2D, color: Color, canvas_transform: Transform2D):
    var rect = edit_mode._get_actor_rect(actor)
    var screen_pos = canvas_transform * rect.position
    var screen_size = rect.size * canvas_transform.get_scale()
    draw_rect(Rect2(screen_pos, screen_size), color, false, 1.0)
