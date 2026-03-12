extends Actor2D

# Collectible triangle

var r: float = 5.0       # collision radius
var worth: int = 1       # energy value when collected
var has_bounced: bool = false
var a: float = 0
var s: Sprite2D

func init():
    var tris_node = get_tree().current_scene.get_node_or_null("%Tris")
    if tris_node:
        reparent(tris_node)
    else:
        reparent(get_tree().root)
    #rotation = randf() * TAU
    s = %Sprite2D
    a = randf() * 360
    animationSpeed = 12

func _physics_process(_delta):
    position += velocity * _delta
    if not has_bounced:
        screen_bounce()
    a += a + animationSpeed
    if a > 360: a -= 360
    s.frame = a * (360/72)

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
