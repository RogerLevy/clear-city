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
        # Spawn hit sparks at contact point using raycast
        var playfield = g.get("playfield")
        if playfield:
            var space = get_world_2d().direct_space_state
            var query = PhysicsRayQueryParameters2D.create(global_position, area.global_position)
            query.collide_with_areas = true
            query.collide_with_bodies = false
            var result = space.intersect_ray(query)
            var contact = result.position if result else global_position
            HitSparks.spawn(playfield, contact, velocity.angle() + PI, 20)
        visible = false
        queue_free()
