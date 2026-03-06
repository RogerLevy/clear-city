extends Control

func _ready():
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw():
    if not OS.has_feature("editor") and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
        return
    var viewport_size = get_viewport().get_visible_rect().size
    print(viewport_size)
    var scl = get_viewport().get_screen_transform().get_scale()
    draw_rect(Rect2(Vector2.ZERO, viewport_size - Vector2( 1/scl.x - 0.001, 1/scl.y - 0.001 )), Color.DIM_GRAY, false, 1/scl.y )

func _process( delta ):
    queue_redraw()
