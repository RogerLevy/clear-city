@tool
class_name BeatConfig
extends Node

## Configure the global beat system when this node is a child of the scene root

@export var bpm: float = 120.0
@export var beats_per_measure: int = 4
@export var default_timing_mode: TimingMode.Mode = TimingMode.Mode.MUSICAL
@export var auto_start: bool = true
@export var music: AudioStreamWAV  ## WAV only for sample-accurate timing

var _warning_pending := false

@export_group("Debug")
@export_range(0, 9999, 1) var start_from_beat = 0:  ## Start playback from this beat (for testing)
    set(value):
        start_from_beat = value
        if value > 0:
            _schedule_warning_check()

@export var target_sequence: NodePath  ## Sequence to start (seeks animation to start_from_beat)

func _schedule_warning_check():
    if _warning_pending:
        return
    _warning_pending = true
    call_deferred("_do_warning_check")

func _do_warning_check():
    _warning_pending = false
    if Engine.is_editor_hint():
        _check_start_from_beat_warning()
    
@export var metronome_enabled: bool = false
@export var metronome_sound: AudioStreamWAV  ## WAV only for sample-accurate timing

func _ready():
    if Engine.is_editor_hint(): return
    # Check if parent is the scene root (direct child of viewport)
    if get_parent().get_parent() != get_tree().root: return

    _apply_config()
    # Store target sequence for Sequence to check
    if target_sequence:
        beat.target_sequence = get_node_or_null(target_sequence)

    # Show warning before starting beat (dialog blocks until dismissed)
    #if start_from_beat > 0:
        #_check_start_from_beat_warning()
        #_warning_pending = false  # Prevent deferred check from running again

    if auto_start:
        if music:
            beat.play_music(music, start_from_beat)
        else:
            beat.start(start_from_beat)

func _check_start_from_beat_warning():
    var target = get_node_or_null(target_sequence) if target_sequence else null
    if not target:
        OS.alert("start_from_beat is set but no target_sequence is specified.\n\nTo skip to a specific sequence, add a SequenceStart node as a child - all sibling Sequences before it will be skipped.", "BeatConfig Warning")
        return

    # Check for animation ourselves since Sequence isn't @tool
    var has_anim := false
    for child in target.get_children():
        if child is AnimationPlayer and child.has_animation(&"sequence"):
            has_anim = true
            break

    if not has_anim:
        # Check if SequenceStart is already present
        for child in target.get_children():
            if child is SequenceStart and child.process_mode != PROCESS_MODE_DISABLED:
                return  # Already has SequenceStart, no warning needed
        OS.alert("start_from_beat requires an animation on the target sequence '%s'.\n\nTo skip to a specific sequence, add a SequenceStart node as a child - all sibling Sequences before it will be skipped.\n\nNote: Music will still start from the specified beat." % target.name, "BeatConfig Warning")

func _apply_config():
    beat.bpm = bpm
    beat.beats_per_measure = beats_per_measure
    beat.default_timing_mode = default_timing_mode
    beat.metronome_enabled = metronome_enabled
    if metronome_sound:
        beat.set_metronome(metronome_sound)
