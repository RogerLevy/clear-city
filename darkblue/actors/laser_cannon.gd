extends Node2D

# Laser cannon - instant wide beam that damages once per enemy

signal finished

var angle: float = 0.0
var ship: Node2D = null
var turret: Node2D = null
var width: float = 1.0
var max_width: float = 100.0
var length: float = 2000.0
var color: Color = Color(0.82, 0.82, 0.7, 1.0)

var damaged_enemies: Dictionary = {}  # track who we've hit
var can_damage: bool = false
var prev_rotation: float = 0.0  # for swept collision
var blocked: bool = false  # laser stopped by high-HP enemy
var blocked_length: float = 0.0  # length to blocked enemy
var debug_draw: bool = false  # draw collision shape in red

# Custom easing curves from original Forth code
func exp3_ease_in(t: float) -> float:
    return pow(2.0, 40.0 * (t - 1.0))

func exp2_ease_out(t: float) -> float:
    return 1.0 - pow(2.0, -20.0 * t)

func _ready():
    rotation = angle
    prev_rotation = angle

    var tween = create_tween()
    # Phase 1: Grow from 1px to full width (exponential3 ease-in)
    tween.tween_method(func(t): set_width(lerpf(1.0, max_width, exp3_ease_in(t))), 0.0, 1.0, 0.2)
    tween.tween_callback(func(): can_damage = true)
    # Phase 2: Hold full width for 2 frames (~0.033s at 60fps)
    tween.tween_interval(0.033)
    # Phase 3: Slowly narrow (exponential2 ease-out, still deals damage)
    tween.tween_method(func(t): set_width(lerpf(max_width, 1.0, exp2_ease_out(t))), 0.0, 1.0, 0.4)
    tween.tween_callback(func(): can_damage = false)
    # Phase 4: Shorten length exponentially
    tween.tween_method(set_length, length, 0.0, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
    # Done
    tween.tween_callback(cleanup)

func set_width(w: float):
    width = w
    queue_redraw()

func set_length(l: float):
    length = l
    queue_redraw()

func _physics_process(_delta):
    # Follow ship position and turret angle
    if is_instance_valid(ship):
        global_position = ship.global_position
    if is_instance_valid(turret):
        rotation = turret.current_angle

    # Check for hits during damage window
    if can_damage:
        check_hits()

    # Store for swept collision next frame
    prev_rotation = rotation

func check_hits():
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(enemy): continue
        if not enemy.is_visible_in_tree(): continue
        if damaged_enemies.has(enemy): continue

        var enemy_r = enemy.get("r") if enemy.get("r") else 16.0
        if is_in_beam(enemy.global_position, enemy_r):
            if enemy.has_method("damage"):
                var dmg = 100 if width >= max_width else int(width)
                enemy.damage(dmg)
                damaged_enemies[enemy] = true
                spawn_sparks(enemy)

# Disabled - blocking/shortening feature (needs work)
#func check_hits_with_blocking():
#    var hits: Array = []
#    for enemy in get_tree().get_nodes_in_group("enemies"):
#        if not is_instance_valid(enemy): continue
#        if not enemy.is_visible_in_tree(): continue
#        if damaged_enemies.has(enemy): continue
#
#        var enemy_r = enemy.get("r") if enemy.get("r") else 16.0
#        if is_in_beam(enemy.global_position, enemy_r):
#            var dist = (enemy.global_position - global_position).length()
#            hits.append({"enemy": enemy, "dist": dist, "r": enemy_r})
#
#    hits.sort_custom(func(a, b): return a.dist < b.dist)
#
#    for hit in hits:
#        var enemy = hit.enemy
#        var dist = hit.dist
#        var enemy_r = hit.r
#
#        if blocked and dist > blocked_length:
#            continue
#
#        if enemy.has_method("damage"):
#            var dmg = 100 if width >= max_width else int(width)
#            var enemy_hp = enemy.get("hp") if enemy.get("hp") else 0
#
#            if enemy_hp > dmg and not blocked:
#                blocked = true
#                blocked_length = dist - enemy_r
#                length = blocked_length
#
#            enemy.damage(dmg)
#            damaged_enemies[enemy] = true
#            spawn_sparks(enemy)

func is_in_beam(pos: Vector2, enemy_r: float) -> bool:
    var to_enemy = pos - global_position
    var dist = to_enemy.length()

    # Check distance (must be within beam length)
    if dist > length + enemy_r:
        return false

    # Get enemy angle relative to beam origin
    var enemy_angle = to_enemy.angle()

    # Calculate angular tolerance (beam width + enemy radius at this distance)
    var tolerance = atan2(width / 2.0 + enemy_r, max(dist, 1.0))

    # Calculate the swept angular range (min to max, accounting for beam width)
    var ang1 = rotation
    var ang2 = prev_rotation

    # Normalize angles to find the actual swept range
    var sweep = angle_difference(ang1, ang2)
    var min_ang: float
    var max_ang: float

    if sweep >= 0:
        min_ang = ang1 - tolerance
        max_ang = ang1 + sweep + tolerance
    else:
        min_ang = ang1 + sweep - tolerance
        max_ang = ang1 + tolerance

    # Check if enemy angle falls within the swept range
    # Use angle_difference to handle wraparound
    var diff_from_min = angle_difference(min_ang, enemy_angle)
    var total_range = angle_difference(min_ang, max_ang)

    # Enemy is in beam if its angle is between min and max
    if total_range >= 0:
        return diff_from_min >= 0 and diff_from_min <= total_range
    else:
        return diff_from_min <= 0 and diff_from_min >= total_range

func spawn_sparks(enemy):
    const HitSparks = preload("res://darkblue/effects/hit_sparks.gd")
    var playfield = g.get("playfield")
    if playfield:
        var contact = g.find_contact_point(global_position, enemy.global_position, enemy.global_position)
        HitSparks.spawn(playfield, contact, rotation + PI, 30)

func cleanup():
    finished.emit()
    queue_free()

func _draw():
    # Draw beam as rectangle from origin extending in +X direction
    var rect = Rect2(0, -width / 2, length, width)
    draw_rect(rect, color)

    # Debug: draw swept collision area as filled polygon
    if debug_draw and can_damage:
        var tolerance = atan2(width / 2.0, length)
        var local_prev = prev_rotation - rotation  # prev beam angle in local space

        var min_ang = minf(0, local_prev) - tolerance
        var max_ang = maxf(0, local_prev) + tolerance

        var points: PackedVector2Array = []
        points.append(Vector2.ZERO)
        var steps = 24
        for i in range(steps + 1):
            var ang = lerpf(min_ang, max_ang, float(i) / steps)
            points.append(Vector2.from_angle(ang) * length)

        draw_colored_polygon(points, Color(1, 0, 0, 0.3))
