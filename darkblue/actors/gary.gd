@tool
class_name Gary
extends Actor2D

static var DEFAULT_ANIM: Array = range(6)
static var PANT_ANIM: Array = [7, 8]
static var FATIGUE_MAX: float = 10.0  # Seconds of running to reach max fatigue
static var PANT_THRESHOLD: float = 4.0  # Min fatigue to start panting
static var NEAR_STOPPED: float = 20.0  # Speed threshold for panting

var fatigue: float = 0.0
var _was_moving: bool = false
var _is_panting: bool = false
var _debug_font: Font = preload("res://common/font_04B_03__.ttf")

#func _process(_delta):
    #if OS.is_debug_build():
        #queue_redraw()

#func _draw():
    #if not OS.is_debug_build(): return
    #var text = "%.1f" % fatigue
    #draw_string(_debug_font, Vector2(30, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.YELLOW)

func init():
    animation = DEFAULT_ANIM
    animationSpeed = 0.5
    var ship = get_parent()
    if ship is Ship:
        ship.damaged.connect(_on_ship_damaged)
    act( func():
        if ship is not Ship:
            return

        if ship.dead:
            current_frame = 6
            animationSpeed = 0
            return

        var turret = ship.get_node_or_null("Turret")
        if not turret:
            return

        # Turret facing direction (right = positive x component)
        var turret_facing_right = cos(turret.current_angle) > 0

        # Ship movement direction
        var ship_moving_right = ship.velocity.x > 0
        var ship_moving = ship.velocity.length() > 0.25

        # Player input (for fatigue - Gary runs when player is actively moving)
        var player_moving = Input.is_action_pressed("left") or Input.is_action_pressed("right") or \
                            Input.is_action_pressed("up") or Input.is_action_pressed("down")

        # Gary faces the direction the turret is facing
        if sprite:
            sprite.flip_h = not turret_facing_right

        var delta = get_physics_process_delta_time()

        # Lower fatigue when starting to run while panting
        if player_moving and not _was_moving and _is_panting:
            #fatigue *= 0.5
            _is_panting = false
        _was_moving = player_moving

        # Running builds fatigue, not running decreases it
        if player_moving:
            fatigue = minf(fatigue + delta, FATIGUE_MAX)
        else:
            if _is_panting:
                fatigue = maxf(fatigue - (delta * 2), 0.0)
            else:
                fatigue = maxf(fatigue - (delta), 0.0)

        # Start panting when ship has stopped, player not moving, and fatigued enough
        var ship_speed = ship.velocity.length()
        if ship_speed < NEAR_STOPPED and fatigue >= PANT_THRESHOLD and not player_moving:
            _is_panting = true

        # Stop panting when fatigue reaches 0
        if fatigue <= 0:
            _is_panting = false

        # Continue panting until fatigue is gone
        if _is_panting:
            if animation != PANT_ANIM:
                animationPos = 0
            animation = PANT_ANIM
            animationSpeed = musical_anim_speed(PANT_ANIM, 1)
            return

        # Back to normal running animation
        animation = DEFAULT_ANIM

        # Animation speed tied to ship speed
        var speed_factor = ship.velocity.length() / 100.0
        var speed = minf(speed_factor, 0.75)

        # Run backwards if:
        # 1. Moving horizontally and turret faces opposite to movement, OR
        # 2. Moving upward (within 45 degrees of straight up)
        var moving_horizontally = absf(ship.velocity.x) > 1.0
        var moving_upward = ship.velocity.y < 0 and absf(ship.velocity.y) >= absf(ship.velocity.x)
        if (moving_horizontally and turret_facing_right != ship_moving_right) or moving_upward:
            speed = -speed

        animationSpeed = speed
    )

func _on_ship_damaged():
    _is_panting = false
    fatigue = 0.0
