extends Node2D

# Hit sparks effect - pixels that spray out, slow down, and disappear

var direction: float = 0.0  # Base direction in radians
var spread: float = deg_to_rad(60)  # Spread angle
var particle_count: int = 5
var color: Color = Color("d1d1b2")

var particles: Array = []  # Array of {pos, vel, life, max_life}
var initial_speed: float = 120.0  # pixels per second

func _ready():
    for i in particle_count:
        # Bias angle towards center using power distribution
        var r = randf_range(-1.0, 1.0)
        r = sign(r) * pow(abs(r), 2.0)  # square biases towards center
        var angle = direction + r * spread / 2
        var dist = randf_range(6.0, 40.0)
        # With linear decel: dist = speed * time / 2, so time = 2 * dist / speed
        var life = 2.0 * dist / initial_speed
        particles.append({
            "pos": Vector2.ZERO,
            "vel": Vector2.from_angle(angle) * initial_speed,
            "life": life,
            "max_life": life
        })

func _process(delta):
    var all_dead = true
    for p in particles:
        if p.life > 0:
            all_dead = false
            var t = p.life / p.max_life  # 1 at start, 0 at end
            p.pos += p.vel * delta * t * t  # Quadratic ease out
            p.life -= delta

    if all_dead:
        queue_free()
    else:
        queue_redraw()

func _draw():
    for p in particles:
        if p.life > 0:
            draw_rect(Rect2(p.pos, Vector2(1, 1)), color)

static func spawn(parent: Node, pos: Vector2, dir: float, count: int = 5, col: Color = Color("d1d1b2") ) -> Node2D:
    var effect = load("res://darkblue/effects/hit_sparks.tscn").instantiate()
    effect.global_position = pos
    effect.direction = dir
    effect.color = col
    effect.particle_count = count
    parent.add_child(effect)
    return effect
