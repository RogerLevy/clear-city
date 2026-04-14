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

        var turret = ship.get_node_or_null("Turret")
        if not turret:
            return

        # Turret facing direction (right = positive x component)
        var turret_facing_right = cos(turret.current_angle) > 0

        # Ship movement direction
        var ship_moving_right = ship.velocity.x > 0
        var ship_moving = absf(ship.velocity.x) > 1.0

        # Gary faces the direction the turret is facing
        if sprite:
            sprite.flip_h = not turret_facing_right

        # Animation speed tied to ship speed
        var speed_factor = ship.velocity.length() / 100.0
        var speed = minf(speed_factor, 0.75)

        # Run backwards if turret faces opposite to movement
        if ship_moving and turret_facing_right != ship_moving_right:
            speed = -speed

        animationSpeed = speed
    )
