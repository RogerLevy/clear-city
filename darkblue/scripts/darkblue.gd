extends "res://common/common.gd"

signal enemy_died(enemy: Node, position: Vector2)

const COLOR_MAIN: Color = Color("d1d1b2")

func _init():
    scene_manifest_path = "res://darkblue/scene_manifest.gd"

func _should_include_in_manifest(path: String) -> bool:
    return path.begins_with("res://common/") or path.begins_with("res://darkblue/")

var p1: Node2D           # player ship reference
var tri_manager
var energy: int = 100    # player energy/health
var mouse_control_style: int = 0  # 0 = full, 1 = local
var mouse_constraint_radius: float = 50
var quantize_aim:bool = false
var move_mouse_with_player:bool = true

var _p1_prev_pos: Vector2
var _status_text_ref: BitmapText
var _status_text: BitmapText:
    get:
        if not _status_text_ref and get_tree().current_scene:
            _status_text_ref = get_tree().current_scene.get_node_or_null("%EnergyStatusText")
        return _status_text_ref
var _display_energy: float = 100.0  # rolls towards actual energy

var scroll_speed:Vector2 = Vector2(-50,0):
    get:
        return scroll_speed
    set(value):
        scroll_speed = value
        
func _ready():
    super._ready()
    #if OS.has_feature("editor"):
        #set_deferred( "energy", 1000000 )

func follow_mouse():
    if move_mouse_with_player and p1 and get_window().has_focus():
        var pos = p1.global_position.round()
        var delta_pos = pos - _p1_prev_pos
        if delta_pos != Vector2.ZERO:
            var root = get_tree().root
            root.warp_mouse(root.get_mouse_position() + delta_pos)
        _p1_prev_pos = pos

func process_mouse():
    if get_window().is_embedded():
        return
    #follow_mouse()
    constrain_mouse()

func process_status():
    if not _status_text: return
    # Roll display energy towards actual energy (faster when difference is larger)
    var diff = energy - _display_energy
    var roll_speed = absf(diff) * 0.1 + 1.0  # proportional + 1/frame minimum
    _display_energy = move_toward(_display_energy, energy, roll_speed)
    # Snap to target when close to avoid showing wrong integer
    if absf(_display_energy - energy) < 0.5:
        _display_energy = float(energy)
    _status_text.text = "%d" % int(_display_energy)

func _process(_delta):
    process_mouse()
    process_status()

func _input(event):
    super._input(event)
    if event.is_action_pressed("ui_reload"):
        get_tree().reload_current_scene()

func constrain_mouse():
    super.constrain_mouse()
    if mouse_control_style != 1 or not p1 or not get_window().has_focus(): return
    if get_window().is_embedded(): return
    var root = get_tree().root
    var mouse = root.get_mouse_position()
    var center = p1.global_position
    var offset = mouse - center
    if offset.length() > mouse_constraint_radius:
        root.warp_mouse(center + offset.normalized() * mouse_constraint_radius)
