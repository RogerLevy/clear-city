extends Node
class_name ShootAtPlayer

@export var bullet_scene: PackedScene = preload("res://darkblue/actors/bullet_orb.tscn")
@export var beat_interval: float = 8.0
@export var bullet_speed: float = 0.9  # pixels per frame
@export var bullet_atk: int = 50

var _last_shot_beat: int = -999

func _is_on_screen(node: Node2D) -> bool:
    var pos = node.global_position
    var screen_size = node.get_viewport().get_visible_rect().size
    return pos.x >= 0 and pos.x <= screen_size.x and pos.y >= 0 and pos.y <= screen_size.y

func _physics_process(_delta):
    if Engine.is_editor_hint(): return
    if not beat.playing: return

    var parent = get_parent()
    if not parent or not parent.is_visible_in_tree(): return
    if "dead" in parent and parent.dead: return
    if not _is_on_screen(parent): return

    var current = beat.beat_number
    if current >= _last_shot_beat + beat_interval:
        _last_shot_beat = current
        _shoot(parent)

func _shoot(parent: Node2D):
    var player = g.p1
    if not player or not is_instance_valid(player): return

    var bullet = bullet_scene.instantiate()
    bullet.global_position = parent.global_position

    # Set velocity towards player (2 pixels per frame)
    var dir = (player.global_position - parent.global_position).normalized()
    bullet.velocity = dir * bullet_speed * Engine.physics_ticks_per_second

    # Set attack value
    if "atk" in bullet: 
        bullet.atk = bullet_atk

    # Add to playfield
    var playfield = g.get("playfield")
    if playfield:
        playfield.add_child(bullet)
    else:
        parent.get_parent().add_child(bullet)
