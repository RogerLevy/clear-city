@tool
extends Sequence
class_name PathMotion

@export var target: Node2D
@export var ease_in: float = 0.0  ## Ease-in strength (0 = linear start)
@export var ease_in_curve: Tween.TransitionType = Tween.TRANS_QUAD:
    set(v):
        ease_in_curve = v
        notify_property_list_changed()
@export var ease_in_param: float = 1.0  ## Curve modifier: exponent, intensity, frequency, or bounce count
@export var ease_out: float = 0.0  ## Ease-out strength (0 = linear end)
@export var ease_out_curve: Tween.TransitionType = Tween.TRANS_QUAD:
    set(v):
        ease_out_curve = v
        notify_property_list_changed()
@export var ease_out_param: float = 1.0  ## Curve modifier: exponent, intensity, frequency, or bounce count

var _path: Path2D
var _tween: Tween
var _curve_length: float
var _end_tangent_local: Vector2  ## Tangent at end, in path-local coords

func _curve_uses_param(curve: Tween.TransitionType) -> bool:
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
    _tween.set_speed_scale(1.0 / _get_time_scale())

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

func _ease_in(t: float, curve: Tween.TransitionType, param: float) -> float:
    return _raw_ease(t, curve, param)

func _ease_out(t: float, curve: Tween.TransitionType, param: float) -> float:
    return 1.0 - _raw_ease(1.0 - t, curve, param)

func _raw_ease(t: float, curve: Tween.TransitionType, param: float) -> float:
    match curve:
        Tween.TRANS_LINEAR:
            return t
        Tween.TRANS_QUAD, Tween.TRANS_CUBIC, Tween.TRANS_QUART, Tween.TRANS_QUINT:
            # param IS the exponent (1.0 uses curve default: 2/3/4/5)
            var exp = param if param != 1.0 else _default_exponent(curve)
            return pow(t, exp)
        Tween.TRANS_SINE:
            return 1.0 - cos(t * PI * 0.5)
        Tween.TRANS_EXPO:
            # param controls intensity (default 10)
            var intensity = param * 10.0
            return 0.0 if t == 0 else pow(2, intensity * (t - 1))
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

func _default_exponent(curve: Tween.TransitionType) -> float:
    match curve:
        Tween.TRANS_QUAD: return 2.0
        Tween.TRANS_CUBIC: return 3.0
        Tween.TRANS_QUART: return 4.0
        Tween.TRANS_QUINT: return 5.0
        _: return 2.0

func _bounce_out(t: float, param: float) -> float:
    # param controls number of bounces (1.0 = 4 bounces default)
    var bounces = int(4 * param)
    if bounces < 1:
        bounces = 1

    # Standard 4-bounce implementation when param=1
    if bounces == 4:
        if t < 1.0 / 2.75:
            return 7.5625 * t * t
        elif t < 2.0 / 2.75:
            var t2 = t - 1.5 / 2.75
            return 7.5625 * t2 * t2 + 0.75
        elif t < 2.5 / 2.75:
            var t2 = t - 2.25 / 2.75
            return 7.5625 * t2 * t2 + 0.9375
        else:
            var t2 = t - 2.625 / 2.75
            return 7.5625 * t2 * t2 + 0.984375

    # Generalized bounce with variable count
    var decay = 2.75 / bounces
    var amplitude = 7.5625
    for i in bounces:
        var threshold = (i + 1.0) / (bounces + 0.75)
        if t < threshold:
            var offset = (i + 0.5) / (bounces + 0.75) if i > 0 else 0.0
            var t2 = t - offset
            var height = 1.0 - pow(0.5, i)
            return amplitude * t2 * t2 + height
    return 1.0

func _on_tween_finished():
    auto_complete()

func stop():
    super.stop()
    if _tween:
        _tween.kill()
        _tween = null
