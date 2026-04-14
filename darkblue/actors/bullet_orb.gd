@tool
class_name BulletOrb
extends Actor2D

@export var atk: int = 30
@export var pulse_amount: float = 0.5
@export var pulse_duration: float = 0.3

static var DEFAULT_ANIM: Array = [2,3,3,2,1,1,0,1,]

var _tween: Tween

func _pulse():
    if _tween:
        _tween.kill()
    _tween = create_tween()
    var big = Vector2(1.0 + pulse_amount, 1.0 + pulse_amount)
    scale = big
    _tween.tween_property(self, "scale", Vector2.ONE, pulse_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_beat(_b: int):
    _pulse()

func _physics_process(_delta):
    super._physics_process(_delta)
    position += velocity * _delta
    # Lockstep animation synced to beat (full loop = 1/8th note = 0.5 beats)
    var anim_size = DEFAULT_ANIM.size()
    var frame_idx = int(beat.current_beat / 0.5 * anim_size) % anim_size
    current_frame = DEFAULT_ANIM[frame_idx]

func init():
    add_to_group("enemy_projectiles")
    beat.beat_hit.connect(_on_beat)
