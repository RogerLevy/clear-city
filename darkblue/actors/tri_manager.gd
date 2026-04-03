extends Node2D
class_name TriManager

# Manages all tris as pure data - no individual nodes
# Uses MultiMeshInstance2D for batched rendering

const MAX_TRIS = 4096
const TRI_RADIUS = 5.0

var positions: PackedVector2Array
var velocities: PackedVector2Array
var angles: PackedFloat32Array
var bounced: PackedByteArray
var trapped: PackedByteArray
var count: int = 0
var spin_speed: float = 12.0

var multimesh_instance: MultiMeshInstance2D
var tri_texture: Texture2D
var tri_shader: Shader
var tri_material: ShaderMaterial

func _ready():
    g.tri_manager = self

    positions.resize(MAX_TRIS)
    velocities.resize(MAX_TRIS)
    angles.resize(MAX_TRIS)
    bounced.resize(MAX_TRIS)
    trapped.resize(MAX_TRIS)

    tri_texture = preload("res://darkblue/actors/tri_sheet.png")
    tri_shader = preload("res://darkblue/actors/tri_multimesh.gdshader")
    tri_material = ShaderMaterial.new()
    tri_material.shader = tri_shader
    tri_material.set_shader_parameter("sprite_sheet", tri_texture)
    setup_multimesh()

func setup_multimesh():
    var mm = MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_2D
    mm.use_colors = true
    mm.instance_count = MAX_TRIS
    mm.visible_instance_count = 0

    # Create quad with explicit UVs (0-1 range)
    var arrays = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = PackedVector2Array([
        Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
    ])
    arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([
        Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)
    ])
    arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
    var quad = ArrayMesh.new()
    quad.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    mm.mesh = quad

    multimesh_instance = MultiMeshInstance2D.new()
    multimesh_instance.multimesh = mm
    multimesh_instance.texture = tri_texture
    multimesh_instance.material = tri_material
    add_child(multimesh_instance)

func spawn(pos: Vector2, vel: Vector2) -> int:
    if count >= MAX_TRIS:
        return -1
    var idx: int = count
    var angle: float = randf() * 360.0
    positions[idx] = pos
    velocities[idx] = vel
    angles[idx] = angle
    bounced[idx] = 0
    trapped[idx] = 0
    count += 1
    # Update multimesh immediately to prevent stale data glitch
    var mm: MultiMesh = multimesh_instance.multimesh
    var t: Transform2D = Transform2D.IDENTITY
    t.origin = pos
    mm.set_instance_transform_2d(idx, t)
    var frame_norm: float = (angle / 360.0 * 72.0) / 72.0
    mm.set_instance_color(idx, Color(frame_norm, 0.0, 0.0, 1.0))
    mm.visible_instance_count = count
    return idx

func _physics_process(delta: float) -> void:
    var screen_w: float = get_viewport().get_visible_rect().size.x
    var screen_h: float = get_viewport().get_visible_rect().size.y
    var mm: MultiMesh = multimesh_instance.multimesh
    var t: Transform2D = Transform2D.IDENTITY
    var cull_min: float = -20.0
    var cull_max_x: float = screen_w + 20.0
    var cull_max_y: float = screen_h + 20.0
    var bounce_max_x: float = screen_w - TRI_RADIUS
    var bounce_max_y: float = screen_h - TRI_RADIUS

    var i: int = 0
    while i < count:
        # Cache array values
        var pos: Vector2 = positions[i] + velocities[i] * delta
        positions[i] = pos
        var px: float = pos.x
        var py: float = pos.y

        # Cull if far off screen
        if px < cull_min or px > cull_max_x or py < cull_min or py > cull_max_y:
            remove_tri(i)
            continue

        # Screen bounce (once only, except right edge always bounces)
        var vel: Vector2 = velocities[i]
        if px > bounce_max_x and vel.x > 0.0:
            velocities[i].x = -vel.x
        elif bounced[i] == 0:
            if (py < TRI_RADIUS and vel.y < 0.0) or (py > bounce_max_y and vel.y > 0.0):
                velocities[i].y = -vel.y
                bounced[i] = 1

        # Update rotation
        var angle: float = fmod(angles[i] + spin_speed, 360.0)
        angles[i] = angle

        # Update multimesh transform (reuse t)
        var frame_norm: float = (angle / 360.0 * 72.0) / 72.0
        t.origin = pos
        mm.set_instance_transform_2d(i, t)
        mm.set_instance_color(i, Color(frame_norm, 0.0, 0.0, 1.0))

        i += 1

func check_ship_collision(ship_pos: Vector2, ship_radius: float) -> int:
    var collect_dist: float = ship_radius + TRI_RADIUS
    var collect_dist_sq: float = collect_dist * collect_dist
    var ship_x: float = ship_pos.x
    var ship_y: float = ship_pos.y
    var collected: int = 0
    var i: int = 0
    while i < count:
        var pos: Vector2 = positions[i]
        # Bounding box pre-check (cheaper than distance)
        var dx: float = pos.x - ship_x
        var dy: float = pos.y - ship_y
        if dx > collect_dist or dx < -collect_dist or dy > collect_dist or dy < -collect_dist:
            i += 1
            continue
        # Squared distance check (no sqrt)
        if dx * dx + dy * dy < collect_dist_sq:
            remove_tri(i)
            collected += 1
        else:
            i += 1
    return collected

func slowdown(factor: float):
    for i in count:
        velocities[i] *= factor
    spin_speed *= factor

func attract_to(target: Vector2, radius: float, speed: float):
    var radius_sq: float = radius * radius
    var tx: float = target.x
    var ty: float = target.y
    for i in count:
        var pos: Vector2 = positions[i]
        var dx: float = tx - pos.x
        var dy: float = ty - pos.y
        var dist_sq: float = dx * dx + dy * dy
        if dist_sq < radius_sq and dist_sq > 0.0:
            trapped[i] = 1
            var dist: float = sqrt(dist_sq)
            velocities[i] = Vector2(dx / dist * speed, dy / dist * speed)

func trap_all():
    for i in count:
        trapped[i] = 1

func attract_trapped(target: Vector2, speed: float):
    var tx: float = target.x
    var ty: float = target.y
    for i in count:
        if trapped[i] == 0: continue
        var pos: Vector2 = positions[i]
        var dx: float = tx - pos.x
        var dy: float = ty - pos.y
        var dist_sq: float = dx * dx + dy * dy
        if dist_sq > 0.0:
            var dist: float = sqrt(dist_sq)
            velocities[i] = Vector2(dx / dist * speed, dy / dist * speed)

func remove_tri(idx: int):
    if idx < 0 or idx >= count:
        return
    # Swap with last
    count -= 1
    var mm: MultiMesh = multimesh_instance.multimesh
    if idx < count:
        positions[idx] = positions[count]
        velocities[idx] = velocities[count]
        angles[idx] = angles[count]
        bounced[idx] = bounced[count]
        trapped[idx] = trapped[count]
        # Update multimesh for swapped element to prevent visual glitch
        var t: Transform2D = Transform2D.IDENTITY
        t.origin = positions[idx]
        mm.set_instance_transform_2d(idx, t)
        var frame_norm: float = (angles[idx] / 360.0 * 72.0) / 72.0
        mm.set_instance_color(idx, Color(frame_norm, 0.0, 0.0, 1.0))
    mm.visible_instance_count = count
