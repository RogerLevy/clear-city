@tool
extends Actor2D

# Player pea shot projectile

const HitSparks = preload("res://darkblue/effects/hit_sparks.gd")

var atk: int = 1

func init():
    add_to_group("player_projectiles")
    rotation = velocity.angle()
    act(func():
        cull()
    )

func cull():
    var screen_size = get_viewport().get_visible_rect().size
    if global_position.x < -20 or global_position.x > screen_size.x + 20:
        queue_free()
    if global_position.y < -20 or global_position.y > screen_size.y + 20:
        queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
    var actor = area.get_parent()
    if actor.is_in_group("enemies"):
        if actor.has_method("damage"):
            actor.damage(atk)
        # Spawn hit sparks at contact point
        var playfield = g.get("playfield")
        if playfield:
            var contact = g.find_contact_point(global_position, area.global_position, global_position)
            HitSparks.spawn(playfield, contact, velocity.angle() + PI, 20)
        visible = false
        queue_free()
