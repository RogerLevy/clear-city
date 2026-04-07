@tool
extends Sequence
class_name AutoStarter

## Automatically calls next() on interval, with optional start delay.

@export var start_delay: float = 0.0  ## Delay in beats before first next()
@export var interval: float = 1.0  ## Beats between each next() call

var _started: bool = false
var _last_beat: int = -1
var _start_beat: int = 0

func start():
    super.start()
    _started = true
    _start_beat = int(beat.beat_number)
    _last_beat = -1

func _physics_process(_delta):
    if Engine.is_editor_hint(): return
    if not _started or not running: return
    if not beat.playing: return

    var current_beat = int(beat.beat_number)
    var beats_since_start = current_beat - _start_beat

    if beats_since_start < start_delay:
        return

    var adjusted_beats = beats_since_start - start_delay
    var interval_num = int(adjusted_beats / interval)
    var fire_beat = _start_beat + int(start_delay) + interval_num * int(interval)

    if fire_beat == _last_beat:
        return

    _last_beat = fire_beat
    next()
