"""
Flexible temporal sequencing node.
If has_animation is set, the animation is played.
When the animation is finished, a sequence_completed signal is emitted.

If has_animation is not set, the children are played in sequence.  (We assume the children are all also sequences.)
After the last one completes, a sequence_completed signal is emitted.

If a duration is set, the sequence_completed signal is emitted and the sequence stops after this duration.
    (Any playing animation or last child sequence completion does not cause the signal to be emitted.)

The animation if it is set to has_animation can direct the sequence by calling the launch() and next() functions
from a call method track.

"""

@icon( "res://common/sequence.svg" )
extends Node2D
class_name Sequence

@export var timing_mode: TimingMode.Mode = TimingMode.Mode.DEFAULT
@export var running: bool = false
var _sequence_list: Array[Sequence] = []  # Cached list of sequence children, captured at _ready()
var _current_index: int = -1               # Index into _sequence_list, not raw child index
@export var duration: float = -1    # -1 = duration depends on child sequences or AnimationPlayer if present
var _timer: Timer
var _duration_override: bool = false
var _anim: AnimationPlayer
@export var autoplay_name: StringName = &"sequence"
@export var open_ended: bool = false  # If true, completion is code- or animation-controlled only
@export var important: bool = false   # On completion: false = free when no running Sequence children, true = free when no Sequence children
var sequences_launched: int = 0
var _pending_free: bool = false

func _get_time_scale() -> float:
    return beat.get_scale_for_mode(timing_mode)

signal sequence_completed

# AnimationPlayer wrappers
var has_animation: bool:
    get: return _anim and _anim.has_animation( autoplay_name )

func play( name: String = "" ):
    if _anim:
        _anim.play( name if name else autoplay_name )

func stop():
    if _anim: 
        _anim.stop()

func _connect_animation_finished():
    if _anim:
        _anim.animation_finished.connect( _on_animation_finished, CONNECT_ONE_SHOT )

func launch_sequence( seq:Sequence ):
    sequences_launched += 1
    seq.visible = true
    seq.process_mode = Node.PROCESS_MODE_INHERIT
    #get_parent().add_child.call_deferred( seq )
    seq.sequence_completed.connect( _on_child_sequence_completed.bind(seq), CONNECT_ONE_SHOT )
    seq.call_deferred( "start" )

func launch( name ):
    for seq in _sequence_list:
        if seq.name == name:
            launch_sequence( seq )
            return

func sequence_children() -> Array[Node]:
    return get_children().filter(func(c): return c is Sequence)

func running_sequence_children() -> Array[Node]:
    return sequence_children().filter(func(c): return c.running)

func can_free() -> bool:
    if important:
        return sequence_children().is_empty()
    else:
        return running_sequence_children().is_empty()

func try_free():
    if _pending_free and can_free():
        print_debug("*** queue_free sequence ***")
        queue_free()

func complete():
    if not running: return
    running = false
    sequence_completed.emit()
    _pending_free = true
    try_free()

func _complete():
    complete()
    
func next():
    _current_index += 1
    if _current_index >= _sequence_list.size():
        if not _duration_override and not open_ended:
            _complete()
        return
    var seq = _sequence_list[_current_index]
    if is_instance_valid(seq):
        launch_sequence(seq)

func _on_child_sequence_completed( _seq: Sequence ):
    if running and not has_animation:
        next()
    try_free()

func _on_animation_finished( _anim_name: String ):
    if not running: return
    if _duration_override or open_ended: return
    _complete()

func _set_timer():
    if _timer:
        _timer.queue_free()
        _timer = null

    _timer = g.timeout( duration * _get_time_scale(), _on_timeout )
    add_child( _timer )

func _on_timeout():
    _complete()

func start():
    running = true

    # Apply timing scale to animation player
    if _anim:
        _anim.speed_scale = 1.0 / _get_time_scale()

    if duration >= 0:
        _duration_override = true
        _set_timer()

    if has_animation:
        if not _duration_override:
            _connect_animation_finished()
        play()
    else:
        next()

func _ready():
    #print_debug( self.to_string() )
    
    # Always run if the sequence is the scene root
    if get_parent() == get_tree().root:
        running = true
    
    # Find AnimationPlayer child
    for child in get_children():
        if child is AnimationPlayer:
            _anim = child
            break

    # Build sequence list and hide them
    _sequence_list = []
    for child in get_children():
        if child is Sequence:
            _sequence_list.append(child)
            child.visible = false
            child.process_mode = Node.PROCESS_MODE_DISABLED

    if not running:
        stop()
    else:
        start()
