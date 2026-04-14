@tool
class_name Gary
extends Actor2D

static var DEFAULT_ANIM: Array = range(6)

func init():
    animation = DEFAULT_ANIM
    animationSpeed = 0.5
    act( func():
        var ship = get_parent()
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
        var ship_moving = ship.velocity.length() > 1.0

        # Gary faces the direction the turret is facing
        if sprite:
            sprite.flip_h = not turret_facing_right

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
