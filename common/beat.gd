@tool
extends Node

## Global beat/tempo system - autoload as "beat"
## Syncs game timing to a music track's tempo with sample-accurate precision
##
## SETUP:
##   1. Add beat.gd as autoload named "beat" in Project Settings
##   2. Add a BeatConfig node as child of your scene root to configure per-scene
##
## BASIC USAGE:
##   beat.start()                          # Start without music (polling mode)
##   beat.play_music(preload("res://music.wav"))  # Start with music (WAV only, sample-accurate)
##   beat.set_metronome(preload("res://click.wav"))  # Set metronome sound
##   beat.metronome_enabled = true         # Enable metronome
##   beat.stop()                           # Stop and reset
##
## TIMING:
##   await beat.wait(4)                    # Wait 4 beats
##   await beat.wait_next_beat()           # Wait until next beat
##   await beat.wait_until(16)             # Wait until beat 16
##   var t = beat.every(1)                 # Timer that fires every beat
##
## SIGNALS:
##   beat.beat_hit.connect(func(b): ...)   # Called each beat
##   beat.measure_hit.connect(func(m): ...)# Called each measure
##
## PROPERTIES:
##   beat.bpm                              # Beats per minute
##   beat.current_beat                     # Current beat (float)
##   beat.beat_number                      # Current beat (int)
##   beat.beat_progress                    # Progress within beat (0.0-1.0)
##   beat.position                         # Playback position in seconds
##   beat.scale                            # Seconds per beat (60/bpm)
##
## TIMING MODES (for Sequence, RelativeAnimationPlayer):
##   TimingMode.Mode.NORMAL                # Real-time seconds
##   TimingMode.Mode.MUSICAL               # Beat-scaled (1 unit = 1 beat)
##   TimingMode.Mode.DEFAULT               # Use beat.default_timing_mode

signal beat_hit(beat_number: int)
signal measure_hit(measure_number: int)
signal bpm_changed(new_bpm: float)
signal default_timing_mode_changed(mode: TimingMode.Mode)
signal sequence_signal(signal_name: String)  ## Global signal for Sequence start_mode=ON_SIGNAL

## Global default timing mode (NORMAL or MUSICAL) - DEFAULT resolves to this
@export var default_timing_mode: TimingMode.Mode = TimingMode.Mode.NORMAL:
    set(value):
        if value == TimingMode.Mode.DEFAULT:
            value = TimingMode.Mode.NORMAL  # DEFAULT can't be the default
        default_timing_mode = value
        default_timing_mode_changed.emit(value)

## Resolve a timing mode (converts DEFAULT to the global setting)
func resolve_timing_mode(mode: TimingMode.Mode) -> TimingMode.Mode:
    return default_timing_mode if mode == TimingMode.Mode.DEFAULT else mode

## Get scale factor for a timing mode (1.0 for NORMAL, beat.scale for MUSICAL)
func get_scale_for_mode(mode: TimingMode.Mode) -> float:
    return scale if resolve_timing_mode(mode) == TimingMode.Mode.MUSICAL else 1.0

@export var bpm: float = 120.0:
    set(value):
        bpm = value
        _update_scale()
        bpm_changed.emit(bpm)

@export var beats_per_measure: int = 4

var scale: float = 1.0  # duration multiplier: 1 beat-second = scale real-seconds
var playing: bool = false
var started_from_beat: float = 0.0  # The beat we started from (for Sequence to check)
var target_sequence: Node  # Sequence that should start from started_from_beat
var _start_time: float = 0.0
var _pause_position: float = 0.0
var _last_beat: int = -1
var _last_measure: int = -1

var metronome_enabled: bool = false
var _metronome_stream: AudioStreamWAV
var _dsp: Dsp
var _using_dsp: bool = false  # true when playing via Dsp (WAV music)

func _ready():
    if Engine.is_editor_hint(): return

    _setup_dsp()
    _update_scale()
    process_mode = Node.PROCESS_MODE_ALWAYS

func _setup_dsp():
    _dsp = Dsp.new()
    add_child(_dsp)
    _dsp.callback.connect(_on_dsp_callback)

func _on_dsp_callback(id: int, _sample: int):
    # id encodes beat number
    var b = id
    beat_hit.emit(b)
    if b % beats_per_measure == 0:
        measure_hit.emit(b / beats_per_measure)

## Set metronome sound (WAV only for sample-accurate timing)
func set_metronome(stream: AudioStreamWAV):
    _metronome_stream = stream

func _update_scale():
    scale = 60.0 / bpm

## Current playback position in seconds
var position: float:
    get:
        if _using_dsp:
            return _dsp.samples_to_time(_dsp.sample_position)
        elif playing:
            return Time.get_ticks_msec() / 1000.0 - _start_time + _pause_position
        return _pause_position

## Current beat number (fractional)
var current_beat: float:
    get:
        return position / scale

## Current whole beat number
var beat_number: int:
    get:
        return int(current_beat)

## Current measure number
var measure_number: int:
    get:
        return beat_number / beats_per_measure

## Progress within current beat (0.0 to 1.0)
var beat_progress: float:
    get:
        return fmod(current_beat, 1.0)

func _physics_process(_delta):
    if Engine.is_editor_hint() or not playing or _using_dsp: return

    # Fallback polling for non-DSP mode
    var b = beat_number
    if b != _last_beat:
        _last_beat = b
        beat_hit.emit(b)

        var m = measure_number
        if m != _last_measure:
            _last_measure = m
            measure_hit.emit(m)

## Start playing a music track with sample-accurate timing (WAV only)
func play_music(stream: AudioStreamWAV, from_beat: float = 0.0):
    started_from_beat = from_beat
    _dsp.set_music(stream)
    var from_sample := int(from_beat * scale * _dsp.sample_rate)
    _dsp.start(from_sample)  # Start from the correct sample
    _schedule_beats_and_metronome(from_beat)
    _using_dsp = true
    _last_beat = int(from_beat) - 1
    _last_measure = _last_beat / beats_per_measure
    playing = true
    get_tree().paused = false

## Start the beat system without music
## Uses DSP if metronome enabled (sample-accurate), otherwise polling
func start(from_beat: float = 0.0):
    started_from_beat = from_beat
    _last_beat = int(from_beat) - 1
    _last_measure = _last_beat / beats_per_measure
    playing = true
    get_tree().paused = false

    if metronome_enabled and _metronome_stream:
        # Use DSP for sample-accurate metronome
        _dsp.clear_music()
        var from_sample := int(from_beat * scale * _dsp.sample_rate)
        _dsp.start(from_sample)
        _schedule_beats_and_metronome(from_beat)
        _using_dsp = true
    else:
        # Polling mode
        _using_dsp = false
        _pause_position = from_beat * scale
        _start_time = Time.get_ticks_msec() / 1000.0

func _schedule_beats_and_metronome(from_beat: float = 0.0):
    print_debug( metronome_enabled, _metronome_stream )
    print_debug("bpm=", bpm, " scale=", scale, " sample_rate=", _dsp.sample_rate)

    _dsp.clear_callbacks()
    _dsp.clear_repeating()
    _dsp.clear_scheduled()

    # Compute sample position directly: beat * 60 * sample_rate / bpm
    # Minimizes floating point error by avoiding intermediate scale variable
    var samples_per_minute: float = _dsp.sample_rate * 60.0
    var max_beats = 1000  # ~2 min at 120bpm
    var first_beat: int = ceili(from_beat)  # Next whole beat at or after from_beat
    for b in max_beats:
        var beat_num: int = first_beat + b
        var sample_pos: int = int(float(beat_num) * samples_per_minute / bpm)
        _dsp.schedule_callback(sample_pos, beat_num)
        # Schedule metronome: full volume on downbeat, 50% on other beats
        if metronome_enabled and _metronome_stream:
            var vol: float = 1.0 if beat_num % beats_per_measure == 0 else 0.45
            _dsp.schedule(_metronome_stream, sample_pos, vol)

## Pause both music and game
func pause():
    if not playing: return
    playing = false
    _pause_position = position
    if _using_dsp:
        _dsp.pause()
    get_tree().paused = true

## Resume music and game
func resume():
    if playing: return
    if _using_dsp:
        _dsp.resume()
    else:
        _start_time = Time.get_ticks_msec() / 1000.0
    playing = true
    get_tree().paused = false

## Toggle pause state
func toggle_pause():
    if playing:
        pause()
    else:
        resume()

## Stop music and reset
func stop():
    playing = false
    _pause_position = 0.0
    _last_beat = -1
    _last_measure = -1
    if _using_dsp:
        _dsp.stop()
    _using_dsp = false
    get_tree().paused = false

# ============ Timing helpers ============

## Convert beats to real seconds
func secs(beats: float) -> float:
    return beats * scale

## Convert real seconds to beats
func beats(seconds: float) -> float:
    return seconds / scale

## Await for a number of beats
func wait(beat_count: float) -> Signal:
    return get_tree().create_timer(secs(beat_count), true, false, true).timeout

## Await until a specific beat number
func wait_until(target_beat: float) -> Signal:
    var beats_to_wait = target_beat - current_beat
    if beats_to_wait <= 0:
        # Already passed - return immediately
        return get_tree().create_timer(0).timeout
    return wait(beats_to_wait)

## Await until the next whole beat
func wait_next_beat() -> Signal:
    return wait_until(float(beat_number + 1))

## Await until the next measure
func wait_next_measure() -> Signal:
    return wait_until(float((measure_number + 1) * beats_per_measure))

## Get a timer that fires every N beats
func every(beat_interval: float) -> Timer:
    var timer = Timer.new()
    timer.wait_time = secs(beat_interval)
    timer.autostart = true
    add_child(timer)
    return timer

## Play a sound immediately (sample-accurate)
func play_now(stream: AudioStreamWAV, volume: float = 1.0):
    if stream and _dsp:
        _dsp.schedule(stream, _dsp.sample_position, volume)

## Pre-decode an audio stream (call during loading screens to avoid stutter)
func warmup_audio(stream: AudioStreamWAV):
    if stream and _dsp:
        _dsp._get_sample_data(stream)
