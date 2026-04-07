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

@tool
@icon( "res://common/sequence.svg" )
extends Node2D
class_name Sequence

enum StartMode {
    NORMAL,      ## Externally controlled only (launched by parent or code)
    IMMEDIATE,   ## Start on _ready()
    ON_PARENT,   ## Start when nearest Sequence ancestor starts
    ON_NODE,     ## Start when specific node (start_node) starts
    ON_SIGNAL,   ## Start when beat emits matching signal_name
}

@export var timing_mode: TimingMode.Mode = TimingMode.Mode.DEFAULT
@export var start_mode: StartMode = StartMode.NORMAL:
    set(v):
        start_mode = v
        notify_property_list_changed()
@export var start_node: NodePath  ## For ON_NODE mode: which Sequence to watch
@export var signal_name: String  ## For ON_SIGNAL mode: which signal to listen for
@export var signal_on_start: bool = false:  ## Emit signal_name via beat when this sequence starts
    set(v):
        signal_on_start = v
        notify_property_list_changed()

func _validate_property(property: Dictionary) -> void:
    match property.name:
        "start_node":
            if start_mode != StartMode.ON_NODE:
                property["usage"] = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY
        "signal_name":
            if start_mode != StartMode.ON_SIGNAL and not signal_on_start:
                property["usage"] = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY
var running: bool = false  # Runtime state - true while sequence is active
var _start_mode_ancestor: Sequence  # Cached for ON_PARENT mode
var _sequence_list: Array[Sequence] = []  # Cached list of sequence children, captured at _ready()
var _independent_list: Array[Sequence] = []  # Independent sequences to start with parent
var _current_index: int = -1               # Index into _sequence_list, not raw child index
@export var duration: float = -1    # -1 = duration depends on child sequences or AnimationPlayer if present
var _timer: Timer
var _duration_override: bool = false
var _anim: AnimationPlayer
@export var autoplay_name: StringName = &"sequence"
@export var open_ended: bool = false  ## If true, completion is code- or animation-controlled only
@export var important: bool = false   ## On completion: false = free when no running Sequence children, true = free when no Sequence children
@export var stick_around: bool = false  ## If true, don't free on completion
var sequences_launched: int = 0
var _pending_free: bool = false
var _seeking: bool = false
var _seek_next_count: int = 0
var frozen: bool = false  # When true, launch/next/complete become no-ops

func _get_time_scale() -> float:
    return beat.get_scale_for_mode(timing_mode)

signal sequence_completed
signal sequence_started

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

func launch_sequence( seq:Sequence, is_independent: bool = false ):
    sequences_launched += 1
    seq.visible = true
    seq.process_mode = Node.PROCESS_MODE_INHERIT
    if not seq.sequence_completed.is_connected(_on_child_sequence_completed):
        seq.sequence_completed.connect( _on_child_sequence_completed.bind(seq, is_independent), CONNECT_ONE_SHOT )
    seq.call_deferred( "start" )

func launch( name ):
    if frozen or _seeking: return
    for seq in _sequence_list:
        if seq.name == name:
            launch_sequence( seq )
            return

func sequence_children() -> Array[Node]:
    return get_children().filter(func(c): return c is Sequence)

## Returns true if a child sequence runs independently (doesn't block parent)
func _is_independent(seq: Sequence) -> bool:
    # Non-NORMAL start modes handle their own starting
    if seq.start_mode != StartMode.NORMAL: return true
    if seq.open_ended: return false  # Explicitly blocking forever
    if seq.duration == -1:
        # Check if it has an animation or child sequences that would make it complete
        for child in seq.get_children():
            if child is AnimationPlayer and child.has_animation(seq.autoplay_name):
                return false
            if child is Sequence:
                return false  # Has child sequences, will complete when they do
        return true
    return false

func running_sequence_children() -> Array[Node]:
    return sequence_children().filter(func(c): return c.running and not _is_independent(c))

func can_free() -> bool:
    if important:
        return sequence_children().is_empty()
    else:
        return running_sequence_children().is_empty()

func try_free():
    if _pending_free and can_free():
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
    print_debug(name, ".next() index=", _current_index, "/", _sequence_list.size())
    if _current_index >= _sequence_list.size():
        if not _duration_override and not open_ended:
            _complete()
        return
    var seq = _sequence_list[_current_index]
    if is_instance_valid(seq):
        print_debug(name, " launching ", seq.name)
        launch_sequence(seq)

func _on_child_sequence_completed( _seq: Sequence, is_independent: bool = false ):
    if running and not has_animation and not is_independent:
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
    if open_ended: return
    _complete()

func start():
    if running: return  # Prevent double-start
    running = true
    print_debug(name, ".start() has_animation=", has_animation, " duration=", duration, " autoplay_name=", autoplay_name)

    # Emit signals
    sequence_started.emit()
    if signal_on_start and signal_name:
        beat.sequence_signal.emit(signal_name)

    # Launch independent sequences (they don't block, just run alongside)
    for seq in _independent_list:
        launch_sequence(seq, true)

    # Apply timing scale and restart all child AnimationPlayers
    # Skip RelativeAnimationPlayer - it handles its own timing
    var time_scale = _get_time_scale()
    for child in get_children():
        if child is AnimationPlayer and not child is RelativeAnimationPlayer:
            child.speed_scale /= time_scale
            # Restart whatever animation was playing (via autoplay)
            if child.autoplay and child.has_animation(child.autoplay):
                child.play(child.autoplay)

    if duration >= 0 and not open_ended:
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

    # Stop all child AnimationPlayers (they may have autoplay) and find the sequence animation
    for child in get_children():
        if child is AnimationPlayer:
            child.stop()  # Stop any autoplay immediately
            if child.has_animation(autoplay_name):
                _anim = child

    # Build sequence list and hide them
    # Check for SequenceStart marker - skip all Sequence siblings before it
    var skip_until_after_start := false
    for child in get_children():
        if child is SequenceStart and child.process_mode != PROCESS_MODE_DISABLED:
            skip_until_after_start = true
            break

    _sequence_list = []
    _independent_list = []
    var found_start := false
    for child in get_children():
        if child is SequenceStart and child.process_mode != PROCESS_MODE_DISABLED:
            found_start = true
            continue
        if child is Sequence:
            # First check if before SequenceStart - disable regardless of independent
            if skip_until_after_start and not found_start:
                child.visible = false
                child.process_mode = Node.PROCESS_MODE_DISABLED
                continue
            # Independent sequences run on their own, not in sequence list
            if _is_independent(child):
                _independent_list.append(child)
                child.visible = false
                child.process_mode = Node.PROCESS_MODE_DISABLED
                continue
            _sequence_list.append(child)
            child.visible = false
            child.process_mode = Node.PROCESS_MODE_DISABLED

    print_debug(name, " _sequence_list=", _sequence_list.map(func(s): return s.name), " _independent_list=", _independent_list.map(func(s): return s.name))

    # Handle start_mode
    match start_mode:
        StartMode.IMMEDIATE:
            call_deferred("_deferred_start")
        StartMode.ON_PARENT:
            # Find nearest Sequence ancestor
            var ancestor = get_parent()
            while ancestor and not ancestor is Sequence:
                ancestor = ancestor.get_parent()
            if ancestor is Sequence:
                _start_mode_ancestor = ancestor
                ancestor.sequence_started.connect(_on_start_mode_trigger, CONNECT_ONE_SHOT)
            else:
                # No ancestor - behave like IMMEDIATE
                call_deferred("_deferred_start")
        StartMode.ON_NODE:
            if start_node:
                var node = get_node_or_null(start_node)
                if node is Sequence:
                    node.sequence_started.connect(_on_start_mode_trigger, CONNECT_ONE_SHOT)
        StartMode.ON_SIGNAL:
            if signal_name:
                beat.sequence_signal.connect(_on_sequence_signal)
        StartMode.NORMAL, _:
            # Check if we have a Sequence ancestor that will launch us
            var ancestor = get_parent()
            while ancestor and not ancestor is Sequence:
                ancestor = ancestor.get_parent()
            if ancestor is Sequence:
                stop()  # Will be launched by ancestor sequence
            else:
                # Top-level sequence - defer start
                call_deferred("_deferred_start")

func _end_seeking():
    _seeking = false
    print_debug("_end_seeking, anim_pos=", _anim.current_animation_position if _anim else -1)

func _deferred_start():
    if beat.target_sequence == self and beat.started_from_beat > 0:
        start_from_beat(beat.started_from_beat)
    else:
        # For musical timing, wait for first beat_hit to sync
        if beat.resolve_timing_mode(timing_mode) == TimingMode.Mode.MUSICAL:
            beat.beat_hit.connect(_on_first_beat, CONNECT_ONE_SHOT)
        else:
            start()

func _on_first_beat(_beat_num: int):
    start()

func _on_start_mode_trigger():
    visible = true
    process_mode = Node.PROCESS_MODE_INHERIT
    start()

func _on_sequence_signal(sig_name: String):
    if sig_name == signal_name:
        beat.sequence_signal.disconnect(_on_sequence_signal)
        visible = true
        process_mode = Node.PROCESS_MODE_INHERIT
        start()
