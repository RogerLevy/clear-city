@tool
@icon("res://common/sequence.svg")
extends Sequence
class_name ShootAtPlayer

enum FireMode {
    INDIVIDUAL,   ## Each instance fires independently
    ROUND_ROBIN,  ## Instances take turns firing sequentially
    RANDOM,       ## A random instance fires each interval
}

## Global registry for distributed firing modes
static var _registry: Array[ShootAtPlayer] = []
static var _next_slot: int = 0  ## Next slot to assign
static var _current_slot: int = 0  ## Next slot to fire in round-robin
static var _chosen_slots: Array[int] = []  ## Slots chosen for current beat
static var _last_distributed_beat: int = -1

func _init():
    start_mode = StartMode.ON_PARENT
    open_ended = true

const RingBurst = preload("res://darkblue/effects/ring_burst.gd")

@export var bullet_scene: PackedScene = preload("res://darkblue/actors/bullet_orb.tscn")
@export var beat_interval: float = 8.0
@export var time_offset: float = 0.0  ## Beat offset for firing alignment
@export var bullet_speed: float = 0.9  # pixels per frame
@export var sync_to_beat: bool = false  ## Sync all shooters with same interval to fire together
@export var fire_mode: FireMode = FireMode.INDIVIDUAL
@export var fire_count: int = 1  ## How many instances fire per interval (distributed modes only)

var _started: bool = false
var _last_shot_beat: int = -1
var _start_beat: int = 0
var _slot: int = -1  ## Slot number for distributed firing

func _is_on_screen() -> bool:
    var pos = global_position
    var screen_size = get_viewport().get_visible_rect().size
    return pos.x >= 0 and pos.x <= screen_size.x and pos.y >= 0 and pos.y <= screen_size.y

func start():
    super.start()
    _started = true
    _start_beat = int(beat.beat_number)
    _last_shot_beat = -1
    if fire_mode != FireMode.INDIVIDUAL and self not in _registry:
        _slot = _next_slot
        _next_slot += 1
        _registry.append(self)
        tree_exiting.connect(_unregister)

func _unregister():
    _registry.erase(self)

func _physics_process(_delta):
    if Engine.is_editor_hint(): return
    if not _started or not running: return
    if not beat.playing: return
    if not is_visible_in_tree(): return
    if not _is_on_screen(): return

    var current_beat = int(beat.beat_number)

    # Distributed modes override normal firing
    if fire_mode != FireMode.INDIVIDUAL:
        if _is_chosen_to_fire(current_beat):
            _shoot()
        return

    # Individual mode - normal firing logic
    var fire_beat: int
    var beats_since_start = current_beat - _start_beat

    if sync_to_beat:
        # Use modulo on global beat offset by time_offset
        var remainder = (current_beat - int(time_offset)) % int(beat_interval)
        if remainder != 0:
            return
        fire_beat = current_beat
    else:
        # Apply time_offset for non-sync mode
        if beats_since_start < time_offset:
            return
        # Fire based on time since start (minus offset)
        var adjusted_beats = beats_since_start - time_offset
        var interval_num = int(adjusted_beats / beat_interval)
        fire_beat = _start_beat + int(time_offset) + interval_num * int(beat_interval)

    # Skip if already fired this beat
    if fire_beat == _last_shot_beat:
        return
    _last_shot_beat = fire_beat

    _shoot()

func _is_chosen_to_fire(current_beat: int) -> bool:
    # Check beat alignment (using this instance's settings)
    var remainder = (current_beat - int(time_offset)) % int(beat_interval)
    if remainder != 0:
        return false

    # Skip if already fired this beat
    if current_beat == _last_shot_beat:
        return false

    # Filter to valid candidates whose beat alignment matches
    var candidates: Array[ShootAtPlayer] = []
    for inst in _registry:
        if is_instance_valid(inst) and inst._started and inst.running:
            if inst.is_visible_in_tree() and inst._is_on_screen():
                var inst_remainder = (current_beat - int(inst.time_offset)) % int(inst.beat_interval)
                if inst_remainder == 0:
                    candidates.append(inst)

    if candidates.is_empty():
        return false

    if self not in candidates:
        return false

    var chosen := _is_chosen_distributed(current_beat, candidates)
    if chosen:
        _last_shot_beat = current_beat
    return chosen

func _is_chosen_distributed(current_beat: int, candidates: Array[ShootAtPlayer]) -> bool:
    # Determine chosen slots once per beat
    if current_beat != _last_distributed_beat:
        _last_distributed_beat = current_beat
        _chosen_slots.clear()

        var count = mini(fire_count, candidates.size())

        match fire_mode:
            FireMode.ROUND_ROBIN:
                # Pick next N slots in sequence
                for i in count:
                    var chosen_inst: ShootAtPlayer = null
                    var lowest_slot_inst: ShootAtPlayer = null
                    var lowest_slot := 999999
                    for inst in candidates:
                        if inst._slot in _chosen_slots:
                            continue
                        if inst._slot >= _current_slot and (chosen_inst == null or inst._slot < chosen_inst._slot):
                            chosen_inst = inst
                        if inst._slot < lowest_slot:
                            lowest_slot = inst._slot
                            lowest_slot_inst = inst
                    # Wrap around if no slot >= _current_slot
                    if chosen_inst == null:
                        chosen_inst = lowest_slot_inst
                    if chosen_inst:
                        _chosen_slots.append(chosen_inst._slot)
                        _current_slot = chosen_inst._slot + 1

            FireMode.RANDOM:
                # Pick N random instances (seeded by beat for determinism)
                var available = candidates.duplicate()
                for i in count:
                    if available.is_empty():
                        break
                    var pick = hash(current_beat + i) % available.size()
                    _chosen_slots.append(available[pick]._slot)
                    available.remove_at(pick)

    return _slot in _chosen_slots

func _shoot():
    var player = g.p1
    if not player or not is_instance_valid(player): return

    # Spawn ring burst effect
    var playfield = g.get("playfield")
    if playfield:
        var ring_r: float = 8.0
        var parent = get_parent()
        if parent.has_method("_get_sprite_size"):
            var sz = parent._get_sprite_size()
            ring_r = maxf(sz.x, sz.y) * 0.4
        RingBurst.spawn(playfield, global_position, ring_r, g.COLOR_MAIN, parent)

    var bullet = bullet_scene.instantiate()
    bullet.global_position = global_position

    # Set velocity towards player
    var dir = (player.global_position - global_position).normalized()
    bullet.velocity = dir * bullet_speed * g.enemy_bullet_factor * Engine.physics_ticks_per_second

    # Add to playfield
    if playfield:
        playfield.add_child(bullet)
    else:
        get_parent().add_child(bullet)
