@tool
extends Actor2D

# Turret orbits around the ship and points at mouse cursor

@export var orbit_radius: float = 24
@export var mouse_lerp_speed: float = 0.5
@export var shot_speed: float = 800.0
@export var snd_shoot: AudioStreamWAV
@export var snd_charge: AudioStreamWAV
@export var snd_bigshot: AudioStreamWAV
@export var snd_laser: AudioStreamWAV

var aim: float = 0.0      # target angle (where we want to point)
var current_angle: float = 0.0  # actual angle (lerps towards aim)

# Charge system
const CHARGE_DELAY: int = 15       # frames before charging starts
const CHARGE_BIG_SHOT: int = 30    # charge needed for big shot
const CHARGE_LASER: int = 100      # charge needed for laser cannon
const CHARGE_MAX: int = 100        # max charge
const CHARGE_TIMEOUT: int = 300    # 5 seconds at 60fps

var hold_frames: int = 0           # how long fire button held
var charge: int = 0                # current charge level
var charge_level: int = 0          # 0=pea, 1=big, 2=laser
var laser_active: bool = false     # can't shoot during laser animation
var shake_amount: float = 0.0

var charge_shot_font: Font = preload("res://darkblue/fonts/darkblue_mini.ttf")

# Charge bar display
var charge_bars: Array = []
const BAR_SCENE = preload("res://darkblue/ui/charge_bar.tscn")

func _ready():
    # Create charge bars (add to ship so they don't rotate with turret)
    call_deferred("_create_charge_bars")

func _create_charge_bars():
    var ship = get_parent()
    if not ship: return
    for i in 2:
        var bar = BAR_SCENE.instantiate()
        bar.visible = false
        ship.add_child(bar)
        charge_bars.append(bar)

func _physics_process(_delta):
    if Engine.is_editor_hint(): return
    self.delta = _delta

    var ship = get_parent()
    if not ship: return

    # Only update aim if mouse is within game viewport
    if g.mouse_in_viewport():
        aim = (g.mouse_pos() - ship.global_position).angle()
        if g.quantize_aim:
            var step = deg_to_rad(45)
            aim = round(aim / step) * step

    # Lerp current angle towards aim
    current_angle = lerp_angle(current_angle, aim, mouse_lerp_speed)

    # Position turret orbiting the ship (with shake)
    var shake_offset = Vector2.ZERO
    if shake_amount > 0:
        shake_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amount * 3
    position = Vector2.from_angle(current_angle) * orbit_radius + shake_offset

    # Rotate to face the aim direction
    rotation = current_angle

    # Handle charging and shooting
    handle_shooting(ship)
    update_charge_bars(ship)
    update_ship_sprite(ship)
    queue_redraw()

func handle_shooting(ship):
    if laser_active:
        return

    # Cancel charge on right click
    if Input.is_action_just_pressed("cancel_charge"):
        cancel_charge()
        return

    if Input.is_action_pressed("shoot"):
        # Fire pea on initial press
        if Input.is_action_just_pressed("shoot"):
            fire_pea()

        hold_frames += 1

        # Start charging after delay (cap at energy - 1 to keep reserve)
        if hold_frames > CHARGE_DELAY:
            var old_level = charge_level
            var max_charge = mini(CHARGE_MAX, g.energy - 1)
            charge = mini(charge + 1, max_charge)
            update_charge_level()

            # Play sound on level up
            if charge_level > old_level and snd_charge:
                g.sfx(snd_charge, 0.5)

        # Timeout - cancel if held too long
        if hold_frames >= CHARGE_TIMEOUT:
            cancel_charge()

        # Update shake based on charge
        shake_amount = float(charge) / float(CHARGE_MAX)

    elif Input.is_action_just_released("shoot"):
        # Fire charged shot on release
        if charge_level == 2 and g.energy >= 120:
            fire_laser_cannon(ship)
        elif charge_level == 1 and g.energy >= 30:
            fire_big_shot(ship)
        reset_charge()

func update_charge_level():
    if charge >= CHARGE_LASER:
        charge_level = 2
    elif charge >= CHARGE_BIG_SHOT:
        charge_level = 1
    else:
        charge_level = 0

func cancel_charge():
    reset_charge()

func reset_charge():
    hold_frames = 0
    charge = 0
    charge_level = 0
    shake_amount = 0.0

func update_charge_bars(ship):
    for i in charge_bars.size():
        var bar = charge_bars[i]
        if i < charge_level:
            bar.visible = true
            bar.global_position = ship.global_position + Vector2(-20, -20 + i * -8)
        else:
            bar.visible = false

func update_ship_sprite(ship):
    if charge > 0:
        # Frame 0-12 based on charge, 1 frame per 10 charge
        var frame = mini(charge / 10, 12)
        ship.current_frame = frame
    elif not ship.recovering():
        ship.current_frame = 0

func fire_pea():
    if g.energy <= 1: return

    g.energy -= 1
    g.sfx(snd_shoot, 0.6)

    var shot = g.spawn("shot", null, get_parent().global_position)
    if shot:
        shot.velocity = Vector2.from_angle(current_angle) * shot_speed
    FloatingText.spawn(g.playfield, get_parent().global_position, "1", charge_shot_font, 16, Color("f00"))

func fire_big_shot(ship):
    g.energy -= 29
    if snd_bigshot:
        g.sfx(snd_bigshot, 0.8)

    # Spawn circle burst at ship center
    var burst = g.spawn("big_shot_burst", ship )
    await secs(0.15)

    # Spawn wide laser from ship center
    var beam = g.spawn("big_shot_beam", null, ship.global_position)
    beam.velocity = Vector2.from_angle(current_angle) * shot_speed

    FloatingText.spawn(g.playfield, get_parent().global_position, str(29), charge_shot_font, 16, Color("f00"))

func fire_laser_cannon(ship):
    g.energy -= 99
    if snd_laser:
        g.sfx(snd_laser, 1.0)

    laser_active = true

    # Spawn large burst at ship center
    var burst = g.spawn("laser_cannon_burst", ship)
    await secs(0.2)
    var laser = g.spawn("laser_cannon", null, ship.global_position)
    laser.angle = current_angle
    laser.ship = ship
    laser.turret = self
    laser.finished.connect(func(): laser_active = false)
        
    FloatingText.spawn(g.playfield, get_parent().global_position, str(99), charge_shot_font, 16, Color("f00"))

func _draw():
    # Debug: show charge counter (un-rotated)
    if charge > 0:
        draw_set_transform(Vector2.ZERO, -rotation)
        draw_string(ThemeDB.fallback_font, Vector2(20, -30), str(charge), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
        draw_set_transform(Vector2.ZERO, 0)
