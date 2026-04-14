class_name Dsp
extends Node

## Sample-accurate audio mixer and scheduler
## Generates audio at the buffer level for precise timing

signal callback(id: int, sample_position: int)

@export var sample_rate: float = 44100.0
@export var buffer_size: int = 1024

var sample_position: int = 0
var playing: bool = false

var _player: AudioStreamPlayer
var _generator: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback

# Main music track
var _music_data: PackedVector2Array
var _music_length: int = 0

# Scheduled one-shot sounds: { trigger_sample: [{ stream, data, length, offset }] }
var _scheduled: Dictionary = {}

# Repeating sounds: [{ stream, data, length, interval, next_sample, offset }]
var _repeating: Array = []

# Scheduled callbacks: { trigger_sample: [callback_id] }
var _callbacks: Dictionary = {}

# Currently playing sounds being mixed: [{ data, length, position }]
var _active: Array = []

# Cache decoded sample data: { stream_rid: Array }
var _sample_cache: Dictionary = {}

func _ready():
    _generator = AudioStreamGenerator.new()
    _generator.mix_rate = sample_rate
    _generator.buffer_length = buffer_size / sample_rate

    _player = AudioStreamPlayer.new()
    _player.stream = _generator
    _player.bus = "BGM"
    add_child(_player)

func start(from_sample: int = 0):
    sample_position = from_sample
    _scheduled.clear()
    _callbacks.clear()
    _active.clear()
    for r in _repeating:
        r.next_sample = r.start_sample
        r.offset = 0
    _player.play()
    _playback = _player.get_stream_playback()
    playing = true

func stop():
    playing = false
    _player.stop()
    _active.clear()

func pause():
    playing = false
    _player.stop()

func resume():
    _player.play()
    _playback = _player.get_stream_playback()
    playing = true

## Set the main music track (WAV only)
## Auto-configures sample rate to match the file
func set_music(stream: AudioStreamWAV):
    # Match sample rate to the music file
    if stream.mix_rate != int(sample_rate):
        sample_rate = stream.mix_rate
        _generator.mix_rate = sample_rate
    _music_data = _get_sample_data(stream)
    _music_length = _music_data.size()

## Clear the music track
func clear_music():
    _music_data = PackedVector2Array()
    _music_length = 0

## Schedule a sound to play at exact sample position
func schedule(stream: AudioStream, at_sample: int, volume: float = 1.0):
    var data := _get_sample_data(stream)
    if data.is_empty(): return

    var entry = { "data": data, "length": data.size(), "volume": volume }
    if not _scheduled.has(at_sample):
        _scheduled[at_sample] = []
    _scheduled[at_sample].append(entry)

## Schedule a sound to play at exact time (seconds)
func schedule_at(stream: AudioStream, at_time: float):
    schedule(stream, time_to_samples(at_time))

## Schedule a repeating sound every N samples
func schedule_repeat(stream: AudioStream, interval_samples: int, start_sample: int = 0):
    var data := _get_sample_data(stream)
    if data.is_empty(): return

    _repeating.append({
        "data": data,
        "length": data.size(),
        "interval": interval_samples,
        "start_sample": start_sample,
        "next_sample": start_sample,
        "offset": 0
    })

## Schedule repeating sound by time interval
func schedule_repeat_at(stream: AudioStream, interval_time: float, start_time: float = 0.0):
    schedule_repeat(stream, time_to_samples(interval_time), time_to_samples(start_time))

## Schedule a callback signal at exact sample position
func schedule_callback(at_sample: int, id: int = 0):
    if not _callbacks.has(at_sample):
        _callbacks[at_sample] = []
    _callbacks[at_sample].append(id)

## Schedule callback at exact time
func schedule_callback_at(at_time: float, id: int = 0):
    schedule_callback(time_to_samples(at_time), id)

## Clear all scheduled sounds (not currently playing ones)
func clear_scheduled():
    _scheduled.clear()

## Clear repeating sounds
func clear_repeating():
    _repeating.clear()

## Clear callbacks
func clear_callbacks():
    _callbacks.clear()

func time_to_samples(time: float) -> int:
    return int(time * sample_rate)

func samples_to_time(samples: int) -> float:
    return samples / sample_rate

func _process(_delta):
    if not playing or not _playback: return
    _fill_buffer()

func _fill_buffer():
    var frames = _playback.get_frames_available()

    for i in frames:
        var sample = Vector2.ZERO

        # Mix main music track
        if _music_length > 0 and sample_position < _music_length:
            sample += _music_data[sample_position]

        # Check for scheduled one-shots at this sample
        if _scheduled.has(sample_position):
            for entry in _scheduled[sample_position]:
                _active.append({ "data": entry.data, "length": entry.length, "position": 0, "volume": entry.volume })
            _scheduled.erase(sample_position)

        # Check for repeating sounds
        for r in _repeating:
            if sample_position >= r.next_sample:
                _active.append({ "data": r.data, "length": r.length, "position": 0, "volume": r.get("volume", 1.0) })
                r.next_sample += r.interval

        # Check for callbacks
        if _callbacks.has(sample_position):
            for id in _callbacks[sample_position]:
                callback.emit(id, sample_position)
            _callbacks.erase(sample_position)

        # Mix all active sounds
        var finished = []
        for j in _active.size():
            var a = _active[j]
            if a.position < a.length:
                sample += a.data[a.position] * a.volume
                a.position += 1
            else:
                finished.append(j)

        # Remove finished sounds (reverse order)
        for j in range(finished.size() - 1, -1, -1):
            _active.remove_at(finished[j])

        _playback.push_frame(sample)
        sample_position += 1

## Extract sample data from an AudioStream as PackedVector2Array (stereo)
## Caches decoded data for reuse
func _get_sample_data(stream: AudioStream) -> PackedVector2Array:
    var key = stream.resource_path if stream.resource_path else str(stream.get_instance_id())
    if _sample_cache.has(key):
        return _sample_cache[key]

    var data := PackedVector2Array()
    if stream is AudioStreamWAV:
        data = _decode_wav(stream)
    elif stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
        push_warning("Dsp: OGG/MP3 streams not yet supported, use WAV")

    if not data.is_empty():
        _sample_cache[key] = data
    return data

func _decode_wav(wav: AudioStreamWAV) -> PackedVector2Array:
    var data: PackedByteArray = wav.data
    var format: int = wav.format
    var stereo: bool = wav.stereo

    # Calculate number of samples and bytes per sample
    var bytes_per_sample: int
    match format:
        AudioStreamWAV.FORMAT_8_BITS:
            bytes_per_sample = 2 if stereo else 1
        AudioStreamWAV.FORMAT_16_BITS:
            bytes_per_sample = 4 if stereo else 2
        _:
            push_warning("Dsp: Unsupported WAV format: ", format)
            return PackedVector2Array()

    var num_samples: int = data.size() / bytes_per_sample
    var samples := PackedVector2Array()
    samples.resize(num_samples)

    # Fast path for 16-bit stereo (most common)
    if format == AudioStreamWAV.FORMAT_16_BITS and stereo:
        for s in num_samples:
            var i: int = s * 4
            var left: float = float(data.decode_s16(i)) / 32768.0
            var right: float = float(data.decode_s16(i + 2)) / 32768.0
            samples[s] = Vector2(left, right)
    elif format == AudioStreamWAV.FORMAT_16_BITS:  # mono
        for s in num_samples:
            var i: int = s * 2
            var val: float = float(data.decode_s16(i)) / 32768.0
            samples[s] = Vector2(val, val)
    elif format == AudioStreamWAV.FORMAT_8_BITS and stereo:
        for s in num_samples:
            var i: int = s * 2
            var left: float = (data[i] - 128) / 128.0
            var right: float = (data[i + 1] - 128) / 128.0
            samples[s] = Vector2(left, right)
    else:  # 8-bit mono
        for s in num_samples:
            var val: float = (data[s] - 128) / 128.0
            samples[s] = Vector2(val, val)

    return samples
