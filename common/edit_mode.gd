extends CanvasLayer

var enabled := false
var selected_actor: Actor2D = null
var hovered_actor: Actor2D = null
var dragging := false
var drag_offset := Vector2.ZERO
var actors_under_mouse: Array[Actor2D] = []
var cycle_index := 0

@onready var label: Label
@onready var draw_layer: Control

func _init():
    process_mode = Node.PROCESS_MODE_ALWAYS

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 99

    draw_layer = Control.new()
    draw_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
    draw_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    draw_layer.set_script(preload("res://common/edit_mode_draw.gd"))
    draw_layer.edit_mode = self
    draw_layer.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(draw_layer)

    label = Label.new()
    label.position = Vector2(4, 4)
    label.add_theme_font_size_override("font_size", 8)
    label.add_theme_color_override("font_color", Color.WHITE)
    label.add_theme_color_override("font_shadow_color", Color.BLACK)
    label.add_theme_constant_override("shadow_offset_x", 1)
    label.add_theme_constant_override("shadow_offset_y", 1)
    add_child(label)
    label.visible = false

func handle_input(event: InputEvent):
    if not is_node_ready():
        return
    if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
        enabled = not enabled
        get_tree().paused = enabled
        print("Edit mode: ", enabled)
        label.visible = enabled
        if not enabled:
            selected_actor = null
            hovered_actor = null
            dragging = false
            draw_layer.queue_redraw()
        return

    if not enabled:
        return

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _on_click(event.position)
        else:
            dragging = false

    if event is InputEventMouseMotion:
        if dragging and selected_actor:
            selected_actor.global_position = _screen_to_world(event.position) + drag_offset
            _update_label()
        else:
            _update_hover(event.position)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
    var viewport = get_viewport()
    var canvas_transform = viewport.get_canvas_transform()
    return canvas_transform.affine_inverse() * screen_pos

func _get_actors_at(screen_pos: Vector2) -> Array[Actor2D]:
    var world_pos = _screen_to_world(screen_pos)
    var result: Array[Actor2D] = []

    for node in get_tree().get_nodes_in_group("actors"):
        if node is Actor2D:
            var rect = _get_actor_rect(node)
            if rect.has_point(world_pos):
                result.append(node)

    # Also check all Actor2D nodes not in group
    for node in _find_all_actors(get_tree().current_scene):
        if node not in result:
            var rect = _get_actor_rect(node)
            if rect.has_point(world_pos):
                result.append(node)

    return result

func _find_all_actors(node: Node) -> Array[Actor2D]:
    var result: Array[Actor2D] = []
    if node is Actor2D:
        result.append(node)
    for child in node.get_children():
        result.append_array(_find_all_actors(child))
    return result

func _get_actor_rect(actor: Actor2D) -> Rect2:
    if actor.sprite and actor.sprite.texture:
        var size = Vector2(actor.frame_width, actor.frame_height)
        var offset = -size / 2  # Assuming centered sprite
        if not actor.sprite.centered:
            offset = Vector2.ZERO
        return Rect2(actor.global_position + offset, size)
    return Rect2(actor.global_position - Vector2(8, 8), Vector2(16, 16))

func _on_click(screen_pos: Vector2):
    var actors = _get_actors_at(screen_pos)

    if actors.is_empty():
        selected_actor = null
        _update_label()
        return

    # Cycle through actors if clicking same spot
    if selected_actor in actors:
        cycle_index = (actors.find(selected_actor) + 1) % actors.size()
    else:
        cycle_index = 0

    selected_actor = actors[cycle_index]
    actors_under_mouse = actors
    dragging = true
    drag_offset = selected_actor.global_position - _screen_to_world(screen_pos)
    _update_label()

func _update_hover(screen_pos: Vector2):
    var actors = _get_actors_at(screen_pos)
    hovered_actor = actors[0] if actors.size() > 0 else null
    draw_layer.queue_redraw()

func _update_label():
    if selected_actor:
        var script_name = ""
        var script = selected_actor.get_script()
        if script:
            script_name = script.resource_path.get_file().get_basename()
        label.text = "%s\npos: %s" % [script_name, selected_actor.global_position]
    else:
        label.text = "Edit Mode (Tab to exit)"
    draw_layer.queue_redraw()

func _process(_delta):
    if enabled:
        draw_layer.queue_redraw()
