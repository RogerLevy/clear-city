class_name RelativeAnimationPlayer
extends AnimationPlayer

## When enabled, animated properties accumulate rather than reset on loop
@export var relative_mode: bool = false
@export var timing_mode: TimingMode.Mode = TimingMode.Mode.DEFAULT

var _track_info: Array = []
var _base_speed_scale: float = 1.0

func _get_time_scale() -> float:
    return beat.get_scale_for_mode(timing_mode)
var _anim: Animation
var _anim_name: StringName
var _original_loop_mode: int
var _offsets: Dictionary = {}  # key -> accumulated offset
var _bases: Dictionary = {}    # key -> original value
var _direct_tracks: Array = []  # tracks that need per-frame offset application

func _ready():
    animation_started.connect(_on_started)
    animation_finished.connect(_on_finished)
    # Run after AnimationPlayer's internal updates
    process_priority = 1000

func _get_zero_for_value(val):
    if val is float or val is int:
        return 0.0
    elif val is Vector2:
        return Vector2.ZERO
    elif val is Vector3:
        return Vector3.ZERO
    elif val is Color:
        return Color(0, 0, 0, 0)
    else:
        return 0.0  # fallback

func _process(_delta):
    if not relative_mode or not is_playing(): return
    # Apply accumulated offsets for direct tracks
    for track in _direct_tracks:
        var key = track.offset_key
        if _offsets.has(key):
            var current = track.node.get_indexed(track.prop)
            track.node.set_indexed(track.prop, current + _offsets[key])

func _on_started(anim_name: StringName):
    var is_restart = (_anim_name == anim_name and _anim != null)
    _anim_name = anim_name
    _anim = get_animation(anim_name)
    if not _anim: return

    if not is_restart:
        # Store original speed_scale and apply timing
        _base_speed_scale = speed_scale
        speed_scale = _base_speed_scale / _get_time_scale()

        if relative_mode:
            _original_loop_mode = _anim.loop_mode
            # Disable built-in looping - we'll handle it manually
            if _anim.loop_mode != Animation.LOOP_NONE:
                _anim.loop_mode = Animation.LOOP_NONE
            _analyze_animation()

func _on_finished(anim_name: StringName):
    if not relative_mode or not _anim: return
    if anim_name != _anim_name: return
    if _original_loop_mode == Animation.LOOP_NONE: return

    # Accumulate offsets for parent-offset tracks
    for track in _track_info:
        var key = track.offset_key
        if track.is_multiplicative:
            _offsets[key] = _offsets.get(key, track.zero_val) * track.loop_delta
            track.offset_node.set_indexed(track.offset_prop, _bases[key] * _offsets[key])
        else:
            _offsets[key] = _offsets.get(key, track.zero_val) + track.loop_delta
            track.offset_node.set_indexed(track.offset_prop, _bases[key] + _offsets[key])

    # Accumulate offsets for direct tracks (applied in _process)
    for track in _direct_tracks:
        var key = track.offset_key
        _offsets[key] = _offsets.get(key, track.zero_val) + track.loop_delta

    # Restart from beginning
    play(_anim_name)

func _analyze_animation():
    _track_info.clear()
    _direct_tracks.clear()
    if not _anim: return

    for i in _anim.get_track_count():
        var track_type = _anim.track_get_type(i)
        var path = _anim.track_get_path(i)
        var node_path = path.get_concatenated_names()
        var node = get_node_or_null(String(root_node) + "/" + node_path) if node_path else get_node_or_null(root_node)
        if not node: continue

        var prop = path.get_concatenated_subnames()
        var key_count = _anim.track_get_key_count(i)
        if key_count < 1: continue

        var start_val
        var end_val
        var loop_delta
        var offset_node: Node
        var offset_prop: NodePath
        var zero_val

        # Handle different track types
        match track_type:
            Animation.TYPE_VALUE, Animation.TYPE_BEZIER:
                if track_type == Animation.TYPE_BEZIER:
                    start_val = _anim.bezier_track_interpolate(i, 0.0)
                    end_val = _anim.bezier_track_interpolate(i, _anim.length)
                else:
                    start_val = _anim.value_track_interpolate(i, 0.0)
                    end_val = _anim.value_track_interpolate(i, _anim.length)

                loop_delta = end_val - start_val

                if node is PathFollow2D and prop == "progress":
                    var path2d = node.get_parent() as Path2D
                    if not path2d or not path2d.curve: continue
                    var pos_start = path2d.curve.sample_baked(start_val)
                    var pos_end = path2d.curve.sample_baked(end_val)
                    loop_delta = (pos_end - pos_start) * path2d.scale
                    offset_node = path2d
                    offset_prop = NodePath("position")
                    zero_val = Vector2.ZERO
                elif node is Node2D and prop == "position":
                    offset_node = node.get_parent() as Node2D
                    if not offset_node: continue
                    offset_prop = NodePath("position")
                    zero_val = Vector2.ZERO
                elif node is Node2D and prop in ["position:x", "position:y"]:
                    offset_node = node.get_parent() as Node2D
                    if not offset_node: continue
                    offset_prop = NodePath(prop)
                    zero_val = 0.0
                elif node is Node2D and prop == "rotation":
                    offset_node = node.get_parent() as Node2D
                    if not offset_node: continue
                    offset_prop = NodePath("rotation")
                    zero_val = 0.0
                elif node is Node2D and prop in ["rotation_degrees"]:
                    offset_node = node.get_parent() as Node2D
                    if not offset_node: continue
                    offset_prop = NodePath("rotation_degrees")
                    zero_val = 0.0
                elif node is CanvasItem and prop in ["modulate", "self_modulate"]:
                    offset_node = node.get_parent() as CanvasItem
                    if not offset_node: continue
                    offset_prop = NodePath(prop)
                    zero_val = Color(0, 0, 0, 0)
                else:
                    # Arbitrary property - apply offset directly each frame
                    var offset_key = str(node.get_instance_id()) + ":" + prop
                    if not _bases.has(offset_key):
                        _bases[offset_key] = node.get_indexed(NodePath(prop))
                    _direct_tracks.append({
                        "node": node,
                        "prop": NodePath(prop),
                        "offset_key": offset_key,
                        "loop_delta": loop_delta,
                        "zero_val": _get_zero_for_value(start_val)
                    })
                    continue
            _:
                continue

        var offset_key = str(offset_node.get_instance_id()) + ":" + str(offset_prop)
        if not _bases.has(offset_key):
            _bases[offset_key] = offset_node.get_indexed(offset_prop)

        _track_info.append({
            "offset_node": offset_node,
            "offset_prop": offset_prop,
            "offset_key": offset_key,
            "loop_delta": loop_delta,
            "zero_val": zero_val,
            "is_multiplicative": false
        })
