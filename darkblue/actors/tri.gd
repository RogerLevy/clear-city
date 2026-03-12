extends Actor2D

# Collectible triangle

var r: float = 5.0       # collision radius
var worth: int = 1       # energy value when collected
var has_bounced: bool = false

func init():
    var tris_node = get_tree().current_scene.get_node_or_null("%Tris")
    if tris_node:
        reparent(tris_node)
    else:
        reparent(get_tree().root)
    rotation = randf() * TAU

func _physics_process(_delta):
    position += velocity * _delta
    rotation += 0.2 * animationSpeed
    if not has_bounced:
        screen_bounce()

func screen_bounce():
    var screen_size = get_viewport().get_visible_rect().size

    # Check all edges - bounce once only
    if global_position.x < r and velocity.x < 0:
        velocity.x *= -1
        has_bounced = true
    elif global_position.x > screen_size.x - r and velocity.x > 0:
        velocity.x *= -1
        has_bounced = true
    elif global_position.y < r and velocity.y < 0:
        velocity.y *= -1
        has_bounced = true
    elif global_position.y > screen_size.y - r and velocity.y > 0:
        velocity.y *= -1
        has_bounced = true
