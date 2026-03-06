@tool
class_name GuideRect
extends Control

@export var width = 480
@export var height = 320

func _ready():
    mouse_filter = MOUSE_FILTER_IGNORE
    
    if not Engine.is_editor_hint():
        queue_free()
        return
    
    # In editor, check ownership directly without await
    var edited_scene_root = get_tree().edited_scene_root
    if edited_scene_root and owner != edited_scene_root:
        visible = false
        return
    
    set_meta("_edit_lock_", true)
    size = Vector2(width, height)
    queue_redraw()
        
func _draw():
    draw_rect(Rect2(Vector2.ZERO, Vector2(width, height)), Color.RED, false)
