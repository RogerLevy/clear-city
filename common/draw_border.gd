extends Control

func _draw():
	var viewport_size = get_viewport().get_visible_rect().size # * get_viewport().get_screen_transform().get_scale()
	print(viewport_size)
	var scl = get_viewport().get_screen_transform().get_scale()
	draw_rect(Rect2(Vector2.ZERO, viewport_size - Vector2( 1/scl.x - 0.001, 1/scl.y )), Color.WHITE, false, 1/scl.y )

func _process( delta ):
	queue_redraw()
