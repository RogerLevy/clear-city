@tool
extends Sequence
class_name PathMotion

@export var target: Node2D
@export_range(0.0, 1.0) var ease_in: float = 0.0  ## Ease-in strength (0 = linear start)
@export_enum("Linear:0", "Sine:1", "Quad:4", "Expo:5", "Circ:8", "Elastic:6", "Back:10", "Bounce:9")
var ease_in_curve: int = Tween.TRANS_QUAD:
    set(v):
        ease_in_curve = v
        notify_property_list_changed()
@export_range(0.0, 8.0) var ease_in_param: float = 1.0  ## Curve modifier: exponent, intensity, frequency, or bounce count
@export_range(0.0, 1.0) var ease_out: float = 0.0  ## Ease-out strength (0 = linear end)
@export_enum("Linear:0", "Sine:1", "Quad:4", "Expo:5", "Circ:8", "Elastic:6", "Back:10", "Bounce:9")
var ease_out_curve: int = Tween.TRANS_QUAD:
    set(v):
        ease_out_curve = v
        notify_property_list_changed()
@export_range(0.0, 8.0) var ease_out_param: float = 1.0  ## Curve modifier: exponent, intensity, frequency, or bounce count

var _path: Path2D
var _tween: Tween
var _curve_length: float
var _end_tangent_local: Vector2  ## Tangent at end, in path-local coords
var _tween_speed_scale: float = 1.0  ## Tracked speed scale for slowdown

func _curve_uses_param(curve: int) -> bool:
    match curve:
        Tween.TRANS_LINEAR, Tween.TRANS_SINE, Tween.TRANS_CIRC:
            return false
        _:
            return true

func _validate_property(property: Dictionary) -> void:
    match property.name:
        "ease_in_param":
            if not _curve_uses_param(ease_in_curve):
                property["usage"] = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY
        "ease_out_param":
            if not _curve_uses_param(ease_out_curve):
                property["usage"] = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY

func _ready():
    super._ready()
    for child in get_children():
        if child is Path2D:
            _path = child
            break

func start():
    super.start()
    if not _path or not target:
        auto_complete()
        return
    if duration <= 0:
        push_warning("PathMotion requires duration > 0")
        auto_complete()
        return

    var curve: Curve2D = _path.curve
    if not curve or curve.point_count < 2:
        auto_complete()
        return

    _curve_length = curve.get_baked_length()
    # Cache tangent in local coords (doesn't change with parent movement)
    var end_local = curve.sample_baked(_curve_length)
    var near_end_local = curve.sample_baked(_curve_length * 0.99)
    _end_tangent_local = (end_local - near_end_local).normalized()
    # Position at start
    target.global_position = _path.to_global(curve.get_point_position(0))

    _tween = create_tween()
    _tween_speed_scale = 1.0 / _get_time_scale()
    _tween.set_speed_scale(_tween_speed_scale)

    # Custom ease using method call
    _tween.tween_method(_sample_path, 0.0, 1.0, duration)
    _tween.finished.connect(_on_tween_finished)

func _sample_path(t: float):
    if not target or not _path:
        return

    var curve: Curve2D = _path.curve
    var eased_t = _apply_ease(t)

    # Compute position fresh each frame (handles moving parents)
    if eased_t > 1.0:
        # Extrapolate beyond end
        var end_pos = _path.to_global(curve.sample_baked(_curve_length))
        var end_tangent = _path.to_global(_end_tangent_local) - _path.to_global(Vector2.ZERO)
        var overshoot = (eased_t - 1.0) * _curve_length
        target.global_position = end_pos + end_tangent * overshoot
    elif eased_t < 0.0:
        # Extrapolate before start
        var start_pos = _path.to_global(curve.get_point_position(0))
        var near_start = _path.to_global(curve.sample_baked(_curve_length * 0.01))
        var start_tangent = (near_start - start_pos).normalized()
        target.global_position = start_pos + start_tangent * eased_t * _curve_length
    else:
        # Normal path sampling
        target.global_position = _path.to_global(curve.sample_baked(eased_t * _curve_length))

func _apply_ease(t: float) -> float:
    if ease_in <= 0 and ease_out <= 0:
        return t

    var result = t

    # Apply ease-in (slow start)
    if ease_in > 0:
        var eased = _ease_in(t, ease_in_curve, ease_in_param)
        result = lerp(t, eased, ease_in)

    # Apply ease-out (slow end) - transform: 1 - f(1 - t)
    if ease_out > 0:
        var eased = _ease_out(result, ease_out_curve, ease_out_param)
        result = lerp(result, eased, ease_out)

    return result

func _ease_in(t: float, curve: int, param: float) -> float:
    return _raw_ease(t, curve, param)

func _ease_out(t: float, curve: int, param: float) -> float:
    return 1.0 - _raw_ease(1.0 - t, curve, param)

func _raw_ease(t: float, curve: int, param: float) -> float:
    match curve:
        Tween.TRANS_LINEAR:
            return t
        Tween.TRANS_QUAD:
            return pow(t, 2.0 * param)
        Tween.TRANS_SINE:
            return 1.0 - cos(t * PI * 0.5)
        Tween.TRANS_EXPO:
            if t == 0.0: return 0.0
            if t == 1.0: return 1.0
            var k := param * 10.0
            if k < 1e-6: return t
            var lo := pow(2.0, -k)
            return (pow(2.0, k * (t - 1.0)) - lo) / (1.0 - lo)
        Tween.TRANS_CIRC:
            return 1.0 - sqrt(1.0 - t * t)
        Tween.TRANS_ELASTIC:
            # param controls oscillation frequency (default ~3 oscillations)
            var freq = 3.0 * param
            return pow(2, 10 * (t - 1)) * sin((t - 1) * PI * 2 * freq)
        Tween.TRANS_BACK:
            # param controls exponent (default 2)
            var exp = param if param != 1.0 else 2.0
            return pow(t, exp) * (2.70158 * t - 1.70158)
        Tween.TRANS_BOUNCE:
            # param controls number of bounces (default 4)
            return 1.0 - _bounce_out(1.0 - t, param)
        _:
            return t

func _bounce_out(t: float, param: float) -> float:
    var n := maxi(1, roundi(4.0 * param))
    # r_t: time decay ratio between successive bounce arcs.
    # Chosen so the last arc always has the same relative amplitude as Penner n=4.
    # At n=4 this is exactly 0.5, so n<=4 matches the original Penner formula.
    var r_t := pow(0.25, 1.0 / maxf(float(n) - 2.0, 1.0))
    var d := 1.0 + (1.0 - pow(r_t, n - 1)) / (1.0 - r_t) if n > 1 else 1.0
    var A := d * d

    if t < 1.0 / d:
        return A * t * t

    var pos := 1.0 / d
    var w := 1.0 / d
    for i in range(1, n):
        var next_pos := pos + w
        if t < next_pos or i == n - 1:
            var t2 := t - (pos + w * 0.5)
            var floor_h := 1.0 - A * pow(w * 0.5, 2.0)
            return A * t2 * t2 + floor_h
        pos = next_pos
        w *= r_t

    return 1.0

func _on_tween_finished():
    auto_complete()

func stop():
    super.stop()
    if _tween:
        _tween.kill()
        _tween = null
