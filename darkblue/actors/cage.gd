@tool
extends Node2D

@export var radius: float = 60.0:
    set(v):
        radius = v
        queue_redraw()

@export var color: Color = g.COLOR_MAIN

func _draw():
    draw_arc(Vector2.ZERO, radius, 0, TAU, 64, color, 4.0)

func _physics_process(_delta: float) -> void:
    if Engine.is_editor_hint():
        return

    var center: Vector2 = global_position

    # Player bounces off inside
    var player = g.p1
    if player and is_instance_valid(player):
        var player_r: float = player.r if "r" in player else 6.0
        var max_dist: float = radius - player_r - 2
        var to_player: Vector2 = player.global_position - center
        var dist: float = to_player.length()
        if dist > max_dist:
            # Push player back inside
            var normal: Vector2 = to_player / dist
            player.global_position = center + normal * max_dist
            # Reflect velocity
            if "velocity" in player:
                var vel: Vector2 = player.velocity
                var dot: float = vel.dot(normal)
                if dot > 0:
                    player.velocity = vel - 2.0 * dot * normal
                    if "snd_bounce" in player:
                        g.sfx(player.snd_bounce)
                    if "paralysis" in player and "sbp" in player:
                        player.paralysis = player.sbp

    # Enemies bounce off outside
    for enemy in get_tree().get_nodes_in_group("enemies"):
        var enemy_r: float = enemy.r if "r" in enemy else 8.0
        var min_dist: float = radius + enemy_r + 4
        var to_enemy: Vector2 = enemy.global_position - center
        var dist: float = to_enemy.length()
        if dist < min_dist and dist > 0:
            # Push enemy back outside
            var normal: Vector2 = to_enemy / dist
            enemy.global_position = center + normal * min_dist
            # Reflect velocity
            if "velocity" in enemy:
                var vel: Vector2 = enemy.velocity
                var dot: float = vel.dot(normal)
                if dot < 0:
                    enemy.velocity = vel - 2.0 * dot * normal

    # Tris bounce off outside (data-based)
    var tm = g.tri_manager
    if tm:
        bounce_tris(tm, center)

    # Scene-based tris (resources group) bounce off outside
    for tri in get_tree().get_nodes_in_group("resources"):
        var tri_r: float = tri.r if "r" in tri else 5.0
        var min_dist: float = radius + tri_r
        var to_tri: Vector2 = tri.global_position - center
        var dist: float = to_tri.length()
        if dist < min_dist and dist > 0:
            var normal: Vector2 = to_tri / dist
            tri.global_position = center + normal * min_dist
            if "velocity" in tri:
                var vel: Vector2 = tri.velocity
                var dot: float = vel.dot(normal)
                if dot < 0:
                    tri.velocity = vel - 2.0 * dot * normal

func bounce_tris(tm: TriManager, center: Vector2):
    var min_dist: float = radius + tm.TRI_RADIUS
    for i in tm.count:
        var to_tri: Vector2 = tm.positions[i] - center
        var dist: float = to_tri.length()
        if dist < min_dist and dist > 0:
            # Push tri back outside
            var normal: Vector2 = to_tri / dist
            tm.positions[i] = center + normal * min_dist
            # Reflect velocity
            var vel: Vector2 = tm.velocities[i]
            var dot: float = vel.dot(normal)
            if dot < 0:
                tm.velocities[i] = vel - 2.0 * dot * normal
