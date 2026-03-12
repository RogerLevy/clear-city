extends "res://common/common.gd"

var p1: Node2D           # player ship reference
var energy: int = 100    # player energy/health
var mouse_control_style: int = 0  # 0 = full, 1 = local
var mouse_constraint_radius: float = 50
var quantize_aim:bool = false
var move_mouse_with_player:bool = true

var _p1_prev_pos: Vector2
var _status_text: BitmapText

func _ready():
    super._ready()
    _status_text = get_tree().current_scene.get_node_or_null("%EnergyStatusText")
    if OS.has_feature("editor"):
        set_deferred( "energy", 1000000 )

func process_mouse():
    if move_mouse_with_player and p1 and get_window().has_focus():
        var pos = p1.global_position.round()
        var delta_pos = pos - _p1_prev_pos
        if delta_pos != Vector2.ZERO:
            var root = get_tree().root
            root.warp_mouse(root.get_mouse_position() + delta_pos)
        _p1_prev_pos = pos
    constrain_mouse()

func process_status():
    _status_text.text = "%d" % energy

func _process(_delta):
    process_mouse()
    process_status()

func constrain_mouse():
    super.constrain_mouse()
    if mouse_control_style != 1 or not p1 or not get_window().has_focus():
        return
    var root = get_tree().root
    var mouse = root.get_mouse_position()
    var center = p1.global_position
    var offset = mouse - center
    if offset.length() > mouse_constraint_radius:
        root.warp_mouse(center + offset.normalized() * mouse_constraint_radius)
