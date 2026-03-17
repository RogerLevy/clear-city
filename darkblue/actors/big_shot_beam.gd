@tool
extends "res://darkblue/actors/shot.gd"

# Big shot beam - 48x16 laser that passes through enemies, dealing continuous damage
# Origin at left edge (back), 48 pixels long

const BEAM_LENGTH: float = 48.0

var damage_cooldown: Dictionary = {}  # enemy -> frames until can damage again
const DAMAGE_INTERVAL: int = 6  # frames between damage ticks

func init():
    atk = 3
    add_to_group("player_projectiles")
    rotation = velocity.angle()
    act(func():
        cull()
        check_hits()
    )

func get_front_tip() -> Vector2:
    return global_position + velocity.normalized() * BEAM_LENGTH

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
    for area in $Area2D.get_overlapping_areas():
        var enemy = area.get_parent()
        if not enemy.is_in_group("enemies"): continue
        if damage_cooldown.has(enemy): continue
        if enemy.has_method("damage"):
            enemy.damage(atk)
            damage_cooldown[enemy] = DAMAGE_INTERVAL
            spawn_sparks(enemy)

func spawn_sparks(enemy):
    var playfield = g.get("playfield")
    if playfield:
        var contact = g.find_contact_point(global_position, enemy.global_position, global_position)
        HitSparks.spawn(playfield, contact, velocity.angle() + PI, 10)

func cull():
    var screen_size = get_viewport().get_visible_rect().size
    if global_position.x < -50 or global_position.x > screen_size.x + 50:
        queue_free()
    if global_position.y < -50 or global_position.y > screen_size.y + 50:
        queue_free()
