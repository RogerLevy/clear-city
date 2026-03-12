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
@export var stick_around: bool = false  # If true, don't free on completion
var sequences_launched: int = 0
var _pending_free: bool = false
var _seeking: bool = false
var _seek_next_count: int = 0
var frozen: bool = false  # When true, launch/next/complete become no-ops

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
    running = false
    if _anim:
        _anim.stop()
    if _timer:
        _timer.queue_free()
        _timer = null
    for seq in running_sequence_children():
        seq.stop()

func freeze():
    frozen = true
    for seq in running_sequence_children():
        seq.freeze()

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
    if frozen or _seeking: return
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
    if frozen or not running: return
    running = false
    sequence_completed.emit()
    if not stick_around:
        _pending_free = true
        try_free()

func _complete():
    complete()

## Call this from subclasses when their work is done.
## Only completes if nothing else (duration, animation, open_ended) is responsible.
func auto_complete():
    if _duration_override or open_ended or has_animation:
        return
    complete()
    
func next():
    if frozen: return
    var anim_pos = _anim.current_animation_position if _anim else -1
    # During seek, just count calls without launching
    if _seeking:
        _seek_next_count += 1
        print_debug("next() BLOCKED during seek, count=", _seek_next_count, " anim_pos=", anim_pos)
        return

    _current_index += 1
    print_debug("next() _current_index=", _current_index, " _sequence_list.size()=", _sequence_list.size(), " anim_pos=", anim_pos)
    if _current_index >= _sequence_list.size():
        print_debug("next() past end of sequence list")
        if not _duration_override and not open_ended:
            _complete()
        return
    var seq = _sequence_list[_current_index]
    print_debug(name, " next() launching seq=", seq.name if seq else "null")
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

## Start from a specific beat (for debugging/testing)
## Seeks the animation to the corresponding time position
func start_from_beat(from_beat: float):
    running = true

    if _anim:
        _anim.speed_scale = 1.0 / _get_time_scale()

        if has_animation:
            # Convert beat to animation time (accounting for speed_scale)
            # MUSICAL: animation in beat units, so seek_time = from_beat
            # NORMAL: animation in real seconds, so seek_time = from_beat * beat.scale
            var seek_time: float = from_beat * beat.scale / _get_time_scale()

            # Count how many next() calls happen before seek_time by reading the animation
            var anim: Animation = _anim.get_animation(autoplay_name)
            var next_calls_before_seek := 0
            for track_idx in anim.get_track_count():
                if anim.track_get_type(track_idx) == Animation.TYPE_METHOD:
                    for key_idx in anim.track_get_key_count(track_idx):
                        var key_time: float = anim.track_get_key_time(track_idx, key_idx)
                        if key_time < seek_time:
                            var method_name = anim.method_track_get_name(track_idx, key_idx)
                            if method_name == &"next":
                                next_calls_before_seek += 1

            # Skip the sequences that would have been launched
            _current_index = next_calls_before_seek - 1  # -1 because next() increments first
            print_debug("start_from_beat: from_beat=", from_beat, " seek_time=", seek_time, " next_calls=", next_calls_before_seek, " _current_index=", _current_index)

            # Play and seek slightly before target so methods at seek_time trigger naturally
            # Use _seeking to block method calls during seek (deferred until next frame)
            _seeking = true
            _anim.play(autoplay_name)
            _anim.seek(seek_time - 0.001, true)
            print_debug("  after seek, anim_pos=", _anim.current_animation_position)
            call_deferred("_end_seeking")

            if not _duration_override:
                _connect_animation_finished()
            return

    # No animation - just start normally
    start()

func _ready():
    add_to_group("sequences")

    # Always run if the sequence is the scene root
    if get_parent() == get_tree().root:
        running = true
    
    # Find AnimationPlayer child
    for child in get_children():
        if child is AnimationPlayer and child.get_node(child.root_node) == self:
            _anim = child
            break

    # Build sequence list and hide them
    _sequence_list = []
    for child in get_children():
        if child is Sequence:
            _sequence_list.append(child)
            print_debug("Sequence._ready: ", name, " _anim=", _anim, " has_animation=", has_animation, " _sequence_list=", _sequence_list.map(func(s): return s.name))
            child.visible = false
            child.process_mode = Node.PROCESS_MODE_DISABLED

    if not running:
        stop()
    else:
        # Defer start to ensure BeatConfig._ready() has run first
        call_deferred("_deferred_start")

func _end_seeking():
    _seeking = false
    print_debug("_end_seeking, anim_pos=", _anim.current_animation_position if _anim else -1)

func _deferred_start():
    print_debug("Sequence._deferred_start: target=", beat.target_sequence, " self=", self, " from_beat=", beat.started_from_beat)
    if beat.target_sequence == self and beat.started_from_beat > 0:
        start_from_beat(beat.started_from_beat)
    else:
        start()
