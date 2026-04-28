@tool
class_name BulletOrb
extends Actor2D

@export var atk: int = 10
@export var pulse_amount: float = 0
@export var pulse_duration: float = 0.3

static var DEFAULT_ANIM: Array = [2,3,3,2,1,1,0,1,]
static var PULSE_ANIM: Array = [7, 6, 5, 4]
static var PULSE_DURATION: float = 0.4  ## Duration in beats

var _tween: Tween
var _pulse_start_beat: float = -1.0

# Tween-based pulse (disabled, kept for reference)
#func _pulse():
#    if _tween:
#        _tween.kill()
#    _tween = create_tween()
#    var big = Vector2(1.0 + pulse_amount, 1.0 + pulse_amount)
#    scale = big
#    _tween.tween_property(self, "scale", Vector2.ONE, pulse_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_beat(_b: int):
    _pulse_start_beat = beat.current_beat

func _physics_process(_delta):
    super._physics_process(_delta)
    position += velocity * _delta

    # Check if we're in a pulse
    var pulse_progress = beat.current_beat - _pulse_start_beat
    if _pulse_start_beat >= 0 and pulse_progress >= 0 and pulse_progress < PULSE_DURATION:
        # Play pulse animation
        var pulse_idx = int(pulse_progress / PULSE_DURATION * PULSE_ANIM.size())
        pulse_idx = mini(pulse_idx, PULSE_ANIM.size() - 1)
        current_frame = PULSE_ANIM[pulse_idx]
    else:
        # Lockstep animation synced to beat (full loop = 1/8th note = 0.5 beats)
        var anim_size = DEFAULT_ANIM.size()
        var frame_idx = int(beat.current_beat / 0.5 * anim_size) % anim_size
        current_frame = DEFAULT_ANIM[frame_idx]

func init():
    add_to_group("enemy_projectiles")
    beat.beat_hit.connect(_on_beat)
