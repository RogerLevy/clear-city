class_name SineMovement
extends Node

@export var enabled:bool = true
@export_range(0.01, 5.0) var x_period: float = 2.0
@export_range(0.01, 5.0) var y_period: float = 2.0
@export_range(0.0, 360.0, 1.0) var x_phase: float = 0.0
@export_range(0.0, 360.0, 1.0) var y_phase: float = 0.0
@export_range(0.0, 240.0, 1.0) var x_pixels: float = 0.0
@export_range(0.0, 160.0, 1.0) var y_pixels: float = 100.0
@export_range(-4.0, 4.0) var speed: float = 1.0
@export_range(-2.0, 2.0) var amount: float = 1.0

var x_angle: float = 0.0
var y_angle: float = 0.0
var _previous_offset: Vector2 = Vector2.ZERO
var _baseline_offset: Vector2 = Vector2.ZERO
var _prev_x_pixels: float
var _prev_y_pixels: float
var _prev_amount: float

func _ready():
    add_to_group("sine_movements")
    _prev_x_pixels = x_pixels
    _prev_y_pixels = y_pixels
    _prev_amount = amount

## Call this when the parent is teleported to prevent jump artifacts
func reset_tracking():
    _previous_offset = Vector2(
        sin(x_angle + deg_to_rad(x_phase)) * x_pixels * amount,
        sin(y_angle + deg_to_rad(y_phase)) * y_pixels * amount
    ) + _baseline_offset

func _process(delta: float):
    if not enabled: return
    
    # Check if amplitude parameters changed
    if x_pixels != _prev_x_pixels or y_pixels != _prev_y_pixels or amount != _prev_amount:
        # Calculate current offset with old values
        var old_offset = Vector2(
            sin(x_angle + deg_to_rad(x_phase)) * _prev_x_pixels * _prev_amount,
            sin(y_angle + deg_to_rad(y_phase)) * _prev_y_pixels * _prev_amount
        )
        
        # Calculate current offset with new values
        var new_offset = Vector2(
            sin(x_angle + deg_to_rad(x_phase)) * x_pixels * amount,
            sin(y_angle + deg_to_rad(y_phase)) * y_pixels * amount
        )
        
        # Adjust baseline to maintain visual continuity
        var baseline_adjustment = old_offset - new_offset
        _baseline_offset += baseline_adjustment
        
        # Also update _previous_offset to prevent jump in offset_delta calculation
        _previous_offset += baseline_adjustment
        
        # Update stored previous values
        _prev_x_pixels = x_pixels
        _prev_y_pixels = y_pixels
        _prev_amount = amount
    
    x_angle += delta * speed * TAU / x_period
    y_angle += delta * speed * TAU / y_period
    
    var current_offset = Vector2(
        sin(x_angle + deg_to_rad(x_phase)) * x_pixels * amount,
        sin(y_angle + deg_to_rad(y_phase)) * y_pixels * amount
    ) + _baseline_offset
    
    var offset_delta = current_offset - _previous_offset
    get_parent().position += offset_delta
    
    _previous_offset = current_offset
