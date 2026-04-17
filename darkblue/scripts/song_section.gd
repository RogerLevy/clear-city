@tool
extends Sequence
class_name SongSection

@export var beat:float = 0
static var current_section:SongSection
var _debug_font: Font = preload("res://common/font_04B_03__.ttf")
#var _name_display_timer: float = 0.0

func _ready():
    if not Engine.is_editor_hint():
        var warnings = EntryWarnings.new()
        add_child(warnings)
    super._ready()

func start():
    current_section = self
    #_name_display_timer = 3.0
    super.start()

func _process(delta):
    if Engine.is_editor_hint(): return
    #if _name_display_timer > 0:
        #_name_display_timer -= delta
    queue_redraw()

func _draw():
    if Engine.is_editor_hint(): return
    #if not OS.is_debug_build(): return
    if not g.debug_info: return
    var screen_size = get_viewport().get_visible_rect().size
    var bottom_left = to_local(Vector2(4, screen_size.y - 4))
    draw_string(_debug_font, bottom_left, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.YELLOW)
