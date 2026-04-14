@tool
extends Sequence
class_name BurstSequence

@export var scene:PackedScene

@export var count:int = 4
@export var count_range:int = 0   # randomize the count by this amount (gets added to count)
@export var force:float = 100
@export var force_range:float = 0  # randomizes force (gets added to force)
@export var angle_offset:float = 0
@export var angle_spread:float = 360
@export var time_stagger:float = 0  # respects musical flag
@export var time_stagger_frames:int = 0
@export var random_angles:bool = false  # false = even distribution, true = random distribution
@export var infinite:bool = false

var _spawns: Array = []
var _spawn_index: int = 0
var _frame_wait: int = 0
var _time_wait: float = 0.0
var _elapsed: float = 0.0

func start():
    # Prevent auto-complete from next() since we have no child sequences
    # But allow duration to control completion if set
    if duration < 0:
        open_ended = true
    super.start()
    _setup_burst()

func _setup_burst():
    var infinite = self.infinite
    assert(not infinite or time_stagger > 0 or time_stagger_frames > 0, "BurstSequence: infinite requires time_stagger or time_stagger_frames")

    var final_count = count + randi_range(0, count_range)
    var angle_step = angle_spread / final_count if not random_angles and final_count > 0 else 0
    var start_angle = angle_offset
    var prev_angle: float = INF

    for i in final_count:
        var angle: float
        if random_angles:
            for attempt in 10:
                angle = angle_offset + randf_range(-angle_spread * 0.5, angle_spread * 0.5)
                if prev_angle == INF or absf(angle_difference(deg_to_rad(angle), deg_to_rad(prev_angle))) >= deg_to_rad(45):
                    break
        else:
            angle = start_angle + angle_step * i if final_count > 1 else angle_offset
        prev_angle = angle
        var final_force = (force + randf_range(0, force_range)) * g.burst_force_factor
        _spawns.append(Vector2.from_angle(deg_to_rad(angle)) * final_force)

    if _spawns.size() > 0:
        _spawn_instance(_spawns[0])
        _spawn_index = 1
        _frame_wait = time_stagger_frames
        _time_wait = time_stagger * _get_time_scale()
        _elapsed = 0.0

func _physics_process(delta):
    if frozen or not running: return
    if _spawns.is_empty(): return

    _elapsed += delta
    # Don't spawn if duration is ending this frame
    if _duration_override and _elapsed >= duration * _get_time_scale():
        return

    var infinite = self.infinite
    if not infinite and _spawn_index >= _spawns.size():
        return

    if time_stagger_frames > 0:
        _frame_wait -= 1
        if _frame_wait <= 0:
            _spawn_instance(_spawns[_spawn_index % _spawns.size()])
            _spawn_index += 1
            _frame_wait = time_stagger_frames
            if not infinite and _spawn_index >= _spawns.size():
                complete()
    elif time_stagger > 0:
        _time_wait -= delta
        if _time_wait <= 0:
            _spawn_instance(_spawns[_spawn_index % _spawns.size()])
            _spawn_index += 1
            _time_wait += time_stagger * _get_time_scale()
            if not infinite and _spawn_index >= _spawns.size():
                complete()
    else:
        while _spawn_index < _spawns.size():
            _spawn_instance(_spawns[_spawn_index])
            _spawn_index += 1
        complete()

func _spawn_instance(vel: Vector2):
    if not scene:
        return
    var instance:Node2D = scene.instantiate()
    instance.transform = get_global_transform()
    g.playfield.add_child.call_deferred(instance)
    _apply_velocity.call_deferred(instance, vel)

func _apply_velocity(instance: Node, vel: Vector2):
    if "velocity" in instance:
        instance.velocity = vel
    elif instance is RigidBody2D:
        instance.linear_velocity = vel
