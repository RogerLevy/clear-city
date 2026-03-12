@tool
extends Actor2D

# Big shot beam - 48x16 laser that passes through enemies, dealing continuous damage

var angle: float = 0.0
var atk: int = 3
var damage_cooldown: Dictionary = {}  # enemy -> frames until can damage again
const DAMAGE_INTERVAL: int = 6  # frames between damage ticks

func init():
    add_to_group("player_projectiles")
    rotation = angle
    act(func():
        cull()
        check_hits()
    )

func _physics_process(delta):
    super._physics_process(delta)
    # Decrease cooldowns
    for enemy in damage_cooldown.keys():
        if is_instance_valid(enemy):
            damage_cooldown[enemy] -= 1
            if damage_cooldown[enemy] <= 0:
                damage_cooldown.erase(enemy)
        else:
            damage_cooldown.erase(enemy)

func check_hits():
    var space = get_world_2d().direct_space_state
    # Check collision with Area2D
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(enemy): continue
        if not enemy.is_visible_in_tree(): continue
        if damage_cooldown.has(enemy): continue

        # Simple distance check for now
        var dist = global_position.distance_to(enemy.global_position)
        var enemy_r = enemy.get("r") if enemy.get("r") else 16.0
        if dist < enemy_r + 24:  # half of beam length
            if enemy.has_method("damage"):
                enemy.damage(atk)
                damage_cooldown[enemy] = DAMAGE_INTERVAL
                # Spawn sparks
                spawn_sparks(enemy)

func spawn_sparks(enemy):
    const HitSparks = preload("res://darkblue/effects/hit_sparks.gd")
    var playfield = g.get("playfield")
    if playfield:
        var enemy_r = enemy.get("r") if enemy.get("r") else 16.0
        var contact = g.find_contact_point(global_position, enemy.global_position, enemy.global_position)
        HitSparks.spawn(playfield, contact, velocity.angle() + PI, 10)

func cull():
    var screen_size = get_viewport().get_visible_rect().size
    if global_position.x < -50 or global_position.x > screen_size.x + 50:
        queue_free()
    if global_position.y < -50 or global_position.y > screen_size.y + 50:
        queue_free()

func _draw():
    # Draw 48x16 beam
    var rect = Rect2(-24, -8, 48, 16)
    draw_rect(rect, Color(0.82, 0.82, 0.7, 1.0))
