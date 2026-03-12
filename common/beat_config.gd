@tool
class_name BeatConfig
extends Node

## Configure the global beat system when this node is a child of the scene root

@export var bpm: float = 120.0
@export var beats_per_measure: int = 4
@export var default_timing_mode: TimingMode.Mode = TimingMode.Mode.MUSICAL
@export var auto_start: bool = true
@export var music: AudioStreamWAV  ## WAV only for sample-accurate timing

@export_group("Debug")
@export var start_from_beat: float = 0.0  ## Start playback from this beat (for testing)
@export var target_sequence: NodePath  ## Sequence to start (seeks animation to start_from_beat)
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
    if auto_start:
        if music:
            beat.play_music(music, start_from_beat)
        else:
            beat.start(start_from_beat)

func _apply_config():
    beat.bpm = bpm
    beat.beats_per_measure = beats_per_measure
    beat.default_timing_mode = default_timing_mode
    beat.metronome_enabled = metronome_enabled
    if metronome_sound:
        beat.set_metronome(metronome_sound)
