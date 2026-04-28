@tool
extends EditorInspectorPlugin

func _can_handle(object: Object) -> bool:
    var script = object.get_script()
    while script:
        if script.get_global_name() == "PathMotion":
            return true
        script = script.get_base_script()
    return false

func _parse_begin(object: Object) -> void:
    var preview = _CurvePreview.new()
    preview.setup(object)
    add_custom_control(preview)


class _CurvePreview extends Control:
    var _obj: Object

    func setup(obj: Object) -> void:
        _obj = obj
        custom_minimum_size = Vector2(0, 160)
        set_process(true)

    func _process(_delta: float) -> void:
        queue_redraw()

    func _draw() -> void:
        if not _obj:
            return

        var w := size.x
        var h := size.y
        var pad := 6.0
        var iw := w - pad * 2
        var ih := h - pad * 2

        # Sample the curve
        const STEPS := 256
        var samples := PackedFloat32Array()
        samples.resize(STEPS + 1)
        var lo := 0.0
        var hi := 1.0
        for i in range(STEPS + 1):
            var t := float(i) / STEPS
            var et: float = _obj._apply_ease(t)
            samples[i] = et
            if et < lo: lo = et
            if et > hi: hi = et

        # Add a little headroom above/below the range
        var span := hi - lo
        var headroom := maxf(span * 0.15, 0.05)
        lo -= headroom
        hi += headroom
        span = hi - lo

        # Background
        var bg := Color(0.08, 0.08, 0.08, 0.85)
        draw_rect(Rect2(pad, pad, iw, ih), bg)

        # Grid lines at output 0 and 1
        var grid_col := Color(0.25, 0.25, 0.25)
        for gv in [0.0, 1.0]:
            var gy := _vy(gv, lo, span, pad, ih)
            draw_line(Vector2(pad, gy), Vector2(w - pad, gy), grid_col, 1.0)

        # Diagonal reference (linear, no easing)
        var ref_col := Color(0.25, 0.35, 0.45)
        draw_line(
            Vector2(pad, _vy(0.0, lo, span, pad, ih)),
            Vector2(w - pad, _vy(1.0, lo, span, pad, ih)),
            ref_col, 1.0
        )

        # Ease curve
        var points := PackedVector2Array()
        points.resize(STEPS + 1)
        for i in range(STEPS + 1):
            var t := float(i) / STEPS
            var x := pad + t * iw
            var y := _vy(samples[i], lo, span, pad, ih)
            points[i] = Vector2(x, y)
        draw_polyline(points, Color(0.35, 0.75, 1.0), 1.5, true)

    # Map a value in [lo, lo+span] to a y pixel (1.0=top, 0.0=bottom)
    func _vy(v: float, lo: float, span: float, pad: float, ih: float) -> float:
        return pad + (1.0 - (v - lo) / span) * ih
